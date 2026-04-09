import CoreLocation
import Foundation
@testable import AverageStepper

/// Test double for `LocationProviding` — emit synthetic fixes on the main actor.
@MainActor
final class MockLocationService: LocationProviding {
    var authorizationState: LocationAuthorizationState = .authorizedWhenInUse
    var latestLocation: CLLocation?
    private(set) var stopUpdatingLocationCallCount = 0
    private(set) var startUpdatingLocationCallCount = 0
    private var locationHandler: (@MainActor (CLLocation) -> Void)?

    func requestWhenInUseAuthorization() {}

    func startUpdatingLocation() {
        startUpdatingLocationCallCount += 1
    }

    func stopUpdatingLocation() {
        stopUpdatingLocationCallCount += 1
    }

    func setLocationUpdateHandler(_ handler: (@MainActor (CLLocation) -> Void)?) {
        locationHandler = handler
    }

    @MainActor
    func emit(_ location: CLLocation) {
        latestLocation = location
        locationHandler?(location)
    }
}
