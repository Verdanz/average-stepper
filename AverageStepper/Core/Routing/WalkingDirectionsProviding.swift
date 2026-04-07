import CoreLocation
import Foundation

/// Abstraction over `MKDirections` walking requests for testability.
protocol WalkingDirectionsProviding: Sendable {
    func walkingRoute(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D
    ) async throws -> SegmentRouteResult
}
