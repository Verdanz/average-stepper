import Foundation
import Observation

@Observable
@MainActor
final class AchievementsViewModel {
    private(set) var achievements: [Achievement] = []

    func reload(using dependencies: AppDependencies) {
        achievements = dependencies.achievementEngine.achievements(from: dependencies.walkHistory)
    }
}
