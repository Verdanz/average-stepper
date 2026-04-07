import CoreLocation
import Foundation

/// A single walking leg result decoupled from `MKRoute` so tests can mock routing without MapKit.
struct SegmentRouteResult: Sendable, Equatable {
    var distanceMeters: Double
    var expectedTravelTime: TimeInterval
    var coordinates: [CLLocationCoordinate2D]
}
