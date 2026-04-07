import Foundation

/// Static surface for badge rule evaluation — `AchievementRuleEvaluator` is the default implementation.
/// Tests can depend on this protocol if you introduce a thin wrapper type later; the enum conforms directly today.
protocol AchievementRuleEvaluating {
    static func unlockDate(definition: BadgeDefinition, context: GamificationContext) -> Date?
    static func progressFraction(definition: BadgeDefinition, context: GamificationContext) -> Double
}

extension AchievementRuleEvaluator: AchievementRuleEvaluating {}
