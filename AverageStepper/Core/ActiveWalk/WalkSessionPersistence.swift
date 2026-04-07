import Foundation

/// Encodes enough state to resume an in-progress walk after process death.
struct PersistedWalkSnapshot: Codable, Equatable, Sendable {
    var session: WalkSession
    var generatedRoute: GeneratedRoute
    var selectedRouteOption: RouteOption
    /// Best route progress seen (avoids regress when GPS jumps backward).
    var routeProgressHighWaterMark: Double
}

/// JSON file in Application Support (`active_walk_snapshot.json`).
final class WalkSessionPersistence {
    private let fileURL: URL

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let dir = base.appendingPathComponent("AverageStepper", isDirectory: true)
            self.fileURL = dir.appendingPathComponent("active_walk_snapshot.json")
        }
    }

    func save(_ snapshot: PersistedWalkSnapshot) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: fileURL, options: [.atomic])
    }

    func load() -> PersistedWalkSnapshot? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(PersistedWalkSnapshot.self, from: data)
        } catch {
            return nil
        }
    }

    func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
