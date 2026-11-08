import AppIntents
import Foundation

private enum HawaianIntentKeys {
    static let pendingStart = "hawaian.pendingStart"
    static let pendingStop = "hawaian.pendingStop"
    static let latestTranslation = "hawaian.latestTranslation"
    static let latestTranscript = "hawaian.latestTranscript"
}

struct StartHawaianListeningIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Hawaian Listening"
    static let description = IntentDescription("Open Hawaian and start translating a conversation.")
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(true, forKey: HawaianIntentKeys.pendingStart)
        UserDefaults.standard.set(false, forKey: HawaianIntentKeys.pendingStop)
        return .result(dialog: "Opening Hawaian and preparing live conversation translation.")
    }
}

struct StopHawaianListeningIntent: AppIntent {
    static let title: LocalizedStringResource = "Stop Hawaian Listening"
    static let description = IntentDescription("Stop Hawaian's live conversation session.")
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(true, forKey: HawaianIntentKeys.pendingStop)
        UserDefaults.standard.set(false, forKey: HawaianIntentKeys.pendingStart)
        return .result(dialog: "Hawaian will stop the live session.")
    }
}

struct GetHawaianTranslationIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Latest Hawaian Translation"
    static let description = IntentDescription("Read the latest translated conversation from Hawaian.")
    static let openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        let translation = UserDefaults.standard.string(forKey: HawaianIntentKeys.latestTranslation) ?? ""
        guard !translation.isEmpty else {
            return .result(dialog: "There isn't a translated conversation yet.")
        }
        return .result(dialog: "\(translation)")
    }
}

struct HawaianShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartHawaianListeningIntent(),
            phrases: ["Start listening with \(.applicationName)", "Start a conversation with \(.applicationName)"],
            shortTitle: "Start listening",
            systemImageName: "waveform"
        )
        AppShortcut(
            intent: StopHawaianListeningIntent(),
            phrases: ["Stop listening with \(.applicationName)"],
            shortTitle: "Stop listening",
            systemImageName: "stop.fill"
        )
        AppShortcut(
            intent: GetHawaianTranslationIntent(),
            phrases: ["Read my latest translation in \(.applicationName)"],
            shortTitle: "Latest translation",
            systemImageName: "captions.bubble"
        )
    }
}
