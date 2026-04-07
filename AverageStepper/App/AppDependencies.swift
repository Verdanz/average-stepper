import CoreLocation
import Foundation
import Observation

/// Composition root for services and user preferences (MVP: in-memory preferences).
@Observable
@MainActor
final class AppDependencies {
    var preferences: UserPreferences
    let locationService: LocationProviding
    let routeGenerationService: RouteGenerationProviding
    let stepEstimator: StepDistanceEstimating
    let walkSessionManager: WalkSessionManager
    let achievementEngine: AchievementProviding

    /// When true, show “Simulate walk” on the active walk screen (Simulator-friendly).
    var debugSimulateWalk: Bool = false

    /// Walk history for achievements (MVP: stub array; TODO persist via SwiftData / files).
    var walkHistory: [WalkSession] = []

    init(
        preferences: UserPreferences,
        locationService: LocationProviding,
        routeGenerationService: RouteGenerationProviding,
        stepEstimator: StepDistanceEstimating,
        walkSessionManager: WalkSessionManager,
        achievementEngine: AchievementProviding
    ) {
        self.preferences = preferences
        self.locationService = locationService
        self.routeGenerationService = routeGenerationService
        self.stepEstimator = stepEstimator
        self.walkSessionManager = walkSessionManager
        self.achievementEngine = achievementEngine
    }

    static let live: AppDependencies = {
        let location = LocationService()
        let persistence = WalkSessionPersistence()
        let walk = WalkSessionManager(
            persistence: persistence,
            locationService: location,
            restoreFromDisk: true
        )
        return AppDependencies(
            preferences: UserPreferences.default,
            locationService: location,
            routeGenerationService: RouteGenerationService(),
            stepEstimator: StepDistanceEstimator(),
            walkSessionManager: walk,
            achievementEngine: AchievementEngine()
        )
    }()

    static let preview: AppDependencies = {
        let location = LocationService()
        let walk = WalkSessionManager(
            session: MockData.sampleWalkSession,
            persistence: WalkSessionPersistence(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("preview_walk.json")),
            locationService: location,
            restoreFromDisk: false
        )
        let mockRoute = MockData.generatedRoute(
            for: MockData.sampleGoal,
            near: CLLocationCoordinate2D(latitude: 37.33, longitude: -122.01),
            preferences: MockData.samplePreferences,
            stepEstimator: StepDistanceEstimator()
        )
        walk.attachPreviewRoute(mockRoute, option: mockRoute.options[0])
        return AppDependencies(
            preferences: MockData.samplePreferences,
            locationService: location,
            routeGenerationService: RouteGenerationService(),
            stepEstimator: StepDistanceEstimator(),
            walkSessionManager: walk,
            achievementEngine: AchievementEngine()
        )
    }()
}
