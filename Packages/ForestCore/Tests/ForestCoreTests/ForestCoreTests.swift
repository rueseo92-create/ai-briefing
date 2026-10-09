import XCTest
@testable import ForestCore

private let day: TimeInterval = 86_400
private let t0 = Date(timeIntervalSince1970: 1_790_000_000)

private var utc: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

final class HabitTests: XCTestCase {
    func testStreakAndTotalWithoutSlips() {
        let habit = Habit(kind: .smoking, startedAt: t0, dailyCost: 4_500)
        let now = t0 + 5 * day + 3600
        XCTAssertEqual(habit.currentStreak(at: now), 5 * day + 3600)
        XCTAssertEqual(habit.totalCleanDays(at: now), 5)
        XCTAssertEqual(habit.moneySaved(at: t0 + 2 * day), 9_000)
        XCTAssertFalse(habit.isWilting(at: now))
    }

    func testSlipCostsOneDayInsteadOfResetting() {
        var habit = Habit(kind: .drinking, startedAt: t0)
        habit.recordSlip(at: t0 + 10 * day)
        let now = t0 + 12 * day
        XCTAssertEqual(habit.currentStreak(at: now), 2 * day)
        XCTAssertEqual(habit.totalCleanDays(at: now), 11)
        XCTAssertEqual(habit.stage(at: now), .youngTree)
    }

    func testTotalNeverDropsBelowCurrentStreak() {
        var habit = Habit(kind: .gambling, startedAt: t0)
        habit.recordSlip(at: t0 + 3600)
        habit.recordSlip(at: t0 + 7200)
        let now = t0 + 7200 + 1800
        XCTAssertEqual(habit.totalClean(at: now), 1800)
    }

    func testWiltingLastsOneDayAfterSlip() {
        var habit = Habit(kind: .gaming, startedAt: t0)
        habit.recordSlip(at: t0 + 5 * day)
        XCTAssertTrue(habit.isWilting(at: t0 + 5 * day + 3600))
        XCTAssertFalse(habit.isWilting(at: t0 + 6 * day + 1))
    }

    func testCustomTitleFallsBack() {
        XCTAssertEqual(Habit(kind: .custom, customTitle: "  ", startedAt: t0).title, "나의 습관")
        XCTAssertEqual(Habit(kind: .custom, customTitle: "커피", startedAt: t0).title, "커피")
        XCTAssertEqual(Habit(kind: .lateNightSnack, startedAt: t0).title, "야식")
    }

    func testWishProgressIsClamped() {
        let wish = Wish(title: "운동화", price: 100_000)
        XCTAssertEqual(wish.progress(saved: 25_000), 0.25)
        XCTAssertEqual(wish.progress(saved: 500_000), 1)
        XCTAssertEqual(Wish(title: "공짜", price: 0).progress(saved: 10), 0)
    }
}

final class GrowthTests: XCTestCase {
    func testStageThresholds() {
        XCTAssertEqual(GrowthStage(cleanDays: 0), .seed)
        XCTAssertEqual(GrowthStage(cleanDays: 1), .sprout)
        XCTAssertEqual(GrowthStage(cleanDays: 6), .sapling)
        XCTAssertEqual(GrowthStage(cleanDays: 7), .youngTree)
        XCTAssertEqual(GrowthStage(cleanDays: 364), .fruit)
        XCTAssertEqual(GrowthStage(cleanDays: 1000), .grand)
        XCTAssertNil(GrowthStage.grand.next)
    }

    func testMilestones() {
        XCTAssertEqual(Milestones.reached(cleanDays: 8).map(\.days), [1, 3, 7])
        XCTAssertEqual(Milestones.next(cleanDays: 8)?.days, 14)
        XCTAssertNil(Milestones.next(cleanDays: 400))
    }
}

final class TreeNameTests: XCTestCase {
    func testNameIsStableForSeed() {
        let seed = UUID()
        XCTAssertEqual(TreeName.make(seed: seed), TreeName.make(seed: seed))
        let parts = TreeName.make(seed: seed)
        XCTAssertTrue(TreeName.trees.contains { parts.hasSuffix($0) })
    }
}

final class CheerBudgetTests: XCTestCase {
    func testDailyLimitAndReset() {
        var budget = CheerBudget(now: t0, calendar: utc)
        for _ in 0..<CheerBudget.dailyLimit {
            XCTAssertTrue(budget.spend(at: t0, calendar: utc))
        }
        XCTAssertFalse(budget.spend(at: t0, calendar: utc))
        XCTAssertEqual(budget.remaining(at: t0, calendar: utc), 0)
        XCTAssertEqual(budget.remaining(at: t0 + day, calendar: utc), CheerBudget.dailyLimit)
        XCTAssertTrue(budget.spend(at: t0 + day, calendar: utc))
        XCTAssertEqual(budget.remaining(at: t0 + day, calendar: utc), CheerBudget.dailyLimit - 1)
    }
}

final class UrgeSessionTests: XCTestCase {
    func testCountdown() {
        let urge = UrgeSession(startedAt: t0)
        XCTAssertEqual(urge.remaining(at: t0 + 60), 9 * 60)
        XCTAssertFalse(urge.isFinished(at: t0 + 60))
        XCTAssertTrue(urge.isFinished(at: t0 + 600))
        XCTAssertEqual(urge.progress(at: t0 + 300), 0.5)
        XCTAssertEqual(Format.countdown(urge.remaining(at: t0 + 0.5)), "10:00")
    }
}

