import CoreLocation
import Foundation

/// Weights for additive penalty terms. **Lower total score is better.**
struct RouteScoreWeights: Sendable, Equatable {
    /// Penalize relative distance mismatch: |actual - target| / target.
    var distanceMismatch: Double
    /// Penalize ending far from the start (closure distance / target).
    var closure: Double
    /// Penalize extra routing legs (complexity proxy).
    var segmentCount: Double
    /// Penalize sharp cumulative bearing changes along the polyline.
    var turning: Double
    /// Penalize ETA far from a neutral expected duration (usually target / walking speed).
    var timeDeviation: Double

    static let `default` = RouteScoreWeights(
        distanceMismatch: 2.2,
        closure: 1.4,
        segmentCount: 0.08,
        turning: 0.006,
        timeDeviation: 0.35
    )
}

/// Inputs derived from an assembled route (pure data for testing).
struct RouteScoreInputs: Equatable, Sendable {
    var targetDistanceMeters: Double
    var actualDistanceMeters: Double
    var closureDistanceMeters: Double
    var segmentCount: Int
    var estimatedDuration: TimeInterval
    var expectedDuration: TimeInterval
    var coordinates: [CLLocationCoordinate2D]
}

/// Stateless scoring used by the generation pipeline and unit tests.
enum RouteScorer {
    /// Computes a single scalar score (lower is better).
    static func score(inputs: RouteScoreInputs, weights: RouteScoreWeights) -> Double {
        let target = max(inputs.targetDistanceMeters, 1)
        let distanceMismatch = abs(inputs.actualDistanceMeters - inputs.targetDistanceMeters) / target

        let closureRatio = inputs.closureDistanceMeters / max(inputs.targetDistanceMeters * 0.05, 35)
        let closureTerm = min(closureRatio, 6) // cap extreme outliers

        let segmentTerm = Double(max(0, inputs.segmentCount - 1))

        let turnMetric = bearingChangeMetric(degrees: inputs.coordinates)
        let timeDev = abs(inputs.estimatedDuration - inputs.expectedDuration) / max(inputs.expectedDuration, 1)

        return weights.distanceMismatch * distanceMismatch
            + weights.closure * closureTerm
            + weights.segmentCount * segmentTerm
            + weights.turning * turnMetric
            + weights.timeDeviation * timeDev
    }

    /// Simplified polyline turning metric: sum of absolute bearing deltas between consecutive edges (degrees).
    static func bearingChangeMetric(degrees coordinates: [CLLocationCoordinate2D]) -> Double {
        guard coordinates.count >= 3 else { return 0 }
        var bearings: [Double] = []
        bearings.reserveCapacity(coordinates.count - 1)
        for i in 0..<(coordinates.count - 1) {
            bearings.append(bearing(from: coordinates[i], to: coordinates[i + 1]))
        }
        var total = 0.0
        for i in 0..<(bearings.count - 1) {
            var delta = abs(bearings[i + 1] - bearings[i])
            if delta > 180 { delta = 360 - delta }
            total += delta
        }
        return total
    }

    /// Initial bearing from `from` to `to` in degrees [0, 360).
    static func bearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let dLon = (to.longitude - from.longitude) * .pi / 180
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let br = atan2(y, x) * 180 / .pi
        let normalized = fmod(br + 360, 360)
        return normalized
    }

    /// Dedupe fingerprint: buckets distances/coords so near-identical candidates collapse.
    static func fingerprint(distanceMeters: Double, coordinates: [CLLocationCoordinate2D]) -> String {
        let d = Int(distanceMeters.rounded())
        guard let first = coordinates.first, let last = coordinates.last else {
            return "\(d)-empty"
        }
        let fLat = String(format: "%.4f", first.latitude)
        let fLon = String(format: "%.4f", first.longitude)
        let lLat = String(format: "%.4f", last.latitude)
        let lLon = String(format: "%.4f", last.longitude)
        return "\(d)-\(fLat)-\(fLon)-\(lLat)-\(lLon)-\(coordinates.count)"
    }
}
