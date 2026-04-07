import CoreLocation
import Foundation
import Observation

@Observable
@MainActor
final class HomeViewModel {
    var targetSteps: Int = 5000
    var isGenerating = false
    var lastError: String?

    private let routeService: RouteGenerationProviding
    private let locationService: LocationProviding
    private let preferences: UserPreferences
    private let stepEstimator: StepDistanceEstimating

    init(
        routeService: RouteGenerationProviding,
        locationService: LocationProviding,
        preferences: UserPreferences,
        stepEstimator: StepDistanceEstimating
    ) {
        self.routeService = routeService
        self.locationService = locationService
        self.preferences = preferences
        self.stepEstimator = stepEstimator
    }

    /// Estimated distance for the current slider/input using stride from preferences.
    func estimatedDistanceMeters() -> Double {
        stepEstimator.estimatedDistanceMeters(forSteps: targetSteps, strideMeters: preferences.strideMeters)
    }

    func estimatedWalkDuration() -> TimeInterval {
        stepEstimator.estimatedDuration(
            distanceMeters: estimatedDistanceMeters(),
            speedMetersPerSecond: preferences.walkingSpeedMetersPerSecond
        )
    }

    /// Produces a route using current location or a fallback coordinate for previews/simulator.
    func generateRoute() async -> GeneratedRoute? {
        isGenerating = true
        lastError = nil
        defer { isGenerating = false }

        locationService.requestWhenInUseAuthorization()
        locationService.startUpdatingLocation()

        let coordinate: CLLocationCoordinate2D
        if let loc = locationService.latestLocation?.coordinate {
            coordinate = loc
        } else {
            // TODO: Block UI until we have a fix, or show explicit "location unknown" state.
            coordinate = CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090)
        }

        let goal = WalkGoal(targetSteps: targetSteps)

        do {
            return try await routeService.generateRoute(goal: goal, preferences: preferences, around: coordinate)
        } catch let error as RouteGenerationError {
            switch error {
            case .noCandidateFound:
                lastError = "Couldn’t build a walking route here. Try again or adjust your step goal."
            case .directionsFailed(let message):
                lastError = message
            case .noLocation:
                lastError = "Location is required to build a route."
            }
            return nil
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }
}
