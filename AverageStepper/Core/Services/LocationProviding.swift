import CoreLocation
import Foundation

enum LocationAuthorizationState: Sendable {
    case notDetermined
    case denied
    case authorizedWhenInUse
    case authorizedAlways
}

/// Abstraction over `CLLocationManager` for testability and future background modes.
/// Isolated to the main actor to match `CLLocationManager` usage and `WalkSessionManager`.
@MainActor
protocol LocationProviding: AnyObject {
    var authorizationState: LocationAuthorizationState { get }
    var latestLocation: CLLocation? { get }

    func requestWhenInUseAuthorization()
    func startUpdatingLocation()
    func stopUpdatingLocation()

    /// Called on the main queue for each location update (may be noisy — filter in consumer).
    func setLocationUpdateHandler(_ handler: (@MainActor (CLLocation) -> Void)?)
}
