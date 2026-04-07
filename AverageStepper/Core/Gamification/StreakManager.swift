import Foundation

/// Calendar-day streaks from completed walks (local timezone).
enum StreakManager {
    struct StreakStats: Equatable, Sendable {
        /// Consecutive days with ≥1 completed walk, anchored to today or yesterday.
        var current: Int
        /// Best consecutive run of calendar days (all time).
        var longest: Int
    }

    /// Start-of-day dates (normalized) for each day that had at least one completed walk.
    static func walkDays(from completedWalks: [WalkSession], calendar: Calendar) -> Set<Date> {
        let completed = completedWalks.filter { $0.status == .completed }
        var days = Set<Date>()
        for w in completed {
            let ref = w.endedAt ?? w.startedAt
            days.insert(calendar.startOfDay(for: ref))
        }
        return days
    }

    /// Daily streak continuity: requires a walk **today** or **yesterday** to count as active.
    static func streakStats(walkDays: Set<Date>, calendar: Calendar, now: Date) -> StreakStats {
        let today = calendar.startOfDay(for: now)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
            return StreakStats(current: 0, longest: longestConsecutiveDays(in: walkDays, calendar: calendar))
        }

        let activeAnchor = walkDays.contains(today) ? today : (walkDays.contains(yesterday) ? yesterday : nil)
        let current: Int
        if let anchor = activeAnchor {
            current = consecutiveDaysCount(endingAt: anchor, walkDays: walkDays, calendar: calendar)
        } else {
            current = 0
        }

        let longest = longestConsecutiveDays(in: walkDays, calendar: calendar)
        return StreakStats(current: current, longest: longest)
    }

    /// Convenience: completed walks → stats.
    static func streakStats(completedWalks: [WalkSession], calendar: Calendar, now: Date) -> StreakStats {
        let days = walkDays(from: completedWalks, calendar: calendar)
        return streakStats(walkDays: days, calendar: calendar, now: now)
    }

    // MARK: - Private

    private static func consecutiveDaysCount(endingAt end: Date, walkDays: Set<Date>, calendar: Calendar) -> Int {
        var count = 0
        var cursor = end
        while walkDays.contains(cursor) {
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = calendar.startOfDay(for: prev)
        }
        return count
    }

    private static func longestConsecutiveDays(in walkDays: Set<Date>, calendar: Calendar) -> Int {
        guard !walkDays.isEmpty else { return 0 }
        let sorted = walkDays.sorted()
        var best = 1
        var run = 1
        for i in 1..<sorted.count {
            let prev = sorted[i - 1]
            let cur = sorted[i]
            let diff = calendar.dateComponents([.day], from: prev, to: cur).day ?? 0
            if diff == 1 {
                run += 1
                best = max(best, run)
            } else {
                run = 1
            }
        }
        return best
    }
}
