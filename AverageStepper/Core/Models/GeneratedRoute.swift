import Foundation

/// Result of route generation: up to three scored options; the user picks one before starting.
struct GeneratedRoute: Identifiable, Equatable, Hashable, Codable, Sendable {
    var id: UUID
    var createdAt: Date
    var goal: WalkGoal
    /// Target distance implied by steps × stride (meters).
    var targetDistanceMeters: Double
    /// Best options first (lower `RouteOption.score` is better).
    var options: [RouteOption]

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        goal: WalkGoal,
        targetDistanceMeters: Double,
        options: [RouteOption]
    ) {
        self.id = id
        self.createdAt = createdAt
        self.goal = goal
        self.targetDistanceMeters = targetDistanceMeters
        self.options = options
    }
}
