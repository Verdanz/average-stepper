import XCTest
@testable import AverageStepper

final class AchievementRulesTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar = cal
    }

    private func walk(
        started: Date,
        ended: Date,
        steps: Int,
        status: WalkSessionStatus = .completed,
        completion: WalkCompletionReason? = .reachedStepGoal
    ) -> WalkSession {
        WalkSession(
            startedAt: started,
            endedAt: ended,
            goal: WalkGoal(targetSteps: 5000),
            status: status,
            trackingPhase: status == .completed ? .inactive : .tracking,
            liveSteps: steps,
            liveDistanceMeters: Double(steps) * 0.7,
            routeProgress01: 0.5,
            elapsedActiveTime: 100,
            adherenceStatus: .onRoute,
            completionReason: completion
        )
    }

    func testTotalWalksUnlockDateIsNthCompletion() {
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        let w1 = walk(started: t0, ended: t0.addingTimeInterval(100), steps: 3000)
        let w2 = walk(started: t0.addingTimeInterval(200), ended: t0.addingTimeInterval(300), steps: 3200)
        let ctx = GamificationContext.make(history: [w1, w2], calendar: calendar, now: t0.addingTimeInterval(400))
        let def = BadgeCatalog.all.first { $0.id == "first_steps" }!
        let unlock = AchievementRuleEvaluator.unlockDate(definition: def, context: ctx)
        XCTAssertEqual(unlock, w1.endedAt)
    }

    func testProgressFractionForTotalWalks() {
        let ctx = GamificationContext.make(history: [], calendar: calendar, now: Date())
        let def = BadgeCatalog.all.first { $0.id == "walks_5" }!
        let p = AchievementRuleEvaluator.progressFraction(definition: def, context: ctx)
        XCTAssertEqual(p, 0, accuracy: 0.001)
        let walks = (0..<3).map { i in
            walk(
                started: Date(timeIntervalSince1970: 1_700_000_000 + Double(i * 100)),
                ended: Date(timeIntervalSince1970: 1_700_000_000 + Double(i * 100 + 50)),
                steps: 4000
            )
        }
        let ctx2 = GamificationContext.make(history: walks, calendar: calendar, now: Date())
        let p2 = AchievementRuleEvaluator.progressFraction(definition: def, context: ctx2)
        XCTAssertEqual(p2, 0.6, accuracy: 0.001)
    }

    func testRouteCompletedOnceUnlock() {
        let t = Date(timeIntervalSince1970: 1_710_000_000)
        let withRoute = walk(
            started: t,
            ended: t.addingTimeInterval(200),
            steps: 5000,
            completion: .routeCompleted
        )
        let ctx = GamificationContext.make(history: [withRoute], calendar: calendar, now: t)
        let def = BadgeCatalog.all.first { $0.id == "explorer" }!
        XCTAssertNotNil(AchievementRuleEvaluator.unlockDate(definition: def, context: ctx))
    }

    func testLifetimeStepsUnlockDate() {
        let base = Date(timeIntervalSince1970: 1_712_000_000)
        let w1 = walk(started: base, ended: base.addingTimeInterval(50), steps: 600)
        let w2 = walk(started: base.addingTimeInterval(100), ended: base.addingTimeInterval(150), steps: 500)
        let ctx = GamificationContext.make(history: [w1, w2], calendar: calendar, now: base.addingTimeInterval(200))
        let def = BadgeDefinition(
            id: "test_lifetime",
            badge: Badge(id: "t", title: "t", detail: "d", systemImageName: "star"),
            rule: .lifetimeSteps(atLeast: 1100)
        )
        let unlock = AchievementRuleEvaluator.unlockDate(definition: def, context: ctx)
        XCTAssertEqual(unlock, w2.endedAt ?? w2.startedAt)
    }

    func testFirstWalkStartingInHourRange() {
        let june10_8am = calendar.date(from: DateComponents(year: 2024, month: 6, day: 10, hour: 8, minute: 30))!
        let w = walk(started: june10_8am, ended: june10_8am.addingTimeInterval(600), steps: 4000)
        let ctx = GamificationContext.make(history: [w], calendar: calendar, now: june10_8am)
        let def = BadgeCatalog.all.first { $0.id == "early_bird" }!
        XCTAssertNotNil(AchievementRuleEvaluator.unlockDate(definition: def, context: ctx))
    }
}
