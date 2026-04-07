import Foundation

/// Snapshot of completed-walk history, aggregates, and streaks used to evaluate `BadgeRule` predicates.
struct GamificationContext: Sendable {
    var completedWalksSorted: [WalkSession]
    var totals: GamificationTotals
    var streaks: StreakManager.StreakStats
    var calendar: Calendar
    var now: Date

    static func make(
        history: [WalkSession],
        calendar: Calendar = .autoupdatingCurrent,
        now: Date = .now
    ) -> GamificationContext {
        let completed = history.filter { $0.status == .completed }
        let sorted = completed.sorted {
            let a = $0.endedAt ?? $0.startedAt
            let b = $1.endedAt ?? $1.startedAt
            return a < b
        }
        let totals = GamificationTotals.from(completedWalks: completed)
        let walkDays = StreakManager.walkDays(from: completed, calendar: calendar)
        let streaks = StreakManager.streakStats(walkDays: walkDays, calendar: calendar, now: now)
        return GamificationContext(
            completedWalksSorted: sorted,
            totals: totals,
            streaks: streaks,
            calendar: calendar,
            now: now
        )
    }
}

/// Evaluates catalog rules for unlock dates and locked-state progress (0...1).
enum AchievementRuleEvaluator {
    static func unlockDate(definition: BadgeDefinition, context: GamificationContext) -> Date? {
        switch definition.rule {
        case .totalWalksCompleted(let n):
            let sorted = context.completedWalksSorted
            guard sorted.count >= n else { return nil }
            let w = sorted[n - 1]
            return w.endedAt ?? w.startedAt

        case .firstWalkReachingSteps(let minSteps):
            return context.completedWalksSorted.first(where: { $0.liveSteps >= minSteps }).flatMap { $0.endedAt ?? $0.startedAt }

        case .currentStreakDays(let n):
            guard context.streaks.current >= n else { return nil }
            return context.completedWalksSorted.last.flatMap { $0.endedAt ?? $0.startedAt }

        case .longestStreakDays(let n):
            guard context.streaks.longest >= n else { return nil }
            return context.completedWalksSorted.last.flatMap { $0.endedAt ?? $0.startedAt }

        case .routeCompletedOnce:
            return context.completedWalksSorted.first(where: { $0.completionReason == .routeCompleted }).flatMap { $0.endedAt ?? $0.startedAt }

        case .lifetimeSteps(let minTotal):
            return dateWhenLifetimeStepsReached(sorted: context.completedWalksSorted, threshold: minTotal)

        case .firstWalkStartingInHourRange(let startHour, let endHour):
            return context.completedWalksSorted.first(where: { w in
                let h = context.calendar.component(.hour, from: w.startedAt)
                return h >= startHour && h < endHour
            }).flatMap { $0.endedAt ?? $0.startedAt }

        case .firstWalkEndingInHourRange(let startHour, let endHour):
            return context.completedWalksSorted.first(where: { w in
                let t = w.endedAt ?? w.startedAt
                let h = context.calendar.component(.hour, from: t)
                return h >= startHour && h < endHour
            }).flatMap { $0.endedAt ?? $0.startedAt }
        }
    }

    /// Progress toward unlock while locked. Ignored once unlocked.
    static func progressFraction(definition: BadgeDefinition, context: GamificationContext) -> Double {
        if unlockDate(definition: definition, context: context) != nil { return 1 }

        switch definition.rule {
        case .totalWalksCompleted(let n):
            guard n > 0 else { return 1 }
            return min(1, Double(context.totals.totalCompletedWalks) / Double(n))

        case .firstWalkReachingSteps(let minSteps):
            guard minSteps > 0 else { return 1 }
            let best = context.completedWalksSorted.map(\.liveSteps).max() ?? 0
            return min(1, Double(best) / Double(minSteps))

        case .currentStreakDays(let n):
            guard n > 0 else { return 1 }
            return min(1, Double(context.streaks.current) / Double(n))

        case .longestStreakDays(let n):
            guard n > 0 else { return 1 }
            return min(1, Double(context.streaks.longest) / Double(n))

        case .routeCompletedOnce:
            return context.completedWalksSorted.contains(where: { $0.completionReason == .routeCompleted }) ? 1 : 0

        case .lifetimeSteps(let minTotal):
            guard minTotal > 0 else { return 1 }
            return min(1, Double(context.totals.totalEstimatedSteps) / Double(minTotal))

        case .firstWalkStartingInHourRange(let startHour, let endHour):
            return context.completedWalksSorted.contains(where: { w in
                let h = context.calendar.component(.hour, from: w.startedAt)
                return h >= startHour && h < endHour
            }) ? 1 : 0

        case .firstWalkEndingInHourRange(let startHour, let endHour):
            return context.completedWalksSorted.contains(where: { w in
                let t = w.endedAt ?? w.startedAt
                let h = context.calendar.component(.hour, from: t)
                return h >= startHour && h < endHour
            }) ? 1 : 0
        }
    }

    private static func dateWhenLifetimeStepsReached(sorted: [WalkSession], threshold: Int) -> Date? {
        guard threshold > 0 else { return sorted.last.flatMap { $0.endedAt ?? $0.startedAt } }
        var sum = 0
        for w in sorted {
            sum += w.liveSteps
            if sum >= threshold {
                return w.endedAt ?? w.startedAt
            }
        }
        return nil
    }
}
