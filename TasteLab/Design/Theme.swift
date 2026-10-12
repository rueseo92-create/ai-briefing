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
        case .sound: Color(light: 0x7A6FD6, dark: 0x9C92EE)
        case .taste: Color(light: 0xC77A3A, dark: 0xE39A5C)
        case .place: Color(light: 0x3E8E7E, dark: 0x5DBBA6)
        case .body: Color(light: 0xD3584F, dark: 0xEE7C73)
        case .hands: Color(light: 0xB58A2E, dark: 0xDDB052)
        case .people: Color(light: 0xCF5F97, dark: 0xEE86B7)
        case .mind: Color(light: 0x4A6FB5, dark: 0x7896DA)
        case .sight: Color(light: 0x5E9A3E, dark: 0x86C463)
        }
    }
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
