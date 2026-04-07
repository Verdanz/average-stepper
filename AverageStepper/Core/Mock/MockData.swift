import CoreLocation
import Foundation

/// Preview and dev-only fixtures for SwiftUI previews when MapKit routing is unavailable.
enum MockData {
    static let samplePreferences = UserPreferences(
        strideMeters: 0.76,
        walkingSpeedMetersPerSecond: 1.4,
        loopClosureRadiusMeters: 100,
        units: .metric,
        hasCompletedOnboarding: true,
        celebratoryAnimationsEnabled: true,
        defaultTargetSteps: 5000
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

    /// Sample completed sessions for previews (two-day streak, mixed completions).
    static var sampleCompletedWalkHistory: [WalkSession] {
        let cal = Calendar.current
        let now = Date()
        let todayStart = cal.startOfDay(for: now)
        guard let yesterdayStart = cal.date(byAdding: .day, value: -1, to: todayStart) else { return [] }

        func session(
            started: Date,
            ended: Date,
            steps: Int,
            distance: Double,
            reason: WalkCompletionReason?
        ) -> WalkSession {
            WalkSession(
                startedAt: started,
                endedAt: ended,
                goal: WalkGoal(targetSteps: 5000),
                status: .completed,
                trackingPhase: .inactive,
                liveSteps: steps,
                liveDistanceMeters: distance,
                routeProgress01: 0.92,
                elapsedActiveTime: 2400,
                adherenceStatus: .onRoute,
                completionReason: reason
            )
        }

        let w1 = session(
            started: yesterdayStart.addingTimeInterval(8 * 3600),
            ended: yesterdayStart.addingTimeInterval(9 * 3600),
            steps: 4200,
            distance: 3200,
            reason: .reachedStepGoal
        )
        let w2 = session(
            started: todayStart.addingTimeInterval(7 * 3600 + 15 * 60),
            ended: todayStart.addingTimeInterval(8 * 3600 + 20 * 60),
            steps: 5100,
            distance: 4000,
            reason: .routeCompleted
        )
        return [w1, w2]
    }

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
        engine.achievements(from: sampleCompletedWalkHistory, asOf: Date())
    }
}
