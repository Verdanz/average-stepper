import Foundation

/// A candidate route the user can select before starting a walk.
struct RouteOption: Identifiable, Equatable, Hashable, Codable, Sendable {
    var id: UUID
    /// Total planned walking distance along the route polyline (meters).
    var distanceMeters: Double
    /// Estimated steps from distance ÷ stride (display; not a guarantee).
    var estimatedSteps: Int
    /// Sum of expected travel times from MapKit legs.
    var estimatedDuration: TimeInterval
    /// Ordered polyline for map display.
    var coordinates: [LatLon]
    /// Lower is better (weighted heuristic).
    var score: Double
    var kind: RoutePatternKind
    /// Human-readable hint (e.g. "Loop (4 sides)").
    var label: String

    init(
        id: UUID = UUID(),
        distanceMeters: Double,
        estimatedSteps: Int,
        estimatedDuration: TimeInterval,
        coordinates: [LatLon],
        score: Double,
        kind: RoutePatternKind,
        label: String
    ) {
        self.id = id
        self.distanceMeters = distanceMeters
        self.estimatedSteps = estimatedSteps
        self.estimatedDuration = estimatedDuration
        self.coordinates = coordinates
        self.score = score
        self.kind = kind
        self.label = label
    }
}
