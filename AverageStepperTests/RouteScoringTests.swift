import CoreLocation
import XCTest
@testable import AverageStepper

final class RouteScoringTests: XCTestCase {
    func testLowerScoreWhenCloserToTargetDistance() {
        let weights = RouteScoreWeights.default
        let target = 3000.0
        let coords = sampleCoordinates()
        let close = RouteScoreInputs(
            targetDistanceMeters: target,
            actualDistanceMeters: 3000,
            closureDistanceMeters: 20,
            segmentCount: 4,
            estimatedDuration: 2000,
            expectedDuration: 2000,
            coordinates: coords
        )
        let far = RouteScoreInputs(
            targetDistanceMeters: target,
            actualDistanceMeters: 5000,
            closureDistanceMeters: 20,
            segmentCount: 4,
            estimatedDuration: 2000,
            expectedDuration: 2000,
            coordinates: coords
        )
        XCTAssertLessThan(
            RouteScorer.score(inputs: close, weights: weights),
            RouteScorer.score(inputs: far, weights: weights)
        )
    }

    func testFingerprintStability() {
        let a = CLLocationCoordinate2D(latitude: 37.33, longitude: -122.01)
        let b = CLLocationCoordinate2D(latitude: 37.34, longitude: -122.02)
        let fp1 = RouteScorer.fingerprint(distanceMeters: 1200, coordinates: [a, b])
        let fp2 = RouteScorer.fingerprint(distanceMeters: 1200, coordinates: [a, b])
        XCTAssertEqual(fp1, fp2)
    }

    private func sampleCoordinates() -> [CLLocationCoordinate2D] {
        let a = CLLocationCoordinate2D(latitude: 37.33, longitude: -122.01)
        let b = CLLocationCoordinate2D(latitude: 37.331, longitude: -122.011)
        let c = CLLocationCoordinate2D(latitude: 37.332, longitude: -122.012)
        return [a, b, c, a]
    }
}
