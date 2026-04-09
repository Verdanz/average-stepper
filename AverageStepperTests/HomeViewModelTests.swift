import CoreLocation
import XCTest
@testable import AverageStepper

@MainActor
private final class StubRouteService: RouteGenerationProviding {
    var route: GeneratedRoute?
    var thrownError: Error?

    func generateRoute(
        goal: WalkGoal,
        preferences: UserPreferences,
        around location: CLLocationCoordinate2D
    ) async throws -> GeneratedRoute {
        if let err = thrownError { throw err }
        guard let route else {
            throw RouteGenerationError.noCandidateFound
        }
        return route
    }
}

@MainActor
final class HomeViewModelTests: XCTestCase {
    private var tempPersistenceURL: URL!
    private var persistence: WalkSessionPersistence!
    private var location: MockLocationService!
    private let coord = CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090)

    override func setUp() {
        super.setUp()
        tempPersistenceURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("home_vm_test_\(UUID().uuidString).json")
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

    private func idleWalkManager() -> WalkSessionManager {
        WalkSessionManager(
            persistence: persistence,
            locationService: location,
            restoreFromDisk: false
        )
    }

    func testGenerateRouteStopsLocationWhenWalkNotActive() async {
        let walk = idleWalkManager()
        let routeSvc = StubRouteService()
        routeSvc.route = MockData.generatedRoute(
            for: WalkGoal(targetSteps: 4000),
            near: coord,
            preferences: MockData.samplePreferences,
            stepEstimator: StepDistanceEstimator()
        )

        let vm = HomeViewModel(
            routeService: routeSvc,
            locationService: location,
            preferences: MockData.samplePreferences,
            stepEstimator: StepDistanceEstimator(),
            walkSession: walk
        )
        vm.targetSteps = 4000

        location.authorizationState = .authorizedWhenInUse
        location.latestLocation = CLLocation(latitude: coord.latitude, longitude: coord.longitude)

        _ = await vm.generateRoute()

        XCTAssertEqual(location.stopUpdatingLocationCallCount, 1)
    }

    func testGenerateRouteDoesNotStopLocationWhenWalkActive() async {
        let walk = idleWalkManager()
        let routeSvc = StubRouteService()
        routeSvc.route = MockData.generatedRoute(
            for: WalkGoal(targetSteps: 4000),
            near: coord,
            preferences: MockData.samplePreferences,
            stepEstimator: StepDistanceEstimator()
        )

        let vm = HomeViewModel(
            routeService: routeSvc,
            locationService: location,
            preferences: MockData.samplePreferences,
            stepEstimator: StepDistanceEstimator(),
            walkSession: walk
        )

        let sampleRoute = routeSvc.route!
        walk.begin(
            route: sampleRoute,
            selectedOption: sampleRoute.options[0],
            goal: WalkGoal(targetSteps: 4000),
            preferences: MockData.samplePreferences
        )

        location.authorizationState = .authorizedWhenInUse
        location.latestLocation = CLLocation(latitude: coord.latitude, longitude: coord.longitude)

        _ = await vm.generateRoute()

        XCTAssertEqual(location.stopUpdatingLocationCallCount, 0)
    }
}
