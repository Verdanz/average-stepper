import Foundation

/// Tunable thresholds for on-route detection and completion (MVP).
struct ActiveWalkConfig: Sendable, Equatable {
    /// Ignore GPS fixes worse than this horizontal accuracy (meters).
    var maxAcceptableHorizontalAccuracy: Double
    /// Do not add distance for moves faster than this (m/s) — filters GPS jumps / driving.
    var maxPlausibleWalkingSpeedMetersPerSecond: Double
    /// Distance from planned polyline considered "on route" (meters).
    var onRouteToleranceMeters: Double
    /// Between on-route and off-route — "slightly off".
    var slightlyOffRouteToleranceMeters: Double
    /// Complete when route progress reaches this fraction (0...1).
    var routeCompletionProgressThreshold: Double
    /// Complete when estimated steps reach this fraction of the step goal.
    var stepGoalCompletionThreshold: Double
    /// Minimum seconds of good GPS before leaving `waitingForGPS`.
    var minimumGoodFixSeconds: TimeInterval

    static let `default` = ActiveWalkConfig(
        maxAcceptableHorizontalAccuracy: 50,
        maxPlausibleWalkingSpeedMetersPerSecond: 5.5,
        onRouteToleranceMeters: 35,
        slightlyOffRouteToleranceMeters: 85,
        routeCompletionProgressThreshold: 0.92,
        stepGoalCompletionThreshold: 0.97,
        minimumGoodFixSeconds: 2
    )
}
