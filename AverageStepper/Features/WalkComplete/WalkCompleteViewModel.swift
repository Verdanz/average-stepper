import Foundation
import Observation

@Observable
@MainActor
final class WalkCompleteViewModel {
    let session: WalkSession
    let newAchievements: [Achievement]

    init(session: WalkSession, dependencies: AppDependencies) {
        self.session = session
        let engine = dependencies.achievementEngine
        let history = dependencies.walkHistory
        let beforeHistory = Array(history.dropLast())
        let before = engine.achievements(from: beforeHistory)
        let after = engine.achievements(from: history)
        self.newAchievements = engine.newlyUnlocked(from: before, to: after)
    }
}
