import SwiftUI
import Translation
import AVFoundation

struct ContentView: View {
    @StateObject private var engine = LiveConversationEngine()
    @StateObject private var languageCatalog = LanguageCatalog()
    @State private var selectedIntent: ConversationIntent = .everyday
    @State private var selectedReplyID = "acknowledge"
    @State private var replyFill = ""
    @State private var showIntentPicker = false
    @State private var showSettings = false
    @State private var isStarting = false
    @AppStorage("translationTargetLanguage") private var selectedLanguage = "en"
    @AppStorage("inputLanguageCode") private var inputLanguageCode = "auto"
    @AppStorage("ignoreDeviceLanguage") private var ignoreDeviceLanguage = true
    @AppStorage("hawaian.pendingStart") private var pendingStart = false
    @AppStorage("hawaian.pendingStop") private var pendingStop = false

    private var targetLanguage: Locale.Language {
        Locale.Language(identifier: selectedLanguage)
    }

    private var replyCandidates: [SmartReplyEngine.Candidate] {
        SmartReplyEngine.candidates(for: selectedIntent, incomingText: engine.translatedText, recentContext: engine.contextMemory)
    }

    private var selectedReply: SmartReplyEngine.Candidate? {
        replyCandidates.first { $0.id == selectedReplyID }
    }

