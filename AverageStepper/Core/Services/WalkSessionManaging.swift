import Foundation

/// Coordinates active walk lifecycle, location-driven metrics, and persistence.
@MainActor
protocol WalkSessionManaging: AnyObject {
    var session: WalkSession { get }
    var activeRoute: GeneratedRoute? { get }
    var selectedRouteOption: RouteOption? { get }
    /// True once after relaunch if an active walk was restored from disk — show resume UI.
    var needsResumeWalkPresentation: Bool { get }

    func acknowledgeResumePresentation()

    func begin(route: GeneratedRoute, selectedOption: RouteOption, goal: WalkGoal, preferences: UserPreferences)
    func pause()
    func resume()
    func complete(reason: WalkCompletionReason)
    func cancel()
    func resetIdle()

    /// Advances a fake position along the route for Simulator / debug (no-op if disabled).
    func simulateAdvancePosition()
}
