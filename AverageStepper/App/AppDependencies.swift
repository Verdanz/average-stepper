import CoreLocation
import Foundation
import Observation

/// Composition root for services and user preferences (MVP: local persistence).
@Observable
@MainActor
final class AppDependencies {
    var preferences: UserPreferences {
        didSet { UserPreferencesStore.save(preferences) }
    }

    let locationService: LocationProviding
    /// Same instance as `locationService` — use with `@Bindable` for authorization UI updates.
    let locationForObservation: LocationService
    let routeGenerationService: RouteGenerationProviding
    let stepEstimator: StepDistanceEstimating
    let walkSessionManager: WalkSessionManager
    let achievementEngine: AchievementProviding
    private let gamificationPersistence: GamificationPersistence

    /// When true, show “Simulate walk” on the active walk screen (Simulator-friendly).
    var debugSimulateWalk: Bool = false

    /// Completed walks for achievements (loaded/saved with `GamificationPersistence`).
    var walkHistory: [WalkSession] = []

    init(
        preferences: UserPreferences,
        locationService: LocationProviding,
        locationForObservation: LocationService,
        routeGenerationService: RouteGenerationProviding,
        stepEstimator: StepDistanceEstimating,
        walkSessionManager: WalkSessionManager,
        achievementEngine: AchievementProviding,
        walkHistory: [WalkSession] = [],
        gamificationPersistence: GamificationPersistence
    ) {
        self.preferences = preferences
        self.locationService = locationService
        self.locationForObservation = locationForObservation
        self.routeGenerationService = routeGenerationService
        self.stepEstimator = stepEstimator
        self.walkSessionManager = walkSessionManager
        self.achievementEngine = achievementEngine
        self.walkHistory = walkHistory
        self.gamificationPersistence = gamificationPersistence
    }

    /// Persists appended session to `walk_history.json`.
    func recordCompletedWalk(_ session: WalkSession) {
        walkHistory.append(session)
        try? gamificationPersistence.save(PersistedGamification(schemaVersion: 1, sessions: walkHistory))
    }

    /// Clears completed walks and achievement progress derived from history.
    func resetWalkHistoryAndAchievements() {
        walkHistory = []
        try? gamificationPersistence.save(PersistedGamification(schemaVersion: 1, sessions: []))
    }

    /// Clears walks and resets preferences to defaults while keeping onboarding complete.
    func resetAllLocalData() {
        resetWalkHistoryAndAchievements()
        var fresh = UserPreferences.default
        fresh.hasCompletedOnboarding = true
        preferences = fresh
    }

    static let live: AppDependencies = {
        let location = LocationService()
        let persistence = WalkSessionPersistence()
        let walk = WalkSessionManager(
            persistence: persistence,
            locationService: location,
            restoreFromDisk: true
        )
        let gamificationPersistence = GamificationPersistence()
        let loaded = try? gamificationPersistence.load()
        let history = loaded?.sessions ?? []
        let prefs = UserPreferencesStore.load()
        return AppDependencies(
            preferences: prefs,
            locationService: location,
            locationForObservation: location,
            routeGenerationService: RouteGenerationService(),
            stepEstimator: StepDistanceEstimator(),
            walkSessionManager: walk,
            achievementEngine: AchievementEngine(),
            walkHistory: history,
            gamificationPersistence: gamificationPersistence
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
        let gamificationPersistence = GamificationPersistence(
            fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("preview_gamification.json")
        )
        return AppDependencies(
            preferences: MockData.samplePreferences,
            locationService: location,
            locationForObservation: location,
            routeGenerationService: RouteGenerationService(),
            stepEstimator: StepDistanceEstimator(),
            walkSessionManager: walk,
            achievementEngine: AchievementEngine(),
            walkHistory: MockData.sampleCompletedWalkHistory,
            gamificationPersistence: gamificationPersistence
        )
    }()
}
