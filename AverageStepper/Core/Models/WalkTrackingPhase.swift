import Foundation

/// Fine-grained UI state while `WalkSession.status == .active`.
enum WalkTrackingPhase: String, Codable, Hashable, Sendable {
    /// Not in an active walk (`WalkSession.status != .active`).
    case inactive
    /// GPS lock not yet good enough to start distance accumulation.
    case waitingForGPS
    /// Actively accumulating distance and checking route adherence.
    case tracking
    /// User paused; timer and distance accumulation stopped.
    case paused
}

/// How closely the user's position matches the planned polyline (MVP heuristic).
enum RouteAdherenceStatus: String, Codable, Hashable, Sendable {
    case unknown
    case onRoute
    case slightlyOffRoute
    case offRoute
    case routeComplete
}
