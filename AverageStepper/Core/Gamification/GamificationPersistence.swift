import Foundation

/// Completed walk history for achievements (local JSON, no backend).
struct PersistedGamification: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var sessions: [WalkSession]
}

/// JSON in Application Support: `walk_history.json`
final class GamificationPersistence {
    private let fileURL: URL

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let dir = base.appendingPathComponent("AverageStepper", isDirectory: true)
            self.fileURL = dir.appendingPathComponent("walk_history.json")
        }
    }

    func load() throws -> PersistedGamification? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(PersistedGamification.self, from: data)
    }

    func save(_ snapshot: PersistedGamification) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: fileURL, options: [.atomic])
    }
}
