import CoreLocation
import Foundation

/// Preview and dev-only fixtures for SwiftUI previews when MapKit routing is unavailable.
enum MockData {
    static let samplePreferences = UserPreferences(
        strideMeters: 0.76,
        walkingSpeedMetersPerSecond: 1.4,
        loopClosureRadiusMeters: 100,
        units: .metric,
        hasCompletedOnboarding: true
    )

    static let sampleGoal = WalkGoal(targetSteps: 5000)

    static let sampleWalkSession = WalkSession(
        goal: WalkGoal(targetSteps: 5000),
        status: .active,
        trackingPhase: .tracking,
        liveSteps: 1200,
        liveDistanceMeters: 900,
        routeProgress01: 0.35,
        elapsedActiveTime: 600,
        adherenceStatus: .onRoute
    )

    static let allBadgeDefinitions: [Badge] = [
        Badge(id: "first_walk", title: "First Steps", detail: "Complete your first walk.", systemImageName: "figure.walk"),
        Badge(id: "target_5k", title: "5K Dream", detail: "Finish a walk with a 5,000 step target.", systemImageName: "5.circle"),
        Badge(id: "target_10k", title: "10K Club", detail: "Finish a walk with a 10,000 step target.", systemImageName: "10.circle"),
        Badge(id: "streak_7", title: "Week Streak", detail: "Hit your goal 7 days in a row.", systemImageName: "flame"),
        Badge(id: "streak_30", title: "Month Streak", detail: "Hit your goal 30 days in a row.", systemImageName: "flame.fill"),
        Badge(id: "walker_10", title: "Regular", detail: "Complete 10 walks.", systemImageName: "star.fill")
    ]

    /// Deterministic fake routes for canvas previews (not MapKit-backed).
    static func generatedRoute(
        for goal: WalkGoal,
        near coordinate: CLLocationCoordinate2D,
        preferences: UserPreferences,
        stepEstimator: StepDistanceEstimating
    ) -> GeneratedRoute {
        let targetDistance = stepEstimator.targetMeters(forSteps: goal.targetSteps, strideMeters: preferences.strideMeters)
        let d = min(max(targetDistance / 4, 120), 800) / 111_000.0
        let corners: [LatLon] = [
            LatLon(coordinate),
            LatLon(CLLocationCoordinate2D(latitude: coordinate.latitude + d, longitude: coordinate.longitude + d)),
            LatLon(CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude + 2 * d)),
            LatLon(CLLocationCoordinate2D(latitude: coordinate.latitude - d, longitude: coordinate.longitude + d)),
            LatLon(coordinate)
        ]

        let distance = max(targetDistance * 0.98, 200)
        let estSteps = stepEstimator.estimatedSteps(forDistanceMeters: distance, strideMeters: preferences.strideMeters)
        let duration = stepEstimator.estimatedDuration(distanceMeters: distance, speedMetersPerSecond: preferences.walkingSpeedMetersPerSecond)

        let opt1 = RouteOption(
            distanceMeters: distance,
            estimatedSteps: estSteps,
            estimatedDuration: duration,
            coordinates: corners,
            score: 0.42,
            kind: .loopPolygon,
            label: "Loop (preview)"
        )

        let opt2 = RouteOption(
            distanceMeters: distance * 0.93,
            estimatedSteps: stepEstimator.estimatedSteps(forDistanceMeters: distance * 0.93, strideMeters: preferences.strideMeters),
            estimatedDuration: stepEstimator.estimatedDuration(distanceMeters: distance * 0.93, speedMetersPerSecond: preferences.walkingSpeedMetersPerSecond),
            coordinates: Array(corners.reversed()),
            score: 0.55,
            kind: .nearLoop,
            label: "Near-loop (preview)"
        )

        let opt3 = RouteOption(
            distanceMeters: distance * 1.05,
            estimatedSteps: stepEstimator.estimatedSteps(forDistanceMeters: distance * 1.05, strideMeters: preferences.strideMeters),
            estimatedDuration: stepEstimator.estimatedDuration(distanceMeters: distance * 1.05, speedMetersPerSecond: preferences.walkingSpeedMetersPerSecond),
            coordinates: corners,
            score: 0.61,
            kind: .outAndBack,
            label: "Out & back (preview)"
        )

        return GeneratedRoute(
            goal: goal,
            targetDistanceMeters: targetDistance,
            options: [opt1, opt2, opt3]
        )
    }

    static func sampleAchievements(engine: AchievementProviding = AchievementEngine()) -> [Achievement] {
        engine.achievements(from: [])
    }
}
