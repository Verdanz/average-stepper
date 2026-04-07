import CoreLocation
import Foundation

enum RouteGenerationError: Error, Equatable, Sendable {
    case noLocation
    case directionsFailed(String)
    case noCandidateFound
}

/// Builds walking routes (MVP: mock + `MKDirections` to be wired in `RouteGenerationService`).
protocol RouteGenerationProviding {
    func generateRoute(
        goal: WalkGoal,
        preferences: UserPreferences,
        around location: CLLocationCoordinate2D
    ) async throws -> GeneratedRoute
}
