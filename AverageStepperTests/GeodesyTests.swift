import CoreLocation
import XCTest
@testable import AverageStepper

final class GeodesyTests: XCTestCase {
    func testDistanceSamePointIsZero() {
        let c = CLLocationCoordinate2D(latitude: 37.33, longitude: -122.01)
        XCTAssertEqual(Geodesy.distanceMeters(c, c), 0, accuracy: 0.001)
    }

    func testDistanceShortOffsetIsPositive() {
        let a = CLLocationCoordinate2D(latitude: 37.33, longitude: -122.01)
        let b = CLLocationCoordinate2D(latitude: 37.331, longitude: -122.01)
        let d = Geodesy.distanceMeters(a, b)
        XCTAssertGreaterThan(d, 80)
        XCTAssertLessThan(d, 200)
    }

    func testMetersPerDegreeLongitudeDecreasesTowardPoles() {
        let equator = Geodesy.metersPerDegreeLongitude(latitudeDegrees: 0)
        let mid = Geodesy.metersPerDegreeLongitude(latitudeDegrees: 45)
        let high = Geodesy.metersPerDegreeLongitude(latitudeDegrees: 60)
        XCTAssertGreaterThan(equator, mid)
        XCTAssertGreaterThan(mid, high)
    }

    func testCoordinatesEqualDetectsMismatch() {
        let a: [CLLocationCoordinate2D] = [
            .init(latitude: 1, longitude: 2),
            .init(latitude: 3, longitude: 4)
        ]
        let b: [CLLocationCoordinate2D] = [
            .init(latitude: 1, longitude: 2),
            .init(latitude: 3, longitude: 5)
        ]
        XCTAssertTrue(Geodesy.coordinatesEqual(a, a))
        XCTAssertFalse(Geodesy.coordinatesEqual(a, b))
    }
}
