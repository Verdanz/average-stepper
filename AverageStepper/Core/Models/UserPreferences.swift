import Foundation

/// User-editable defaults for stride, walking speed, units, onboarding, and the Plan screen’s default step goal.
/// Loaded/saved via `UserPreferencesStore` and injected through `AppDependencies`.
struct UserPreferences: Equatable, Sendable {
    /// Average step length in meters (stride).
    var strideMeters: Double
    /// Assumed walking speed for ETA, in meters per second.
    var walkingSpeedMetersPerSecond: Double
    /// Max distance from start to consider a route a "loop" for scoring/UX copy.
    var loopClosureRadiusMeters: Double
    var units: MeasurementUnits
    var hasCompletedOnboarding: Bool
    /// Soft celebration on walk complete (confetti-style).
    var celebratoryAnimationsEnabled: Bool
    /// Default step goal when opening Plan (quick picks sync to this in Settings).
    var defaultTargetSteps: Int

    static let `default` = UserPreferences(
        strideMeters: 0.76,
        walkingSpeedMetersPerSecond: 1.4,
        loopClosureRadiusMeters: 100,
        units: .metric,
        hasCompletedOnboarding: false,
        celebratoryAnimationsEnabled: true,
        defaultTargetSteps: 5000
    )
}

extension UserPreferences: Codable {
    enum CodingKeys: String, CodingKey {
        case strideMeters
        case walkingSpeedMetersPerSecond
        case loopClosureRadiusMeters
        case units
        case hasCompletedOnboarding
        case celebratoryAnimationsEnabled
        case defaultTargetSteps
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        strideMeters = try c.decodeIfPresent(Double.self, forKey: .strideMeters) ?? Self.default.strideMeters
        walkingSpeedMetersPerSecond = try c.decodeIfPresent(Double.self, forKey: .walkingSpeedMetersPerSecond)
            ?? Self.default.walkingSpeedMetersPerSecond
        loopClosureRadiusMeters = try c.decodeIfPresent(Double.self, forKey: .loopClosureRadiusMeters)
            ?? Self.default.loopClosureRadiusMeters
        units = try c.decodeIfPresent(MeasurementUnits.self, forKey: .units) ?? Self.default.units
        hasCompletedOnboarding = try c.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding)
            ?? Self.default.hasCompletedOnboarding
        celebratoryAnimationsEnabled = try c.decodeIfPresent(Bool.self, forKey: .celebratoryAnimationsEnabled)
            ?? Self.default.celebratoryAnimationsEnabled
        defaultTargetSteps = try c.decodeIfPresent(Int.self, forKey: .defaultTargetSteps) ?? Self.default.defaultTargetSteps
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(strideMeters, forKey: .strideMeters)
        try c.encode(walkingSpeedMetersPerSecond, forKey: .walkingSpeedMetersPerSecond)
        try c.encode(loopClosureRadiusMeters, forKey: .loopClosureRadiusMeters)
        try c.encode(units, forKey: .units)
        try c.encode(hasCompletedOnboarding, forKey: .hasCompletedOnboarding)
        try c.encode(celebratoryAnimationsEnabled, forKey: .celebratoryAnimationsEnabled)
        try c.encode(defaultTargetSteps, forKey: .defaultTargetSteps)
    }
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
