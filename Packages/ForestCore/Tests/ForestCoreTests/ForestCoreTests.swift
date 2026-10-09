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
        for index in 0..<CheerBudget.dailyLimit {
            XCTAssertTrue(budget.spend(on: "tree-\(index)", at: t0, calendar: utc))
        }
        XCTAssertFalse(budget.spend(on: "another", at: t0, calendar: utc))
        XCTAssertEqual(budget.remaining(at: t0, calendar: utc), 0)
        XCTAssertEqual(budget.remaining(at: t0 + day, calendar: utc), CheerBudget.dailyLimit)
        XCTAssertTrue(budget.spend(on: "tree-0", at: t0 + day, calendar: utc))
        XCTAssertEqual(budget.remaining(at: t0 + day, calendar: utc), CheerBudget.dailyLimit - 1)
    }

    func testOneDropPerTreePerDay() {
        var budget = CheerBudget(now: t0, calendar: utc)
        XCTAssertTrue(budget.spend(on: "a", at: t0, calendar: utc))
        XCTAssertFalse(budget.spend(on: "a", at: t0 + 60, calendar: utc))
        XCTAssertTrue(budget.hasWatered("a", at: t0, calendar: utc))
        XCTAssertEqual(budget.remaining(at: t0, calendar: utc), CheerBudget.dailyLimit - 1)
        XCTAssertFalse(budget.hasWatered("a", at: t0 + day, calendar: utc))
    }

    /// 앱을 다시 열어도 오늘 물 준 나무를 기억하고, 예전 데이터도 읽힌다.
    func testWateredTreesSurviveSaveAndOldDataDecodes() throws {
        var budget = CheerBudget(now: t0, calendar: utc)
        _ = budget.spend(on: "a", at: t0, calendar: utc)
        let restored = try JSONDecoder().decode(CheerBudget.self, from: JSONEncoder().encode(budget))
        XCTAssertTrue(restored.hasWatered("a", at: t0, calendar: utc))

        let old = #"{"day":"2026-10-08","used":2}"#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(CheerBudget.self, from: old)
        XCTAssertEqual(decoded.used, 2)
        XCTAssertTrue(decoded.wateredIDs.isEmpty)
    }
}

final class CheerInboxTests: XCTestCase {
    func testSameSenderCountsOncePerDay() {
        var inbox = CheerInbox(now: t0, calendar: utc)
        let spam = Array(repeating: IncomingCheer(sender: "x", sentAt: t0), count: 50)
        XCTAssertEqual(inbox.receive(spam + [IncomingCheer(sender: "y", sentAt: t0)], now: t0, calendar: utc), 2)
        XCTAssertEqual(inbox.receive([IncomingCheer(sender: "x", sentAt: t0 + 60)], now: t0 + 60, calendar: utc), 0)
        XCTAssertEqual(inbox.count(at: t0, calendar: utc), 2)
        // 다음 날에는 같은 사람의 물방울도 다시 센다.
        XCTAssertEqual(inbox.receive([IncomingCheer(sender: "x", sentAt: t0 + day)], now: t0 + day, calendar: utc), 1)
        XCTAssertEqual(inbox.count(at: t0 + day, calendar: utc), 1)
        XCTAssertEqual(inbox.count(at: t0 + 2 * day, calendar: utc), 0)
    }

    func testUnknownSendersAlwaysCount() {
        var inbox = CheerInbox(day: DayKey.make(t0, calendar: utc), count: 2)
        let cheers = Array(repeating: IncomingCheer(sender: nil, sentAt: t0), count: 3)
        XCTAssertEqual(inbox.receive(cheers, now: t0, calendar: utc), 3)
        XCTAssertEqual(inbox.count(at: t0, calendar: utc), 5)
    }
}

final class RemindersTests: XCTestCase {
    /// 오후에 시작해서 알림 시각이 낮에 떨어지게 한다.
    private let noon = Date(timeIntervalSince1970: 1_790_000_000 - 1_790_000_000.truncatingRemainder(dividingBy: day) + 12 * 3600)

