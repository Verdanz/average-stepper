import CoreLocation
import Foundation

/// A single walking leg result decoupled from `MKRoute` so tests can mock routing without MapKit.
struct SegmentRouteResult: Sendable, Equatable {
    var distanceMeters: Double
    var expectedTravelTime: TimeInterval
    var coordinates: [CLLocationCoordinate2D]

    static func == (lhs: SegmentRouteResult, rhs: SegmentRouteResult) -> Bool {
        lhs.distanceMeters == rhs.distanceMeters
            && lhs.expectedTravelTime == rhs.expectedTravelTime
            && Geodesy.coordinatesEqual(lhs.coordinates, rhs.coordinates)
    }
}
