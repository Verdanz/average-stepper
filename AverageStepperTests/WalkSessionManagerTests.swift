import CoreLocation
import XCTest
@testable import AverageStepper

@MainActor
final class WalkSessionManagerTests: XCTestCase {
    private var tempPersistenceURL: URL!
    private var persistence: WalkSessionPersistence!
    private var location: MockLocationService!

    private let coord = CLLocationCoordinate2D(latitude: 37.33, longitude: -122.01)

    override func setUp() {
        super.setUp()
        tempPersistenceURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("walk_test_\(UUID().uuidString).json")
        persistence = WalkSessionPersistence(fileURL: tempPersistenceURL)
        location = MockLocationService()
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempPersistenceURL)
        tempPersistenceURL = nil
        persistence = nil
        location = nil
        super.tearDown()
    }

    private func testConfig() -> ActiveWalkConfig {
        ActiveWalkConfig(
            maxAcceptableHorizontalAccuracy: 50,
            maxPlausibleWalkingSpeedMetersPerSecond: 5.5,
            onRouteToleranceMeters: 35,
            slightlyOffRouteToleranceMeters: 85,
            routeCompletionProgressThreshold: 0.92,
            stepGoalCompletionThreshold: 0.97,
            minimumGoodFixSeconds: 0
        )
    }

    private func makeManager() -> WalkSessionManager {
        WalkSessionManager(
            persistence: persistence,
            locationService: location,
            config: testConfig(),
            restoreFromDisk: false
        )
    }

    private func sampleRouteAndOption() -> (GeneratedRoute, RouteOption) {
        let route = MockData.generatedRoute(
            for: MockData.sampleGoal,
            near: coord,
            preferences: MockData.samplePreferences,
            stepEstimator: StepDistanceEstimator()
        )
        return (route, route.options[0])
    }

    func testBeginStartsActiveWaitingForGPS() {
        let mgr = makeManager()
        let (route, option) = sampleRouteAndOption()
        mgr.begin(
            route: route,
            selectedOption: option,
            goal: MockData.sampleGoal,
            preferences: MockData.samplePreferences
        )
        XCTAssertEqual(mgr.session.status, .active)
        XCTAssertEqual(mgr.session.trackingPhase, .waitingForGPS)
        XCTAssertNil(mgr.session.endedAt)
    }

    func testGoodFixTransitionsToTracking() {
        let mgr = makeManager()
        let (route, option) = sampleRouteAndOption()
        mgr.begin(
            route: route,
            selectedOption: option,
            goal: MockData.sampleGoal,
            preferences: MockData.samplePreferences
        )
        let fix = CLLocation(
            coordinate: coord,
            altitude: 0,
            horizontalAccuracy: 10,
            verticalAccuracy: 0,
            timestamp: Date()
        )
        location.emit(fix)
        XCTAssertEqual(mgr.session.trackingPhase, .tracking)
    }

    func testPauseResume() {
        let mgr = makeManager()
        let (route, option) = sampleRouteAndOption()
        mgr.begin(
            route: route,
            selectedOption: option,
            goal: MockData.sampleGoal,
            preferences: MockData.samplePreferences
        )
        location.emit(
            CLLocation(
                coordinate: coord,
                altitude: 0,
                horizontalAccuracy: 10,
                verticalAccuracy: 0,
                timestamp: Date()
            )
        )
        mgr.pause()
        XCTAssertEqual(mgr.session.trackingPhase, .paused)
        mgr.resume()
        XCTAssertEqual(mgr.session.trackingPhase, .tracking)
    }

    func testCompleteSetsCompletedAndClearsPersistence() throws {
        let mgr = makeManager()
        let (route, option) = sampleRouteAndOption()
        mgr.begin(
            route: route,
            selectedOption: option,
            goal: MockData.sampleGoal,
            preferences: MockData.samplePreferences
        )
        location.emit(
            CLLocation(
                coordinate: coord,
                altitude: 0,
                horizontalAccuracy: 10,
                verticalAccuracy: 0,
                timestamp: Date()
            )
        )
        mgr.complete(reason: .userEnded)
        XCTAssertEqual(mgr.session.status, .completed)
        XCTAssertEqual(mgr.session.completionReason, .userEnded)
        XCTAssertNotNil(mgr.session.endedAt)
        XCTAssertNil(persistence.load())
    }

    func testCancelSetsCancelled() {
        let mgr = makeManager()
        let (route, option) = sampleRouteAndOption()
        mgr.begin(
            route: route,
            selectedOption: option,
            goal: MockData.sampleGoal,
            preferences: MockData.samplePreferences
        )
        mgr.cancel()
        XCTAssertEqual(mgr.session.status, .cancelled)
        XCTAssertEqual(mgr.session.completionReason, .aborted)
    }

    func testResetIdleReturnsIdleSession() {
        let mgr = makeManager()
        let (route, option) = sampleRouteAndOption()
        mgr.begin(
            route: route,
            selectedOption: option,
            goal: MockData.sampleGoal,
            preferences: MockData.samplePreferences
        )
        mgr.resetIdle()
        XCTAssertEqual(mgr.session.status, .idle)
        XCTAssertEqual(mgr.session.goal.targetSteps, 0)
        XCTAssertNil(mgr.activeRoute)
    }
}
