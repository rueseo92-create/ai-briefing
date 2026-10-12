import SwiftUI
import UIKit
import TasteCore

enum Theme {
    static let background = Color(light: 0xF6F2EC, dark: 0x16151A)
    static let card = Color(light: 0xFFFCF7, dark: 0x222027)
    static let ink = Color(light: 0x24212B, dark: 0xEEEAF2)
    static let muted = Color(light: 0x6E6876, dark: 0xA7A1AE)
    static let accent = Color(light: 0x6A55C9, dark: 0x9C8AF0)
    static let ad = Color(light: 0xB7791F, dark: 0xE0A54A)
    static let kit = Color(light: 0x2E7D6B, dark: 0x5CC2A8)

    static func slotColor(_ slot: Slot) -> Color {
        switch slot {
        case .confirm: Color(light: 0x3F8F5A, dark: 0x5DB57A)
        case .sideStep: Color(light: 0x2F6E8F, dark: 0x6FB3D6)
        case .fresh: Color(light: 0xC2557A, dark: 0xE88AAA)
        }
    }

    static func domainColor(_ domain: Domain) -> Color {
        switch domain {
        case .rest: Color(light: 0x6F7FC9, dark: 0x93A1E6)
        case .movement: Color(light: 0x4F9A6B, dark: 0x6FC28C)
        case .food: Color(light: 0xD07A45, dark: 0xE89A66)
        case .breath: Color(light: 0x3E8EA8, dark: 0x6BB8D0)
        case .nature: Color(light: 0x5E8F3E, dark: 0x86BA63)
        case .senses: Color(light: 0xC9628E, dark: 0xE88AB0)
        case .making: Color(light: 0xB58A2E, dark: 0xDDB052)
        case .connection: Color(light: 0xC8553D, dark: 0xE8775E)
        }
    }

    static let paper = Color(light: 0xFFFDF8, dark: 0x2A2730)
    static let stampInk = Color(light: 0xB8323A, dark: 0xE0626A)
    static let gold = Color(light: 0xC9A227, dark: 0xE6C350)
}

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

extension View {
    func card() -> some View { modifier(CardBackground()) }
}

/// 작은 꼬리표. "광고", "키트", "결이 같은" 같은 것.
struct Chip: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}

enum Formats {
    private static let locale = Locale(identifier: "ko_KR")

    /// 10월 16일 (목)
    static func day(_ date: Date) -> String {
        date.formatted(.dateTime.month(.defaultDigits).day().weekday(.abbreviated).locale(locale))
    }

    static func won(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        return (formatter.string(from: NSNumber(value: value)) ?? String(value)) + "원"
    }

    /// 0원 / 약 8,000원
    static func cost(_ value: Int) -> String {
        value == 0 ? "0원" : "약 " + won(value)
    }

    /// 실험 40분 · 오가는 시간 20분
    static func time(minutes: Int, travel: Int?) -> String {
        guard let travel else { return "실험 " + self.minutes(minutes) + " · 위치가 있어야 갈 수 있어요" }
        return travel == 0 ? "실험 " + self.minutes(minutes) : "실험 " + self.minutes(minutes) + " · 오가는 시간 " + self.minutes(travel)
    }

    static func minutes(_ value: Int) -> String {
        value >= 60 ? (value % 60 == 0 ? "\(value / 60)시간" : "\(value / 60)시간 \(value % 60)분") : "\(value)분"
    }

    static func kitLine(_ kit: Kit, now: Date = Date()) -> String {
        switch Weekend.status(of: kit, now: now) {
        case .thisWeekend(let orderBy, let saturday):
            "\(day(orderBy)) 낮 12시까지 주문하면 \(day(saturday))에 받아요"
        case .nextWeekend(let orderBy, let saturday):
            "이번 주말은 늦었어요 · \(day(orderBy)) 낮 12시까지 주문하면 \(day(saturday))에 받아요"
        }
    }
}
