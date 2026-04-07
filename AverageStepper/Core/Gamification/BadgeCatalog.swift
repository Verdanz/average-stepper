import Foundation

/// Static badge definitions (titles + rules). Add rows here to grow the system.
enum BadgeCatalog {
    struct Definition: Equatable, Sendable {
        var id: String
        var badge: Badge
        var rule: BadgeRule
    }

    static let all: [Definition] = [
        Definition(
            id: "first_steps",
            badge: Badge(
                id: "first_steps",
                title: "First Steps",
                detail: "Complete your first walk.",
                systemImageName: "figure.walk"
            ),
            rule: .totalWalksCompleted(atLeast: 1)
        ),
        Definition(
            id: "walks_5",
            badge: Badge(
                id: "walks_5",
                title: "Momentum",
                detail: "Finish 5 walks.",
                systemImageName: "5.circle"
            ),
            rule: .totalWalksCompleted(atLeast: 5)
        ),
        Definition(
            id: "walks_10",
            badge: Badge(
                id: "walks_10",
                title: "Rhythm",
                detail: "Finish 10 walks.",
                systemImageName: "10.circle"
            ),
            rule: .totalWalksCompleted(atLeast: 10)
        ),
        Definition(
            id: "walks_25",
            badge: Badge(
                id: "walks_25",
                title: "Committed",
                detail: "Finish 25 walks.",
                systemImageName: "sparkles"
            ),
            rule: .totalWalksCompleted(atLeast: 25)
        ),
        Definition(
            id: "steps_3k",
            badge: Badge(
                id: "steps_3k",
                title: "3K Session",
                detail: "Complete a walk with 3,000+ estimated steps.",
                systemImageName: "arrow.up.circle"
            ),
            rule: .firstWalkReachingSteps(atLeast: 3000)
        ),
        Definition(
            id: "steps_5k",
            badge: Badge(
                id: "steps_5k",
                title: "5K Session",
                detail: "Complete a walk with 5,000+ estimated steps.",
                systemImageName: "5.circle.fill"
            ),
            rule: .firstWalkReachingSteps(atLeast: 5000)
        ),
        Definition(
            id: "steps_10k",
            badge: Badge(
                id: "steps_10k",
                title: "10K Club",
                detail: "Complete a walk with 10,000+ estimated steps.",
                systemImageName: "10.circle.fill"
            ),
            rule: .firstWalkReachingSteps(atLeast: 10_000)
        ),
        Definition(
            id: "streak_3",
            badge: Badge(
                id: "streak_3",
                title: "3-Day Streak",
                detail: "Walk on 3 consecutive days.",
                systemImageName: "flame"
            ),
            rule: .currentStreakDays(atLeast: 3)
        ),
        Definition(
            id: "streak_7",
            badge: Badge(
                id: "streak_7",
                title: "7-Day Streak",
                detail: "Walk on 7 consecutive days.",
                systemImageName: "flame.fill"
            ),
            rule: .currentStreakDays(atLeast: 7)
        ),
        Definition(
            id: "explorer",
            badge: Badge(
                id: "explorer",
                title: "Explorer",
                detail: "Complete a planned route end-to-end.",
                systemImageName: "map"
            ),
            rule: .routeCompletedOnce
        ),
        Definition(
            id: "consistency",
            badge: Badge(
                id: "consistency",
                title: "Consistency",
                detail: "Reach a 10-day walking streak.",
                systemImageName: "calendar"
            ),
            rule: .longestStreakDays(atLeast: 10)
        ),
        Definition(
            id: "lifetime_100k_steps",
            badge: Badge(
                id: "lifetime_100k_steps",
                title: "Century Stride",
                detail: "Accumulate 100,000 estimated steps from completed walks.",
                systemImageName: "figure.walk.motion"
            ),
            rule: .lifetimeSteps(atLeast: 100_000)
        ),
        Definition(
            id: "early_bird",
            badge: Badge(
                id: "early_bird",
                title: "Early Bird",
                detail: "Start a walk before 10 a.m.",
                systemImageName: "sun.horizon.fill"
            ),
            rule: .firstWalkStartingInHourRange(startHour: 5, endHour: 10)
        ),
        Definition(
            id: "sunset",
            badge: Badge(
                id: "sunset",
                title: "Golden Hour",
                detail: "Finish a walk between 5 and 8 p.m.",
                systemImageName: "sunset.fill"
            ),
            rule: .firstWalkEndingInHourRange(startHour: 17, endHour: 20)
        )
    ]
}
