import XCTest
@testable import AverageStepper

final class StreakManagerTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar = cal
    }

    private func completedWalk(ended: Date, steps: Int = 3000) -> WalkSession {
        WalkSession(
            startedAt: ended.addingTimeInterval(-3600),
            endedAt: ended,
            goal: WalkGoal(targetSteps: 5000),
            status: .completed,
            trackingPhase: .inactive,
            liveSteps: steps,
            liveDistanceMeters: 2000,
            routeProgress01: 0.9,
            elapsedActiveTime: 1800,
            adherenceStatus: .onRoute,
            completionReason: .reachedStepGoal
        )
    }

    func testWalkDaysDedupesMultipleWalksSameDay() {
        let day = calendar.date(from: DateComponents(year: 2024, month: 6, day: 10))!
        let morning = day.addingTimeInterval(8 * 3600)
        let evening = day.addingTimeInterval(18 * 3600)
        let w1 = completedWalk(ended: morning)
        let w2 = completedWalk(ended: evening)
        let days = StreakManager.walkDays(from: [w1, w2], calendar: calendar)
        XCTAssertEqual(days.count, 1)
        XCTAssertTrue(days.contains(calendar.startOfDay(for: morning)))
    }

    func testCurrentStreakOneWhenWalkedToday() {
        let now = calendar.date(from: DateComponents(year: 2024, month: 6, day: 10, hour: 14))!
        let todayStart = calendar.startOfDay(for: now)
        let w = completedWalk(ended: todayStart.addingTimeInterval(4000))
        let stats = StreakManager.streakStats(completedWalks: [w], calendar: calendar, now: now)
        XCTAssertEqual(stats.current, 1)
        XCTAssertEqual(stats.longest, 1)
    }

    func testCurrentStreakContinuesFromYesterdayOnly() {
        let now = calendar.date(from: DateComponents(year: 2024, month: 6, day: 10, hour: 10))!
        let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))!
        let w = completedWalk(ended: yesterday.addingTimeInterval(5000))
        let stats = StreakManager.streakStats(completedWalks: [w], calendar: calendar, now: now)
        XCTAssertEqual(stats.current, 1)
    }

    func testCurrentStreakZeroWhenLastWalkTooOld() {
        let now = calendar.date(from: DateComponents(year: 2024, month: 6, day: 10, hour: 10))!
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: calendar.startOfDay(for: now))!
        let w = completedWalk(ended: threeDaysAgo.addingTimeInterval(1000))
        let stats = StreakManager.streakStats(completedWalks: [w], calendar: calendar, now: now)
        XCTAssertEqual(stats.current, 0)
        XCTAssertEqual(stats.longest, 1)
    }

    func testLongestStreakAcrossGap() {
        let d0 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let d1 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 2))!
        let d2 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 3))!
        let w0 = completedWalk(ended: d0.addingTimeInterval(100))
        let w1 = completedWalk(ended: d1.addingTimeInterval(100))
        let w2 = completedWalk(ended: d2.addingTimeInterval(100))
        let stats = StreakManager.streakStats(completedWalks: [w0, w1, w2], calendar: calendar, now: d2)
        XCTAssertEqual(stats.longest, 3)
        XCTAssertEqual(stats.current, 3)
    }
}
