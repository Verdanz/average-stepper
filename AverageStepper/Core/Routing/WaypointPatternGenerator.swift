import CoreLocation
import Foundation

/// Produces ordered waypoint lists **beginning at the user's start coordinate**.
/// These are *geometric* patterns; MapKit directions will snap them to walkable paths.
enum WaypointPatternGenerator {
    /// Regular polygon-ish loop: start at center, visit `sides` rim points, return to start.
    /// - Parameters:
    ///   - start: User location (also treated as loop center for waypoint placement).
    ///   - targetPerimeterMeters: Desired approximate walking distance along the loop.
    ///   - sides: Number of rim vertices (not counting returns).
    ///   - rotationRadians: Rotates the polygon around the center to diversify candidates.
    static func loopPolygon(
        start: CLLocationCoordinate2D,
        targetPerimeterMeters: Double,
        sides: Int,
        rotationRadians: Double
    ) -> [CLLocationCoordinate2D] {
        let n = max(3, sides)
        // Perimeter ~ 2πr for a smooth circle; inscribed polygon perimeter is smaller — inflate radius slightly.
        let perimeter = max(targetPerimeterMeters, 200)
        let baseRadius = perimeter / (2 * .pi) * 1.12

        var points: [CLLocationCoordinate2D] = [start]

        for i in 0..<n {
            let theta = rotationRadians + (2 * .pi * Double(i) / Double(n))
            let north = baseRadius * cos(theta)
            let east = baseRadius * sin(theta)
            points.append(Geodesy.coordinate(from: start, eastMeters: east, northMeters: north))
        }

        points.append(start)
        return points
    }

    /// Near-loop: same as loop but the final approach stops slightly short, then adds a short closing hop.
    /// This sometimes yields nicer walking graphs than perfect loops in dense street grids.
    static func nearLoop(
        start: CLLocationCoordinate2D,
        targetPerimeterMeters: Double,
        sides: Int,
        rotationRadians: Double,
        shortfallMeters: Double
    ) -> [CLLocationCoordinate2D] {
        let loop = loopPolygon(start: start, targetPerimeterMeters: targetPerimeterMeters, sides: sides, rotationRadians: rotationRadians)
        guard loop.count >= 3 else { return loop }
        // Replace the last leg to `start` with a point near start, then walk in.
        var trimmed = Array(loop.dropLast())
        let near = Geodesy.coordinate(from: start, eastMeters: shortfallMeters, northMeters: -shortfallMeters * 0.4)
        trimmed.append(near)
        trimmed.append(start)
        return trimmed
    }

    /// Out-and-back: start → turnaround → start (two routed legs).
    static func outAndBack(
        start: CLLocationCoordinate2D,
        totalDistanceMeters: Double,
        bearingDegreesFromNorth: Double
    ) -> [CLLocationCoordinate2D] {
        let half = max(totalDistanceMeters * 0.5, 150)
        let bearing = bearingDegreesFromNorth * .pi / 180
        let north = half * cos(bearing)
        let east = half * sin(bearing)
        let turn = Geodesy.coordinate(from: start, eastMeters: east, northMeters: north)
        return [start, turn, start]
    }
}
