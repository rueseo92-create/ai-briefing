import Foundation

/// 기기 안에서만 울리는 알림 하나.
public struct Reminder: Equatable, Sendable {
    public let id: String
    public let date: Date
    public let title: String
    public let body: String

    public init(id: String, date: Date, title: String, body: String) {
        self.id = id
        self.date = date
        self.title = title
        self.body = body
    }
}

/// 알림 문구와 시각.
///
/// 알림은 잠금 화면에 뜨므로 무엇을 끊는지, 돈, 이유는 절대 넣지 않는다.
/// 나무 모습과 날짜만 말한다. (RemindersTests가 확인한다)
public enum Reminders {
    public static let urgeDoneID = "urge-done"
    /// 성장 알림 id의 앞부분. 다시 계획할 때 이것으로 한꺼번에 지운다.
    public static let growthPrefix = "grow-"
    /// 이 시간 밖에 닿는 성장 알림은 아침으로 미룬다.
    public static let quietHours = (end: 9, start: 21)

    /// 참기 타이머가 끝났을 때. 앱을 닫아 두어도 알 수 있게.
    public static func urgeDone(_ urge: UrgeSession) -> Reminder {
        Reminder(
            id: urgeDoneID,
            date: urge.startedAt.addingTimeInterval(urge.duration),
            title: "버텼어요 🌱",
            body: "충동이 지나갔어요. 앱을 열어 숲에 기록해요."
        )
    }

    /// 다음 성장 단계, 배지, 목표에 닿는 때. 다시 하면 시각이 밀리니 그때마다 새로 만든다.
    public static func upcoming(habit: Habit, now: Date, calendar: Calendar = .current, limit: Int = 3) -> [Reminder] {
        let days = habit.totalCleanDays(at: now)
        var targets = Set<Int>()
        targets.formUnion(GrowthStage.allCases.map(\.requiredDays).filter { $0 > days })
        targets.formUnion(Milestones.all.map(\.days).filter { $0 > days })
        if let target = habit.goal?.targetDays, target > days { targets.insert(target) }

        return targets.sorted().prefix(limit).compactMap { target in
            guard let reachAt = habit.date(reachingCleanDays: target, after: now) else { return nil }
            let goal = habit.goal?.targetDays == target ? habit.goal : nil
            let milestone = Milestones.all.first { $0.days == target }
            let stage = GrowthStage.allCases.first { $0.requiredDays == target }
            let (title, body) = message(goal: goal, milestone: milestone, stage: stage)
            return Reminder(
                id: "\(growthPrefix)\(target)",
                date: daytime(reachAt, calendar: calendar),
                title: title,
                body: body
            )
        }
    }

    /// 밤이나 새벽이면 아침 9시로 미룬다.
    public static func daytime(_ date: Date, calendar: Calendar = .current) -> Date {
        let hour = calendar.component(.hour, from: date)
        if hour >= quietHours.end && hour < quietHours.start { return date }
        let day = hour < quietHours.end ? date : (calendar.date(byAdding: .day, value: 1, to: date) ?? date)
        return calendar.date(bySettingHour: quietHours.end, minute: 0, second: 0, of: day) ?? date
    }

    private static func message(goal: Goal?, milestone: Milestone?, stage: GrowthStage?) -> (String, String) {
        var parts: [String] = []
        if let goal { parts.append("\(goal.title) 목표를 이뤘어요.") }
        if let milestone { parts.append("‘\(milestone.title)’ 배지를 받았어요.") }
        if let stage { parts.append("이제 \(stage.title)\(copula(after: stage.title)).") }
        if goal != nil {
            parts.append("다음 목표를 골라 봐요.")
        } else if milestone == nil {
            parts.append("숲에서도 바뀐 모습이 보여요.")
        }
        let title = goal != nil ? "목표에 닿았어요 🎯" : milestone != nil ? "배지를 받았어요 🏅" : "나무가 자랐어요 🌳"
        return (title, parts.joined(separator: " "))
    }

    /// 받침이 있으면 "이에요", 없으면 "예요".
    static func copula(after word: String) -> String {
        guard let last = word.unicodeScalars.last, (0xAC00...0xD7A3).contains(last.value) else { return "이에요" }
        return (last.value - 0xAC00) % 28 == 0 ? "예요" : "이에요"
    }
}
