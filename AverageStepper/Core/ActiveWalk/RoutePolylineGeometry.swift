import CoreLocation
import Foundation

/// Pure geometry helpers for progress along a walk route polyline (WGS84, short segments).
enum RoutePolylineGeometry {
    /// Total path length by summing geodesic segment lengths (meters).
    static func totalLengthMeters(coordinates: [CLLocationCoordinate2D]) -> Double {
        guard coordinates.count >= 2 else { return 0 }
        var sum = 0.0
        for i in 0..<(coordinates.count - 1) {
            let a = CLLocation(latitude: coordinates[i].latitude, longitude: coordinates[i].longitude)
            let b = CLLocation(latitude: coordinates[i + 1].latitude, longitude: coordinates[i + 1].longitude)
            sum += a.distance(from: b)
        }
        return sum
    }

    /// Nearest point on the polyline to `point`, and distance from `point` to that segment (meters).
    static func nearestPointOnPolyline(
        to point: CLLocationCoordinate2D,
        coordinates: [CLLocationCoordinate2D]
    ) -> (nearest: CLLocationCoordinate2D, crossTrackDistance: Double, segmentIndex: Int, t: Double) {
        guard coordinates.count >= 2 else {
            return (point, 0, 0, 0)
        }
        let p = CLLocation(latitude: point.latitude, longitude: point.longitude)
        var bestDist = Double.greatestFiniteMagnitude
        var bestPoint = coordinates[0]
        var bestIndex = 0
        var bestT = 0.0

        for i in 0..<(coordinates.count - 1) {
            let a = coordinates[i]
            let b = coordinates[i + 1]
            let projection = project(point: point, segmentFrom: a, to: b)
            let q = projection.coordinate
            let d = p.distance(from: CLLocation(latitude: q.latitude, longitude: q.longitude))
            if d < bestDist {
                bestDist = d
                bestPoint = q
                bestIndex = i
                bestT = projection.t
            }
        }
        return (bestPoint, bestDist, bestIndex, bestT)
    }

    /// Distance along the polyline from the start to the projected point (meters).
    static func distanceAlongPolyline(
        to point: CLLocationCoordinate2D,
        coordinates: [CLLocationCoordinate2D]
    ) -> Double {
        guard coordinates.count >= 2 else { return 0 }
        let (nearest, _, segmentIndex, t) = nearestPointOnPolyline(to: point, coordinates: coordinates)
        var sum = 0.0
        for i in 0..<segmentIndex {
            let a = CLLocation(latitude: coordinates[i].latitude, longitude: coordinates[i].longitude)
            let b = CLLocation(latitude: coordinates[i + 1].latitude, longitude: coordinates[i + 1].longitude)
            sum += a.distance(from: b)
        }
        let segStart = coordinates[segmentIndex]
        let segEnd = coordinates[segmentIndex + 1]
        let partial = CLLocation(latitude: segStart.latitude, longitude: segStart.longitude)
            .distance(from: CLLocation(latitude: nearest.latitude, longitude: nearest.longitude))
        /// `t` is along segment; use actual geodesic partial for consistency.
        _ = t
        return sum + partial
    }

    /// Progress 0...1 = distanceAlong / totalLength.
    static func routeProgress01(user: CLLocationCoordinate2D, coordinates: [CLLocationCoordinate2D]) -> Double {
        let total = totalLengthMeters(coordinates: coordinates)
        guard total > 1 else { return 0 }
        let along = min(distanceAlongPolyline(to: user, coordinates: coordinates), total)
        return min(1, max(0, along / total))
    }

    // MARK: - Private

    private struct Projection {
        var coordinate: CLLocationCoordinate2D
        var t: Double
    }

    /// Project `point` onto segment AB; `t` in 0...1 along the chord in lat/lon (good enough for MVP).
    private static func project(
        point: CLLocationCoordinate2D,
        segmentFrom a: CLLocationCoordinate2D,
        to b: CLLocationCoordinate2D
    ) -> Projection {
        let ax = a.longitude, ay = a.latitude
        let bx = b.longitude, by = b.latitude
        let px = point.longitude, py = point.latitude
        let abx = bx - ax, aby = by - ay
        let apx = px - ax, apy = py - ay
        let ab2 = abx * abx + aby * aby
        guard ab2 > 1e-18 else { return Projection(coordinate: a, t: 0) }
        var t = (apx * abx + apy * aby) / ab2
        t = min(1, max(0, t))
        let nx = ax + t * abx
        let ny = ay + t * aby
        return Projection(coordinate: CLLocationCoordinate2D(latitude: ny, longitude: nx), t: t)
    }
}
