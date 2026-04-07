import CoreLocation
import Foundation

/// Straight-line mock for unit tests (not representative of real road networks).
struct MockWalkingDirectionsService: WalkingDirectionsProviding {
    var assumedSpeedMetersPerSecond: Double

    init(assumedSpeedMetersPerSecond: Double = 1.35) {
        self.assumedSpeedMetersPerSecond = assumedSpeedMetersPerSecond
    }

    func walkingRoute(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D
    ) async throws -> SegmentRouteResult {
        let distance = Geodesy.distanceMeters(start, end)
        let duration = distance / max(assumedSpeedMetersPerSecond, 0.1)
        return SegmentRouteResult(
            distanceMeters: distance,
            expectedTravelTime: duration,
            coordinates: [start, end]
        )
    }
}
