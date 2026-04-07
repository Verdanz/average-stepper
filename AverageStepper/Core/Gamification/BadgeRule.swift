import Foundation

/// Expandable rule vocabulary — add cases here and handle them in `AchievementRuleEvaluator`.
enum BadgeRule: Equatable, Sendable {
    /// Total completed walks in app history (lifetime).
    case totalWalksCompleted(atLeast: Int)
    /// First completed walk whose estimated steps meet the threshold.
    case firstWalkReachingSteps(atLeast: Int)
    /// Current walking-day streak (calendar days).
    case currentStreakDays(atLeast: Int)
    /// Longest ever calendar-day streak.
    case longestStreakDays(atLeast: Int)
    /// Completed a route (polyline completion) at least once.
    case routeCompletedOnce
    /// Total lifetime estimated steps across completed walks.
    case lifetimeSteps(atLeast: Int)
    /// First walk with `startedAt` hour in `[startHour, endHour)` (local).
    case firstWalkStartingInHourRange(startHour: Int, endHour: Int)
    /// First walk with end time hour in `[startHour, endHour)` (local).
    case firstWalkEndingInHourRange(startHour: Int, endHour: Int)
}
