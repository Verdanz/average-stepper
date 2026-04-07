import Foundation

/// Tunable knobs for the MVP heuristic router. Adjust weights without changing call sites.
struct RoutingConfig: Sendable, Equatable {
    /// Acceptable relative error for total walking distance vs target (e.g. 0.15 = ±15%).
    var acceptableDistanceRelativeError: Double

    /// Hard cap on how far the route may end from the start to still count as a "good" loop (meters).
    var loopClosureRadiusMeters: Double

    /// Max loop / near-loop patterns to *attempt* (each issues multiple MKDirections requests).
    var maxLoopPatternAttempts: Int

    /// Polygon side counts to try for loop-like routes.
    var polygonSides: [Int]

    /// Extra rotation offsets (radians) applied to diversify loop shapes.
    var rotationJitterRadians: [Double]

    /// Bearings (radians, clockwise from east or standard math angle) for out-and-back legs — we use absolute offsets from north in generator.
    var outAndBackBearingsDegrees: [Double]

    /// How many top-scoring options to return to the UI.
    var topOptionsCount: Int

    /// Scoring weights (lower total score is better).
    var scoreWeights: RouteScoreWeights

    static let `default` = RoutingConfig(
        acceptableDistanceRelativeError: 0.18,
        loopClosureRadiusMeters: 120,
        maxLoopPatternAttempts: 18,
        polygonSides: [3, 4, 5],
        rotationJitterRadians: [0, .pi / 6, .pi / 3],
        outAndBackBearingsDegrees: [0, 35, 70, 120, 200, 260],
        topOptionsCount: 3,
        scoreWeights: .default
    )
}
