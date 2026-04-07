import Foundation
import Observation

@Observable
@MainActor
final class AchievementsViewModel {
    private(set) var achievements: [Achievement] = []
    private(set) var totals: GamificationTotals = GamificationTotals(
        totalCompletedWalks: 0,
        totalEstimatedSteps: 0,
        totalDistanceMeters: 0
    )
    private(set) var streaks: StreakManager.StreakStats = StreakManager.StreakStats(current: 0, longest: 0)
    private(set) var streakNudge: String?

    func reload(using dependencies: AppDependencies) {
        let history = dependencies.walkHistory
        let completed = history.filter { $0.status == .completed }
        let cal = Calendar.autoupdatingCurrent
        let now = Date()
        totals = GamificationTotals.from(completedWalks: completed)
        streaks = StreakManager.streakStats(completedWalks: completed, calendar: cal, now: now)
        streakNudge = StreakDailyCheck.gentleReminder(completedWalks: completed, calendar: cal, now: now)
        achievements = dependencies.achievementEngine.achievements(from: history, asOf: now)
    }
}
