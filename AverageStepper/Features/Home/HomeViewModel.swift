import CoreLocation
import Foundation
import Observation

@Observable
@MainActor
final class HomeViewModel {
    var targetSteps: Int
    var isGenerating = false
    /// Blocking error (e.g. route failure, permission).
    var lastError: String?
    /// Non-blocking hint (GPS quality, waiting for fix).
    var routeHint: String?

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
        self.targetSteps = preferences.defaultTargetSteps
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

    func clearError() {
        lastError = nil
    }

    /// Produces a route using current location or a fallback coordinate for previews/simulator.
    func generateRoute() async -> GeneratedRoute? {
        isGenerating = true
        lastError = nil
        routeHint = nil
        defer { isGenerating = false }

        locationService.requestWhenInUseAuthorization()
        locationService.startUpdatingLocation()

        switch locationService.authorizationState {
        case .denied:
            lastError = AppCopy.Generation.deniedShort
            return nil
        case .notDetermined, .authorizedWhenInUse, .authorizedAlways:
            break
        }

        let coordinate: CLLocationCoordinate2D
        if let loc = locationService.latestLocation {
            coordinate = loc.coordinate
            let acc = loc.horizontalAccuracy
            if acc > 0, acc > 80 {
                routeHint = AppCopy.GPS.lowAccuracy
            }
        } else {
            coordinate = CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090)
            routeHint = AppCopy.Generation.noLocationFix
        }

        let goal = WalkGoal(targetSteps: targetSteps)

        do {
            return try await routeService.generateRoute(goal: goal, preferences: preferences, around: coordinate)
        } catch let error as RouteGenerationError {
            switch error {
            case .noCandidateFound:
                lastError = AppCopy.Generation.noRouteNearby()
            case .directionsFailed(let message):
                lastError = AppCopy.Generation.directionsFailed(message)
            case .noLocation:
                lastError = AppCopy.Generation.noLocationFix
            }
            return nil
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }
}
