import Foundation

/// Writes lightweight, privacy-safe startup diagnostics to the app's Documents folder.
/// Speech transcripts and translated text are deliberately never written.
final class HawaianDiagnostics: @unchecked Sendable {
    static let shared = HawaianDiagnostics()

    private let lock = NSLock()
    private let fileName = "Hawaian-Diagnostics.log"

    private init() {}

    var logURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(fileName)
    }

    func mark(_ message: String) {
        lock.lock()
        defer { lock.unlock() }

        guard let url = logURL else { return }
        let formatter = ISO8601DateFormatter()
        let line = "\(formatter.string(from: Date())) | \(message)\n"
        guard let data = line.data(using: .utf8) else { return }

        do {
            if !FileManager.default.fileExists(atPath: url.path) {
                try data.write(to: url, options: .atomic)
            } else {
                let handle = try FileHandle(forWritingTo: url)
                defer { try? handle.close() }
                try handle.seekToEnd()
                try handle.write(contentsOf: data)
                try handle.synchronize()
            }
        } catch {
            // Diagnostics must never interfere with app startup.
        }
    }
}