    func testUpcomingMergesStageMilestoneAndGoal() {
        let habit = Habit(kind: .smoking, startedAt: noon, goal: .days(7))
        let reminders = Reminders.upcoming(habit: habit, now: noon + 3600, calendar: utc)
        XCTAssertEqual(reminders.map(\.id), ["grow-1", "grow-3", "grow-7"])
        XCTAssertEqual(reminders[0].date, noon + day)
        XCTAssertEqual(reminders[0].title, "배지를 받았어요 🏅")
        XCTAssertEqual(reminders[0].body, "‘첫 하루’ 배지를 받았어요. 이제 새싹이에요.")
        XCTAssertEqual(reminders[2].title, "목표에 닿았어요 🎯")
        XCTAssertEqual(reminders[2].body, "7일 목표를 이뤘어요. ‘일주일’ 배지를 받았어요. 이제 어린 나무예요. 다음 목표를 골라 봐요.")
    }

    func testStageOnlyAndLimit() {
        let habit = Habit(kind: .drinking, startedAt: noon - 15 * day)
        let reminders = Reminders.upcoming(habit: habit, now: noon, calendar: utc, limit: 1)
        XCTAssertEqual(reminders.map(\.id), ["grow-21"])
        XCTAssertEqual(reminders[0].title, "나무가 자랐어요 🌳")
        XCTAssertEqual(reminders[0].body, "이제 나무예요. 숲에서도 바뀐 모습이 보여요.")
        XCTAssertEqual(reminders[0].date, noon + 6 * day)
    }

    func testSlipPushesRemindersBack() {
        var habit = Habit(kind: .gaming, startedAt: noon)
        habit.recordSlip(at: noon + 2 * 3600)
        let reminders = Reminders.upcoming(habit: habit, now: noon + 3 * 3600, calendar: utc)
        XCTAssertEqual(reminders.first?.id, "grow-1")
        XCTAssertEqual(reminders.first?.date, noon + 2 * 3600 + day)
    }

    func testNightRemindersMoveToMorning() {
        let midnight = noon - 12 * 3600
        XCTAssertEqual(Reminders.daytime(midnight + 3 * 3600, calendar: utc), midnight + 9 * 3600)
        XCTAssertEqual(Reminders.daytime(midnight + 22 * 3600, calendar: utc), midnight + day + 9 * 3600)
        XCTAssertEqual(Reminders.daytime(midnight + 15 * 3600, calendar: utc), midnight + 15 * 3600)
    }

    /// 잠금 화면에 뜨는 문구에 무엇을 끊는지가 나오면 안 된다.
    func testRemindersNeverMentionTheHabit() {
        for kind in HabitKind.allCases {
            let habit = Habit(kind: kind, customTitle: "비밀", startedAt: noon, dailyCost: 50_000, reason: "가족", goal: .days(30))
            let texts = Reminders.upcoming(habit: habit, now: noon, calendar: utc, limit: 20)
                .flatMap { [$0.title, $0.body] } + [Reminders.urgeDone(UrgeSession(startedAt: noon)).body]
            for secret in [habit.title, kind.emoji, "50,000", "가족"] {
                XCTAssertFalse(texts.contains { $0.contains(secret) }, "\(secret) leaked")
            }
        }
    }

    func testUrgeDoneFiresWhenTimerEnds() {
        let reminder = Reminders.urgeDone(UrgeSession(startedAt: t0))
        XCTAssertEqual(reminder.id, Reminders.urgeDoneID)
        XCTAssertEqual(reminder.date, t0 + UrgeSession.defaultDuration)
    }

    func testCopula() {
        XCTAssertEqual(Reminders.copula(after: "묘목"), "이에요")
        XCTAssertEqual(Reminders.copula(after: "큰 나무"), "예요")
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
        var garden = GardenCollection()
        _ = garden.update(with: GardenProgress(cleanDays: 30, urgeWins: 0, cheers: 0))
        garden.toggle(.leafMaple)
        garden.toggle(.mushroom)
        garden.toggle(.skyNight)
        let tree = PublicTree(id: "abc", name: "조용한 소나무", habit: habit, style: garden.style, urgingSince: t0, now: t0 + 30 * day, calendar: utc)
        let data = try JSONEncoder().encode(tree)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(Set(object.keys), ["id", "name", "stage", "isWilting", "urgingSince", "startDay", "updatedAt", "leaf", "decorations"])
        XCTAssertEqual(tree.leaf, .leafMaple)
        XCTAssertEqual(tree.decorations, [.mushroom])
        XCTAssertFalse(String(decoding: data, as: UTF8.self).contains("skyNight"), "하늘은 숲에 나가지 않는다")
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
