import CoreLocation
import Foundation

/// UI helpers for the active walk screen (reads from `WalkSessionManager` + preferences).
/// Not `@Observable`: the view observes `WalkSessionManager` via `@Bindable` so live metrics update.
@MainActor
final class ActiveWalkViewModel {
    private let walkSessionManager: WalkSessionManager
    private let preferences: UserPreferences

    init(walkSessionManager: WalkSessionManager, preferences: UserPreferences) {
        self.walkSessionManager = walkSessionManager
        self.preferences = preferences
    }

    var lastUserCoordinate: CLLocationCoordinate2D? { walkSessionManager.lastKnownUserCoordinate }
    var routePolylineLengthMeters: Double { walkSessionManager.routePolylineLengthMeters }

    /// Step goal progress 0...1.
    func stepProgress01(for session: WalkSession) -> Double {
        let target = session.goal.targetSteps
        guard target > 0 else { return 0 }
        return min(1, Double(session.liveSteps) / Double(target))
    }

    /// Remaining distance along the planned polyline (heuristic).
    func estimatedRemainingRouteMeters(for session: WalkSession) -> Double {
        let len = routePolylineLengthMeters
        guard len > 0 else { return 0 }
        return max(0, len * (1 - session.routeProgress01))
    }

    /// Rough ETA from remaining distance and preferred walking speed.
    func estimatedRemainingWalkTime(for session: WalkSession) -> TimeInterval {
        let speed = max(preferences.walkingSpeedMetersPerSecond, 0.5)
        return estimatedRemainingRouteMeters(for: session) / speed
    }

    func elapsedTimeText(for session: WalkSession) -> String {
        Formatting.elapsedClock(session.elapsedActiveTime)
    }

    func primaryStatusLine(for session: WalkSession) -> String {
        guard session.status == .active else { return "" }
        switch session.trackingPhase {
        case .inactive:
            return ""
        case .waitingForGPS:
            return "Waiting for GPS…"
        case .paused:
            return "Paused"
        case .tracking:
            return adherenceTitle(session.adherenceStatus)
        }
    }

    func secondaryHintLine(for session: WalkSession) -> String? {
        if let msg = session.lastErrorMessage, !msg.isEmpty {
            return msg
        }
        if session.trackingPhase == .waitingForGPS {
            return "Stay outdoors if you can — first fix can take a few seconds."
        }
        return nil
    }

    var locationDenied: Bool {
        walkSessionManager.locationAuthorizationState == .denied
    }

    func pause() {
        walkSessionManager.pause()
    }

    func resume() {
        walkSessionManager.resume()
    }

    func endWalkMetGoal() {
        walkSessionManager.complete(reason: .reachedStepGoal)
    }

    func endWalkEarly() {
        walkSessionManager.complete(reason: .userEnded)
    }

    func simulateAdvance() {
        walkSessionManager.simulateAdvancePosition()
    }

    private func adherenceTitle(_ status: RouteAdherenceStatus) -> String {
        switch status {
        case .unknown:
            return "Locating you on the route…"
        case .onRoute:
            return "On route"
        case .slightlyOffRoute:
            return "Slightly off route"
        case .offRoute:
            return "Off route — head back toward the line when you can"
        case .routeComplete:
            return "Route complete"
        }
    }
}
