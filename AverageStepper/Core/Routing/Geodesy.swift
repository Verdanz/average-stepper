import CoreLocation
import Foundation

/// Small, testable helpers for placing points on the WGS84 ellipsoid (MVP: spherical approximation).
enum Geodesy {
    /// Meters per degree latitude (approximate near mid-latitudes).
    static func metersPerDegreeLatitude() -> Double { 111_320 }

    /// Meters per degree longitude at a given latitude.
    static func metersPerDegreeLongitude(latitudeDegrees: Double) -> Double {
        111_320 * cos(latitudeDegrees * .pi / 180)
    }

    /// Offset from `origin` using local east/north offsets in meters (small distances).
    static func coordinate(from origin: CLLocationCoordinate2D, eastMeters: Double, northMeters: Double) -> CLLocationCoordinate2D {
        let lat = origin.latitude + northMeters / metersPerDegreeLatitude()
        let lon = origin.longitude + eastMeters / max(1, metersPerDegreeLongitude(latitudeDegrees: origin.latitude))
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    /// Great-circle distance in meters (sufficient for scoring closure and segment sanity checks).
    static func distanceMeters(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
        let locA = CLLocation(latitude: a.latitude, longitude: a.longitude)
        let locB = CLLocation(latitude: b.latitude, longitude: b.longitude)
        return locA.distance(from: locB)
    }

    /// Used by routing DTO `Equatable` — `CLLocationCoordinate2D` synthesis can fail under strict concurrency.
    static func coordinatesEqual(_ a: [CLLocationCoordinate2D], _ b: [CLLocationCoordinate2D]) -> Bool {
        guard a.count == b.count else { return false }
        for i in 0..<a.count {
            if a[i].latitude != b[i].latitude || a[i].longitude != b[i].longitude { return false }
        }
        return true
    }
}
