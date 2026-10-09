import Foundation
import UserNotifications
import ForestCore

/// 기기 안에서만 울리는 알림. 서버를 거치지 않는다.
/// 문구는 ForestCore의 Reminders가 만든다. 잠금 화면에 뜨므로 무엇을 끊는지는 넣지 않는다.
enum Notifier {
    private static var center: UNUserNotificationCenter { .current() }

    static func requestPermission() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    static func schedule(_ reminders: [Reminder]) {
        for reminder in reminders {
            let interval = reminder.date.timeIntervalSinceNow
            guard interval > 1 else { continue }
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.body
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            center.add(UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger))
        }
    }

    static func cancel(_ ids: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// 성장 알림을 지우고 새 계획으로 바꾼다.
    static func replaceGrowth(with reminders: [Reminder]) async {
        let pending = await center.pendingNotificationRequests()
        cancel(pending.map(\.identifier).filter { $0.hasPrefix(Reminders.growthPrefix) })
        schedule(reminders)
    }

    static func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
}
