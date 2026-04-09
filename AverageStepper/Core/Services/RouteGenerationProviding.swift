import CoreLocation
import Foundation

enum RouteGenerationError: Error, Equatable, Sendable {
    case noLocation
    case directionsFailed(String)
    case noCandidateFound
}

/// Builds walking routes via `RouteGenerationService` → `RouteGenerationPipeline` (`MKDirections` walking legs).
protocol RouteGenerationProviding {
    func generateRoute(
        goal: WalkGoal,
        preferences: UserPreferences,
        around location: CLLocationCoordinate2D
    ) async throws -> GeneratedRoute
}
