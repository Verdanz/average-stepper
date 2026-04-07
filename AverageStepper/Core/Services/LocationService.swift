import CoreLocation
import Foundation
import Observation

/// Core Location wrapper. Forwards updates to an optional handler for `WalkSessionManager`.
@Observable
@MainActor
final class LocationService: NSObject, LocationProviding {
    private let manager: CLLocationManager

    private(set) var authorizationState: LocationAuthorizationState = .notDetermined
    private(set) var latestLocation: CLLocation?

    private var locationHandler: (@MainActor (CLLocation) -> Void)?

    override init() {
        self.manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.activityType = .fitness
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = 5
        refreshAuthorizationState()
    }

    func setLocationUpdateHandler(_ handler: (@MainActor (CLLocation) -> Void)?) {
        locationHandler = handler
    }

    func requestWhenInUseAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }

    fileprivate func refreshAuthorizationState() {
        switch manager.authorizationStatus {
        case .notDetermined:
            authorizationState = .notDetermined
        case .restricted, .denied:
            authorizationState = .denied
        case .authorizedWhenInUse:
            authorizationState = .authorizedWhenInUse
        case .authorizedAlways:
            authorizationState = .authorizedAlways
        @unknown default:
            authorizationState = .notDetermined
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.refreshAuthorizationState()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            self.latestLocation = loc
            self.locationHandler?(loc)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        _ = error
    }
}
