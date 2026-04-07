import Foundation

/// Lightweight daily continuity helper (local calendar, no server).
enum StreakDailyCheck {
    /// Optional nudge when a streak is active but today has no completed walk yet (before `cutoffHour`).
    static func gentleReminder(
        completedWalks: [WalkSession],
        calendar: Calendar = .autoupdatingCurrent,
        now: Date = .now,
        cutoffHour: Int = 21
    ) -> String? {
        let walkDays = StreakManager.walkDays(from: completedWalks, calendar: calendar)
        let today = calendar.startOfDay(for: now)
        let hour = calendar.component(.hour, from: now)
        let stats = StreakManager.streakStats(completedWalks: completedWalks, calendar: calendar, now: now)

        guard stats.current >= 2 else { return nil }
        guard hour < cutoffHour else { return nil }
        guard !walkDays.contains(today) else { return nil }

        return "A short walk today keeps your \(stats.current)-day momentum going."
    }
}
