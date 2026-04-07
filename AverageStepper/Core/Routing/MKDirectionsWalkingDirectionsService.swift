import CoreLocation
import Foundation
import MapKit

/// Production implementation using Apple MapKit walking directions.
struct MKDirectionsWalkingDirectionsService: WalkingDirectionsProviding {
    func walkingRoute(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D
    ) async throws -> SegmentRouteResult {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
        request.transportType = .walking
        request.requestsAlternateRoutes = false

        let directions = MKDirections(request: request)
        let response = try await directions.calculate()
        guard let route = response.routes.first else {
            throw RouteGenerationError.directionsFailed("No walking route between points.")
        }

        let coords = Self.polylineCoordinates(from: route.polyline)
        return SegmentRouteResult(
            distanceMeters: route.distance,
            expectedTravelTime: route.expectedTravelTime,
            coordinates: coords
        )
    }

    static func polylineCoordinates(from polyline: MKPolyline) -> [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: polyline.pointCount)
        polyline.getCoordinates(&coords, range: NSRange(location: 0, length: polyline.pointCount))
        return coords
    }
}
