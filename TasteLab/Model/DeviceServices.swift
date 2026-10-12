import Foundation
import UserNotifications
import WeatherKit
import CoreLocation
import TasteCore

/// 월요일 체크인, 키트 마감, 주말 계획 알림. 이 기기 안에서만 울린다.
struct LocalReminders: ReminderSink {
    func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func replace(with reminders: [Reminder]) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: WeeklyReminders.allIDs)
        for reminder in reminders {
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.body
            content.sound = .default
            let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger))
        }
    }

    func cancelAll() async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: WeeklyReminders.allIDs)
    }
}

/// Apple 날씨(WeatherKit). 동네 좌표만 쓴다. WeatherKit 권한이 없으면 날씨 없이 동작한다.
struct WeatherKitProvider: WeatherProvider {
    /// 날씨를 보여 줄 때 함께 걸어야 하는 출처 표시.
    static let attributionURL = URL(string: "https://weatherkit.apple.com/legal-attribution.html")!

    func outlook(for origin: Coordinate) async -> WeatherOutlook? {
        do {
            let daily = try await WeatherService.shared.weather(
                for: CLLocation(latitude: origin.latitude, longitude: origin.longitude),
                including: .daily
            )
            let days = daily.forecast.prefix(7).map { day in
                DayForecast(date: day.date, rainChance: day.precipitationChance, highC: day.highTemperature.converted(to: .celsius).value)
            }
            return WeatherOutlook(origin: origin, fetchedAt: Date(), days: Array(days))
        } catch {
            return nil
        }
    }
}

struct MapKitPlaceSearcher: PlaceSearcher {
    func search(around origin: Coordinate) async -> NearbyPlaces? {
        await PlaceFinder.search(around: origin)
    }
}
