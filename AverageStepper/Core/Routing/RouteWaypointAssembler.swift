import CoreLocation
import Foundation

/// Result of stitching MapKit walking legs between ordered waypoints.
struct AssembledWalkRoute: Sendable, Equatable {
    var distanceMeters: Double
    var estimatedDuration: TimeInterval
    var coordinates: [CLLocationCoordinate2D]
    var segmentCount: Int
}

/// Chains `start → … → end` legs using walking directions.
enum RouteWaypointAssembler {
    /// Walks the polyline in order, requesting a separate walking route for each leg.
    static func assemble(
        waypoints: [CLLocationCoordinate2D],
        directions: WalkingDirectionsProviding
    ) async throws -> AssembledWalkRoute {
        guard waypoints.count >= 2 else {
            throw RouteGenerationError.directionsFailed("Need at least two waypoints.")
        }

        var totalDistance = 0.0
        var totalDuration = 0.0
        var merged: [CLLocationCoordinate2D] = []

        for i in 0..<(waypoints.count - 1) {
            let from = waypoints[i]
            let to = waypoints[i + 1]
            let segment = try await directions.walkingRoute(from: from, to: to)
            totalDistance += segment.distanceMeters
            totalDuration += segment.expectedTravelTime

            if merged.isEmpty {
                merged.append(contentsOf: segment.coordinates)
            } else {
                // Drop duplicated joint point when present.
                if let first = segment.coordinates.first, let last = merged.last, isClose(first, last) {
                    merged.append(contentsOf: segment.coordinates.dropFirst())
                } else {
                    merged.append(contentsOf: segment.coordinates)
                }
            }
        }

        let legs = waypoints.count - 1
        return AssembledWalkRoute(
            distanceMeters: totalDistance,
            estimatedDuration: totalDuration,
            coordinates: merged,
            segmentCount: legs
        )
    }

    static func isClose(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Bool {
        abs(a.latitude - b.latitude) < 1e-5 && abs(a.longitude - b.longitude) < 1e-5
    }
}