    var body: some View {
        ZStack {
            HawaianBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    languageBar
                    visualizerSection
                    conversationSection
                    intentSection
                    replySection
                    footer
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 36)
            }
        }
        .translationTask(source: engine.translationSource, target: targetLanguage) { session in
            engine.setTranslationSession(session)
        }
        .translationTask(source: targetLanguage, target: engine.translationSource) { session in
            engine.setReplyTranslationSession(session)
        }
        .task {
            await languageCatalog.load(excludingDeviceLanguage: ignoreDeviceLanguage, targetLanguageCode: selectedLanguage)
            if pendingStop {
                pendingStop = false
                engine.stop()
            }
            if pendingStart {
                pendingStart = false
                await startListening()
            }
        }
        .onChange(of: selectedLanguage) { _, code in
            engine.updateTargetLanguage(code)
            Task { await languageCatalog.load(excludingDeviceLanguage: ignoreDeviceLanguage, targetLanguageCode: code) }
        }
        .onChange(of: ignoreDeviceLanguage) { _, enabled in
            Task { await languageCatalog.load(excludingDeviceLanguage: enabled, targetLanguageCode: selectedLanguage) }
            if engine.isListening {
                engine.stop()
                Task { await startListening() }
            }
        }
        .onChange(of: inputLanguageCode) { _, _ in
            if engine.isListening {
                engine.stop()
                Task { await startListening() }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)) { _ in
            engine.refreshOutputRoute()
        }
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { notification in
            engine.handleAudioInterruption(notification)
        }
        .onChange(of: pendingStart) { _, requested in
            guard requested else { return }
            pendingStart = false
            Task { await startListening() }
        }
        .onChange(of: pendingStop) { _, requested in
            guard requested else { return }
            pendingStop = false
            engine.stop()
        }
        .onChange(of: engine.translatedText) { _, value in
            UserDefaults.standard.set(value, forKey: "hawaian.latestTranslation")
        }
        .onChange(of: engine.recognizedText) { _, value in
            UserDefaults.standard.set(value, forKey: "hawaian.latestTranscript")
        }
        .sheet(isPresented: $showIntentPicker) {
            intentSheet.presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSettings) {
            settingsSheet.presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("HAWAIAN")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(.white.opacity(0.62))
                Text("Speak freely.")
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .tracking(-1.2)
            }
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .glassEffect(.regular, in: Circle())
            }
            .accessibilityLabel("Settings")
        }
    }

    private var languageBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
            Menu {
                Button("Auto detect (up to 8 languages)") { inputLanguageCode = "auto" }
                ForEach(languageCatalog.speechInputLocales, id: \.identifier) { locale in
                    Button(languageCatalog.displayName(for: locale.identifier)) {
                        inputLanguageCode = locale.language.languageCode?.identifier ?? locale.identifier
                    }
                }
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "waveform")
                    Text(inputLanguageCode == "auto" ? "Auto" : languageCatalog.displayName(for: inputLanguageCode))
                    Image(systemName: "chevron.down").font(.system(size: 10, weight: .bold))
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .glassEffect(.regular, in: Capsule())
            }
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))
            Menu {
                ForEach(languageCatalog.translationLanguages, id: \.minimalIdentifier) { language in
                    Button(languageCatalog.displayName(for: language.minimalIdentifier)) {
                        selectedLanguage = language.minimalIdentifier
                    }
                }
            } label: {
                HStack(spacing: 7) {
                    Text(languageCatalog.displayName(for: selectedLanguage))
                    Image(systemName: "chevron.down").font(.system(size: 10, weight: .bold))
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .glassEffect(.regular, in: Capsule())
            }
                Spacer(minLength: 0)
            }
            HStack(spacing: 7) {
            Image(systemName: "speaker.slash")
            Text(ignoreDeviceLanguage
                 ? "Ignoring device language: \(languageCatalog.displayName(for: SpeechLanguagePolicy.deviceLanguageCode()))"
                 : "Device language is included")
            Spacer()
            Text(inputLanguageCode == "auto" ? "Auto: max 8" : "Manual input")
                .monospacedDigit()
        }
        .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.cyan.opacity(0.82))
        }
    }

    private func languagePill(_ title: String, icon: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: Capsule())
    }

    private var visualizerSection: some View {
        VStack(spacing: 18) {
            SiriOrbView(isActive: engine.isListening)
                .frame(height: 210)
                .frame(maxWidth: .infinity)
            VStack(spacing: 6) {
                Text(statusTitle)
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(statusSubtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
            }
            Button {
                if engine.isListening {
                    engine.stop()
                } else {
                    Task { await startListening() }
                }
            } label: {
                HStack(spacing: 10) {
                    if isStarting || engine.state == .requestingPermission {
                        ProgressView().tint(.black)
                    } else {
                        Image(systemName: engine.isListening ? "pause.fill" : "waveform")
                            .font(.system(size: 14, weight: .bold))
                    }
                    Text(engine.isListening ? "Pause session" : "Start listening")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.black.opacity(0.88))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(
                    LinearGradient(colors: [Color.white, Color(red: 0.78, green: 0.88, blue: 1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: Capsule()
                )
            }
            .disabled(isStarting || engine.state == .requestingPermission)
            .buttonStyle(.plain)
            if let error = engine.lastError ?? stateError {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(LinearGradient(colors: [.white.opacity(0.24), .white.opacity(0.035)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        }
    }

    private var statusTitle: String {
        switch engine.state {
        case .idle: "Your conversations, understood"
        case .requestingPermission: "Preparing your session"
        case .listening: "Listening to the moment"
        case .interrupted: "Session interrupted"
        case .failed: "Could not start"
        }
    }

    private var statusSubtitle: String {
        switch engine.state {
        case .idle: "Translation stays ready when you are."
        case .requestingPermission: "Checking microphone and speech permissions."
        case .listening: "Live speech recognition and translation are active."
        case .interrupted(let reason), .failed(let reason): reason
        }
    }

    private var stateError: String? {
        if case .failed(let message) = engine.state { return message }
        if case .interrupted(let message) = engine.state { return message }
        return nil
    }

    private var conversationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading("LIVE CONVERSATION", subtitle: engine.detectedLanguageCode.map { languageCatalog.displayName(for: $0) } ?? "Waiting for speech")
            VStack(alignment: .leading, spacing: 8) {
                Text("HEARD")
                    .font(.system(size: 9, weight: .bold)).tracking(1.6)
                    .foregroundStyle(.white.opacity(0.42))
                Text(engine.recognizedText.isEmpty ? "Your conversation will appear here as people speak." : engine.recognizedText)
                    .font(.system(size: 14))
                    .foregroundStyle(engine.recognizedText.isEmpty ? .white.opacity(0.36) : .white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider().overlay(.white.opacity(0.12))
                HStack {
                    Text("TRANSLATION")
                        .font(.system(size: 9, weight: .bold)).tracking(1.6)
                        .foregroundStyle(.cyan.opacity(0.8))
                    Spacer()
                    Button { engine.speakLatestTranslation() } label: {
                        Image(systemName: "speaker.wave.2.fill").foregroundStyle(.cyan)
                    }
                    .disabled(engine.translatedText.isEmpty)
                    .accessibilityLabel("Play translation")
                }
                Text(engine.translatedText.isEmpty ? "The translated meaning will appear here." : engine.translatedText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(engine.translatedText.isEmpty ? .white.opacity(0.36) : .white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            HStack(spacing: 6) {
                Image(systemName: "airpodspro")
                Text("Audio output: \(engine.outputRouteName)")
                Spacer()
                Text("Automatic routing")
            }
            .font(.system(size: 10))
            .foregroundStyle(.white.opacity(0.48))
        }
    }

    private var intentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CONVERSATION INTENT")
                        .font(.system(size: 10, weight: .bold)).tracking(2.2)
                        .foregroundStyle(.white.opacity(0.48))
                    Text(selectedIntent.title)
                        .font(.system(size: 23, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
                Button("Change") { showIntentPicker = true }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.cyan)
            }
            HStack(spacing: 12) {
                Image(systemName: selectedIntent.symbol)
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(.cyan)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedIntent.subtitle)
                        .font(.system(size: 14, weight: .medium)).foregroundStyle(.white)
                    Text(selectedIntent.guidance)
                        .font(.system(size: 12)).foregroundStyle(.white.opacity(0.52)).lineLimit(2)
                }
                Spacer(minLength: 0)
            }
            .padding(15)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    private var replySection: some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionHeading("SMART REPLY", subtitle: "Choose a structure, then add your meaning")
            ForEach(replyCandidates) { candidate in
                Button {
                    selectedReplyID = candidate.id
                    replyFill = ""
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: selectedReplyID == candidate.id ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selectedReplyID == candidate.id ? .cyan : .white.opacity(0.35))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(candidate.title).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                            Text(candidate.body).font(.system(size: 12)).foregroundStyle(.white.opacity(0.56))
                        }
                        Spacer()
                    }
                    .padding(14)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            if let selectedReply {
                if selectedReply.requiresFill {
                    Text(selectedReply.fillPrompt ?? "Add your details")
                        .font(.system(size: 11, weight: .medium)).foregroundStyle(.cyan)
                    TextField("Your words", text: $replyFill)
                        .textFieldStyle(.roundedBorder)
                }
                let response = SmartReplyEngine.fill(selectedReply, with: replyFill)
                Text(response)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(13)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                Button {
                    Task { await engine.speakReply(response) }
                } label: {
                    Label("Translate and speak reply", systemImage: "waveform")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.cyan.opacity(0.92), in: Capsule())
                }
                .disabled(!engine.isListening || (selectedReply.requiresFill && replyFill.isEmpty))
                if !engine.spokenReplyPreview.isEmpty {
                    Text("Spoken: \(engine.spokenReplyPreview)")
                        .font(.system(size: 11))
                        .foregroundStyle(.cyan.opacity(0.8))
                }
            }
        }
    }

    private func sectionHeading(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 10, weight: .bold)).tracking(2.1).foregroundStyle(.white.opacity(0.48))
            Text(subtitle).font(.system(size: 12)).foregroundStyle(.white.opacity(0.55))
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield")
            Text("Audio is processed by Apple Speech and Translation services.")
        }
        .font(.system(size: 10))
        .foregroundStyle(.white.opacity(0.38))
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private var settingsSheet: some View {
        NavigationStack {
            Form {
                Section("Speech input") {
                    Toggle("Ignore device language", isOn: $ignoreDeviceLanguage)
                    Text(ignoreDeviceLanguage
                         ? "The iPhone's preferred language is excluded from recognition candidates."
                         : "The iPhone's preferred language can be recognized.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Text("Available speech languages: \(languageCatalog.speechInputLocales.count). Auto mode uses up to 8 concurrent recognizers to keep latency and battery use manageable.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Translation") {
                    Picker("Translate into", selection: $selectedLanguage) {
                        ForEach(languageCatalog.translationLanguages, id: \.minimalIdentifier) { language in
                            Text(languageCatalog.displayName(for: language.minimalIdentifier)).tag(language.minimalIdentifier)
                        }
                    }
                }
                Section("Audio") {
                    Label(engine.outputRouteName, systemImage: "airpodspro")
                    Text("Hawaian follows iOS audio routing. Connect AirPods or another Bluetooth audio device before starting for private listening.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Siri AI") {
                    Label("App Intents enabled", systemImage: "sparkles")
                    Text("Siri AI can discover Hawaian actions through App Intents. Siri decides how to interpret your natural-language request; Hawaian does not call Siri's private model directly.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Privacy") {
                    Text("Live listening uses Apple's Speech framework. Some speech locales require an internet connection. Apple's Translation framework processes translated text on device.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showSettings = false }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var intentSheet: some View {
        NavigationStack {
            List {
                ForEach(ConversationIntent.allCases) { intent in
                    Button {
                        selectedIntent = intent
                        showIntentPicker = false
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: intent.symbol).frame(width: 28).foregroundStyle(.cyan)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(intent.title).foregroundStyle(.primary)
                                Text(intent.subtitle).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selectedIntent == intent { Image(systemName: "checkmark").foregroundStyle(.cyan) }
                        }
                    }
                }
            }
            .navigationTitle("Conversation intent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showIntentPicker = false }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    @MainActor
    private func startListening() async {
        guard !isStarting else { return }
        isStarting = true
        await engine.start(targetLanguageCode: selectedLanguage, excludeDeviceLanguage: ignoreDeviceLanguage, inputLanguageCode: inputLanguageCode)
        isStarting = false
    }
}

private struct HawaianBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.025, green: 0.035, blue: 0.075)
            RadialGradient(colors: [Color.blue.opacity(0.25), .clear], center: .topTrailing, startRadius: 10, endRadius: 390)
            RadialGradient(colors: [Color.purple.opacity(0.19), .clear], center: .center, startRadius: 20, endRadius: 330)
            LinearGradient(colors: [.clear, Color.black.opacity(0.35)], startPoint: .top, endPoint: .bottom)
        }
        .ignoresSafeArea()
    }
}

private struct SiriOrbView: View {
    let isActive: Bool
    @State private var phase = false

    var body: some View {
        ZStack {
            Circle().fill(Color.cyan.opacity(0.08)).frame(width: 190, height: 190).blur(radius: 34).scaleEffect(phase ? 1.22 : 0.88)
            ForEach(0..<3) { index in
                Circle().stroke(.white.opacity(0.09 - Double(index) * 0.018), lineWidth: 1)
                    .frame(width: CGFloat(142 + index * 34), height: CGFloat(142 + index * 34))
                    .scaleEffect(phase ? 1.035 : 0.965)
            }
            ZStack {
                Circle().fill(AngularGradient(colors: [
                    Color(red: 0.24, green: 0.88, blue: 1),
                    Color(red: 0.45, green: 0.48, blue: 1),
                    Color(red: 0.87, green: 0.42, blue: 0.94),
                    Color(red: 1, green: 0.58, blue: 0.76),
                    Color(red: 0.24, green: 0.88, blue: 1)
                ], center: .center, angle: .degrees(phase ? 250 : 35)))
                .frame(width: 112, height: 112).blur(radius: 1)
                Circle().fill(.white.opacity(0.16)).frame(width: 84, height: 84).blur(radius: 16).offset(x: -15, y: -17)
                Circle().fill(.black.opacity(0.16)).frame(width: 74, height: 74).blur(radius: 13).offset(x: 18, y: 16)
                Circle().stroke(.white.opacity(0.34), lineWidth: 0.8).frame(width: 110, height: 110)
            }
            .shadow(color: .cyan.opacity(phase ? 0.45 : 0.2), radius: isActive ? 34 : 22)
            .scaleEffect(isActive ? (phase ? 1.12 : 0.94) : (phase ? 1.035 : 0.97))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: isActive ? 0.85 : 2.8).repeatForever(autoreverses: true)) { phase = true }
        }
        .onChange(of: isActive) { _, active in
            withAnimation(.easeInOut(duration: active ? 0.55 : 2.8).repeatForever(autoreverses: true)) { phase.toggle() }
        }
        .accessibilityLabel(isActive ? "Hawaian voice visualizer active" : "Hawaian voice visualizer idle")
    }
}

#Preview {
    ContentView()
}
