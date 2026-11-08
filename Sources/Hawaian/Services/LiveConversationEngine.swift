import AVFoundation
import Foundation
import Combine
import Speech
@preconcurrency import Translation

@MainActor
final class LiveConversationEngine: ObservableObject {
    enum State: Equatable {
        case idle
        case requestingPermission
        case listening
        case interrupted(String)
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var recognizedText = ""
    @Published private(set) var translatedText = ""
    @Published private(set) var detectedLanguageCode: String?
    @Published private(set) var activeInputCount = 0
    @Published private(set) var outputRouteName = "System audio"
    @Published private(set) var spokenReplyPreview = ""
    @Published private(set) var contextMemory: [String] = []
    @Published private(set) var lastError: String?

    private let audioEngine = AVAudioEngine()
    private let synthesizer = AVSpeechSynthesizer()
    private var recognizers: [(code: String, recognizer: SFSpeechRecognizer)] = []
    private var tasks: [SFSpeechRecognitionTask] = []
    private let requestBox = AudioRequestBox()
    private var generation = 0
    private var isRestarting = false
    private var translationSession: TranslationSession?
    private var replyTranslationSession: TranslationSession?
    private var translationTask: Task<Void, Never>?
    private var latestCandidateScore = -1.0
    private var lastSpokenTranslation = ""
    private var targetLanguageCode = "en"
    private var excludeDeviceLanguage = true
    private var inputLanguageCode = "auto"

    var isListening: Bool { state == .listening }
    var translationSource: Locale.Language? {
        detectedLanguageCode.map { Locale.Language(identifier: $0) }
    }

    func start(targetLanguageCode: String, excludeDeviceLanguage: Bool, inputLanguageCode: String = "auto") async {
        guard state != .listening, state != .requestingPermission else { return }
        state = .requestingPermission
        lastError = nil
        self.targetLanguageCode = targetLanguageCode
        self.excludeDeviceLanguage = excludeDeviceLanguage
        self.inputLanguageCode = inputLanguageCode

        let microphoneGranted = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { continuation.resume(returning: $0) }
        }
        guard microphoneGranted else {
            state = .failed("Microphone permission is required.")
            return
        }

        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard speechStatus == .authorized else {
            state = .failed("Speech recognition permission is required.")
            return
        }

        let excluded = excludeDeviceLanguage ? SpeechLanguagePolicy.deviceLanguageCode() : nil
        let locales = SpeechLanguagePolicy.filter(Array(SFSpeechRecognizer.supportedLocales()), excludingLanguageCode: excluded)
        let translationLanguages = await TranslationLanguageProvider.supportedLanguages()
        let translationCodes = Set(translationLanguages.map {
            $0.languageCode?.identifier.lowercased() ?? $0.minimalIdentifier.lowercased()
        })
        let translatableLocales = locales.filter { locale in
            let code = locale.language.languageCode?.identifier.lowercased() ?? ""
            return translationCodes.contains(code)
        }
        let candidates = SpeechLanguagePolicy.recognitionCandidates(
            translatableLocales,
            preferredLanguageCode: inputLanguageCode
        )

        guard !candidates.isEmpty else {
            state = .failed("No speech and translation languages are available after applying your language filter.")
            return
        }

        recognizers = candidates.compactMap { locale in
            guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else { return nil }
            return (locale.language.languageCode?.identifier ?? locale.identifier, recognizer)
        }

        guard !recognizers.isEmpty else {
            state = .failed("Apple speech recognition is currently unavailable.")
            return
        }

        do {
            try configureAudioSession()
            try startAudioCapture()
            rebuildRecognitionTasks()
            state = .listening
            updateOutputRoute()
        } catch {
            stopAudioCapture()
            state = .failed(error.localizedDescription)
        }
    }

    func stop() {
        translationTask?.cancel()
        translationTask = nil
        translationSession = nil
        tasks.forEach { $0.cancel() }
        tasks.removeAll()
        requestBox.replace(with: [])
        stopAudioCapture()
        synthesizer.stopSpeaking(at: .immediate)
        detectedLanguageCode = nil
        recognizedText = ""
        translatedText = ""
        activeInputCount = 0
        latestCandidateScore = -1
        state = .idle
    }

    func setTranslationSession(_ session: TranslationSession) {
        translationSession = session
        translateLatest()
    }

    func setReplyTranslationSession(_ session: TranslationSession) {
        replyTranslationSession = session
    }

    func speakReply(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let replyTranslationSession else {
            lastError = "Reply translation is not ready yet."
            return
        }
        do {
            let response = try await replyTranslationSession.translate(text)
            spokenReplyPreview = response.targetText
            speak(response.targetText, languageCode: detectedLanguageCode ?? "en")
        } catch {
            lastError = "Reply translation unavailable: \(error.localizedDescription)"
        }
    }

    func refreshOutputRoute() {
        updateOutputRoute()
    }

