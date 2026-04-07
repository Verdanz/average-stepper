import CoreLocation
import Foundation

/// Core Location wrapper. Forwards updates to an optional handler for `WalkSessionManager`.
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

    private func refreshAuthorizationState() {
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
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        refreshAuthorizationState()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        latestLocation = loc
        DispatchQueue.main.async {
            self.locationHandler?(loc)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // GPS errors are common; consumer keeps last fix and shows degraded UI.
        _ = error
    }
}
