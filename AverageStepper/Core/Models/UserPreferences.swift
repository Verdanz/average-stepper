import Foundation

/// Persisted user tuning for stride, speed, and first-run state.
struct UserPreferences: Codable, Equatable, Sendable {
    /// Average step length in meters (stride).
    var strideMeters: Double
    /// Assumed walking speed for ETA, in meters per second.
    var walkingSpeedMetersPerSecond: Double
    /// Max distance from start to consider a route a "loop" for scoring/UX copy.
    var loopClosureRadiusMeters: Double
    var units: MeasurementUnits
    var hasCompletedOnboarding: Bool

    static let `default` = UserPreferences(
        strideMeters: 0.76,
        walkingSpeedMetersPerSecond: 1.4,
        loopClosureRadiusMeters: 100,
        units: .metric,
        hasCompletedOnboarding: false
    )
}

enum MeasurementUnits: String, Codable, CaseIterable, Sendable {
    case metric
    case imperial
}

/// Future: load from HealthKit / user profile; MVP uses `UserPreferences.strideMeters` directly.
struct StrideProfile: Equatable, Sendable {
    var metersPerStep: Double

    static let `default` = StrideProfile(metersPerStep: UserPreferences.default.strideMeters)
}
