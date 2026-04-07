import CoreLocation
import Foundation

/// Orchestrates waypoint heuristics + MapKit walking legs via `RouteGenerationPipeline`.
final class RouteGenerationService: RouteGenerationProviding {
    private let stepEstimator: StepDistanceEstimating
    private let directions: WalkingDirectionsProviding
    private let config: RoutingConfig

    init(
        stepEstimator: StepDistanceEstimating = StepDistanceEstimator(),
        directions: WalkingDirectionsProviding = MKDirectionsWalkingDirectionsService(),
        config: RoutingConfig = .default
    ) {
        self.stepEstimator = stepEstimator
        self.directions = directions
        self.config = config
    }

    func generateRoute(
        goal: WalkGoal,
        preferences: UserPreferences,
        around location: CLLocationCoordinate2D
    ) async throws -> GeneratedRoute {
        let pipeline = RouteGenerationPipeline(
            config: config,
            directions: directions,
            stepEstimator: stepEstimator
        )
        return try await pipeline.makeGeneratedRoute(goal: goal, preferences: preferences, start: location)
    }
}
