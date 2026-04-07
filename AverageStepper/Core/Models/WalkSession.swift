import Foundation

/// High-level lifecycle for a walk record (persisted with `WalkSession`).
enum WalkSessionStatus: String, Codable, Hashable, Sendable {
    case idle
    case active
    case completed
    case cancelled
}

enum WalkCompletionReason: String, Codable, Hashable, Sendable {
    case reachedStepGoal
    /// Walked far enough along the planned polyline (see `ActiveWalkConfig`).
    case routeCompleted
    case userEnded
    case aborted
}

/// Single walk record: goal, live metrics while active, and completion metadata for history and gamification.
/// Owned by `WalkSessionManager` during an active walk; completed rows feed `GamificationContext` and streak logic.
struct WalkSession: Identifiable, Equatable, Hashable, Codable, Sendable {
    var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var goal: WalkGoal
    var plannedRouteId: UUID?
    var selectedRouteOptionId: UUID?
    var status: WalkSessionStatus
    /// Sub-state while `status == .active` (ignored once completed).
    var trackingPhase: WalkTrackingPhase
    var liveSteps: Int
    var liveDistanceMeters: Double
    /// 0...1 progress along the selected route polyline length.
    var routeProgress01: Double
    /// Elapsed time while not paused (updated by `WalkSessionManager`).
    var elapsedActiveTime: TimeInterval
    /// Sum of completed pause intervals.
    var accumulatedPausedTime: TimeInterval
    var adherenceStatus: RouteAdherenceStatus
    var completionReason: WalkCompletionReason?
    /// User-facing error when tracking cannot continue (e.g. permission).
    var lastErrorMessage: String?

    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        goal: WalkGoal,
        plannedRouteId: UUID? = nil,
        selectedRouteOptionId: UUID? = nil,
        status: WalkSessionStatus = .idle,
        trackingPhase: WalkTrackingPhase = .inactive,
        liveSteps: Int = 0,
        liveDistanceMeters: Double = 0,
        routeProgress01: Double = 0,
        elapsedActiveTime: TimeInterval = 0,
        accumulatedPausedTime: TimeInterval = 0,
        adherenceStatus: RouteAdherenceStatus = .unknown,
        completionReason: WalkCompletionReason? = nil,
        lastErrorMessage: String? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.goal = goal
        self.plannedRouteId = plannedRouteId
        self.selectedRouteOptionId = selectedRouteOptionId
        self.status = status
        self.trackingPhase = trackingPhase
        self.liveSteps = liveSteps
        self.liveDistanceMeters = liveDistanceMeters
        self.routeProgress01 = routeProgress01
        self.elapsedActiveTime = elapsedActiveTime
        self.accumulatedPausedTime = accumulatedPausedTime
        self.adherenceStatus = adherenceStatus
        self.completionReason = completionReason
        self.lastErrorMessage = lastErrorMessage
    }
}