    func handleAudioInterruption(_ notification: Notification) {
        guard let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: rawType) else { return }
        switch type {
        case .began:
            state = .interrupted("Audio was interrupted. Resume the session when ready.")
        case .ended:
            try? AVAudioSession.sharedInstance().setActive(true)
            state = .interrupted("Audio is available again. Tap Start listening to resume.")
        @unknown default:
            state = .interrupted("Audio route changed. Restart the session to continue.")
        }
    }

    func speakLatestTranslation() {
        guard !translatedText.isEmpty else { return }
        speak(translatedText, languageCode: targetLanguageCode)
    }

    func updateTargetLanguage(_ code: String) {
        targetLanguageCode = code
        translationSession = nil
        replyTranslationSession = nil
        translatedText = ""
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.allowBluetooth, .allowBluetoothA2DP, .duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func startAudioCapture() throws {
        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        let requestBox = self.requestBox
        input.installTap(onBus: 0, bufferSize: 2048, format: format) { buffer, _ in
            requestBox.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
    }

    private func rebuildRecognitionTasks() {
        guard !recognizers.isEmpty, audioEngine.isRunning else { return }
        generation += 1
        let currentGeneration = generation
        tasks.forEach { $0.cancel() }
        tasks = []
        let newRequests = recognizers.map { pair -> SFSpeechAudioBufferRecognitionRequest in
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            request.taskHint = .dictation
            request.requiresOnDeviceRecognition = pair.recognizer.supportsOnDeviceRecognition
            return request
        }
        requestBox.replace(with: newRequests)
        activeInputCount = recognizers.count

        for (index, pair) in recognizers.enumerated() {
            let request = newRequests[index]
            let languageCode = pair.code
            let task = pair.recognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self else { return }
                if let result {
                    let text = result.bestTranscription.formattedString
                    let confidence = result.bestTranscription.segments.isEmpty
                        ? 0.0
                        : Double(result.bestTranscription.segments.map(\.confidence).reduce(0, +)) / Double(result.bestTranscription.segments.count)
                    Task { @MainActor in
                        guard self.generation == currentGeneration, self.state == .listening else { return }
                        self.receive(text: text, languageCode: languageCode, confidence: confidence, isFinal: result.isFinal)
                    }
                } else if let error {
                    Task { @MainActor in
                        guard self.generation == currentGeneration, self.state == .listening else { return }
                        self.lastError = error.localizedDescription
                    }
                }
            }
            tasks.append(task)
        }
    }

    private func receive(text: String, languageCode: String, confidence: Double, isFinal: Bool) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let score = confidence + min(Double(text.count), 80) * 0.001
        guard score >= latestCandidateScore || detectedLanguageCode == languageCode else { return }
        latestCandidateScore = score
        detectedLanguageCode = languageCode
        recognizedText = text
        scheduleTranslation(text, final: isFinal)
        if isFinal, !isRestarting {
            isRestarting = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(180))
                guard self.state == .listening else { self.isRestarting = false; return }
                self.rebuildRecognitionTasks()
                self.isRestarting = false
            }
        }
    }

    private func scheduleTranslation(_ text: String, final: Bool) {
        translationTask?.cancel()
        translationTask = Task { @MainActor in
            if !final {
                try? await Task.sleep(for: .milliseconds(650))
            }
            guard !Task.isCancelled, let session = translationSession else { return }
            do {
                let response = try await session.translate(text)
                guard !Task.isCancelled else { return }
                translatedText = response.targetText
                if final, contextMemory.last != response.targetText {
                    contextMemory.append(response.targetText)
                    if contextMemory.count > 6 { contextMemory.removeFirst(contextMemory.count - 6) }
                }
                if final, translatedText != lastSpokenTranslation {
                    lastSpokenTranslation = translatedText
                    speak(translatedText, languageCode: targetLanguageCode)
                }
            } catch {
                lastError = "Translation unavailable: \(error.localizedDescription)"
            }
        }
    }

    private func translateLatest() {
        guard !recognizedText.isEmpty else { return }
        scheduleTranslation(recognizedText, final: false)
    }

    private func speak(_ text: String, languageCode: String) {
        guard !text.isEmpty else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: languageCode)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(utterance)
    }

    private func updateOutputRoute() {
        let route = AVAudioSession.sharedInstance().currentRoute.outputs
        outputRouteName = route.first?.portName ?? "System audio"
    }

    private func stopAudioCapture() {
        if audioEngine.isRunning {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
        } else {
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}


private final class AudioRequestBox: @unchecked Sendable {
    private let lock = NSLock()
    private var requests: [SFSpeechAudioBufferRecognitionRequest] = []

    func replace(with newRequests: [SFSpeechAudioBufferRecognitionRequest]) {
        lock.lock()
        requests = newRequests
        lock.unlock()
    }

    func append(_ buffer: AVAudioPCMBuffer) {
        lock.lock()
        let current = requests
        lock.unlock()
        current.forEach { $0.append(buffer) }
    }
}
