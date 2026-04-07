import Foundation

/// User intent before route generation: how many steps they want to target.
struct WalkGoal: Equatable, Hashable, Codable, Sendable {
    var targetSteps: Int

    init(targetSteps: Int) {
        self.targetSteps = max(0, targetSteps)
    }
}