final class PublicTreeTests: XCTestCase {
    /// 숲에 나가는 필드는 이것뿐이어야 한다. 끊는 것·일수·돈·이유가 새어 나가면 실패한다.
    func testOnlyAllowedFieldsAreShared() throws {
        var habit = Habit(kind: .gambling, customTitle: "비밀", startedAt: t0, dailyCost: 50_000, reason: "가족", goal: .lifetime)
        habit.wish = Wish(title: "여행", price: 1_000_000)
        let tree = PublicTree(id: "abc", name: "조용한 소나무", habit: habit, urgingSince: t0, now: t0 + 30 * day, calendar: utc)
        let data = try JSONEncoder().encode(tree)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(Set(object.keys), ["id", "name", "stage", "isWilting", "urgingSince", "startDay", "updatedAt"])
        let json = String(decoding: data, as: UTF8.self)
        for secret in ["gambling", "비밀", "50000", "가족", "여행", "goal", "lifetime"] {
            XCTAssertFalse(json.contains(secret), "\(secret) leaked")
        }
        XCTAssertEqual(tree.stage, .tree)
        XCTAssertEqual(tree.startDay, DayKey.make(t0, calendar: utc))
    }

    func testUrgingWindowAndStats() {
        func tree(_ id: String, stage: GrowthStage, urging: Date?, day startDay: String = "2026-10-01", updated: Date = t0) -> PublicTree {
            PublicTree(id: id, name: id, stage: stage, isWilting: false, urgingSince: urging, startDay: startDay, updatedAt: updated)
        }
        let now = t0 + 60
        let trees = [
            tree("a", stage: .seed, urging: t0),
            tree("b", stage: .grand, urging: nil),
            tree("c", stage: .tree, urging: t0 - UrgeSession.publicWindow - 1),
            tree("d", stage: .sprout, urging: nil, day: "2026-10-02", updated: t0 - 8 * day),
        ]
        XCTAssertEqual(ForestStats.urgingCount(trees, now: now), 1)
        XCTAssertEqual(ForestStats.sorted(trees, now: now).map(\.id), ["a", "b", "c", "d"])
        XCTAssertEqual(ForestStats.cohort(trees, startDay: "2026-10-02", now: now), Cohort(total: 1, active: 0))
        XCTAssertEqual(ForestStats.cohort(trees, startDay: "2026-10-01", now: now), Cohort(total: 3, active: 3))
    }
}

final class FormatTests: XCTestCase {
    func testFormats() {
        XCTAssertEqual(Format.won(54_000), "54,000원")
        let elapsed = Format.elapsed(2 * day + 4 * 3600 + 23 * 60 + 11)
        XCTAssertEqual(elapsed.days, 2)
        XCTAssertEqual(elapsed.clock, "04:23:11")
    }
}

final class GoalTests: XCTestCase {
    func testDayGoalProgress() {
        let goal = Goal.days(70)
        XCTAssertEqual(goal.progress(cleanDays: 35), 0.5)
        XCTAssertEqual(goal.remaining(cleanDays: 45), 25)
        XCTAssertFalse(goal.isReached(cleanDays: 69))
        XCTAssertTrue(goal.isReached(cleanDays: 70))
        XCTAssertEqual(goal.progress(cleanDays: 200), 1)
    }

    func testLifetimeNeverEnds() {
        XCTAssertNil(Goal.lifetime.progress(cleanDays: 10_000))
        XCTAssertNil(Goal.lifetime.remaining(cleanDays: 10))
        XCTAssertFalse(Goal.lifetime.isReached(cleanDays: 10_000))
        XCTAssertEqual(Goal.lifetime.title, "평생")
    }

    func testCustomIsClampedAndChoicesSkipPassedGoals() {
        XCTAssertEqual(Goal.custom(0), .days(1))
        XCTAssertEqual(Goal.custom(99_999), .days(Goal.maxDays))
        XCTAssertEqual(Goal.choices(cleanDays: 40), [.days(70), .days(100), .days(365), .lifetime])
        XCTAssertEqual(Goal.choices(cleanDays: 5_000), [.lifetime])
    }

    func testGoalSurvivesSlip() {
        var habit = Habit(kind: .smoking, startedAt: t0, goal: .days(70))
        habit.recordSlip(at: t0 + 40 * day)
        XCTAssertFalse(habit.goal!.isReached(cleanDays: habit.totalCleanDays(at: t0 + 70 * day)))
        XCTAssertTrue(habit.goal!.isReached(cleanDays: habit.totalCleanDays(at: t0 + 71 * day)))
    }

    /// 목표 기능 전에 저장된 데이터도 그대로 읽혀야 한다.
    func testOldSavedHabitDecodesWithoutGoal() throws {
        var object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(Habit(kind: .drinking, startedAt: t0))) as? [String: Any]
        )
        object.removeValue(forKey: "goal")
        let habit = try JSONDecoder().decode(Habit.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertNil(habit.goal)
        let lifetime = try JSONDecoder().decode(Goal.self, from: JSONEncoder().encode(Goal.lifetime))
        XCTAssertEqual(lifetime, .lifetime)
    }
}
