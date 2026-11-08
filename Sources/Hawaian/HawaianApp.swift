import SwiftUI

@main
struct HawaianApp: App {
    init() {
        HawaianDiagnostics.shared.mark("APP process initialized")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
