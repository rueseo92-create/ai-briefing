import SwiftUI
import UIKit

enum Theme {
    static let background = Color(light: 0xF3F1EA, dark: 0x121814)
    static let card = Color(light: 0xFBFAF6, dark: 0x1C241F)
    static let ink = Color(light: 0x1E2A22, dark: 0xE9EDE6)
    static let muted = Color(light: 0x5E6A61, dark: 0xA3B0A6)
    static let leaf = Color(light: 0x3F8F5A, dark: 0x5DB57A)
    static let leafDeep = Color(light: 0x2E6F45, dark: 0x469A63)
    static let wilt = Color(light: 0xA39A6B, dark: 0x8C845E)
    static let bark = Color(light: 0x7A5A3E, dark: 0x9C7A5B)
    static let ground = Color(light: 0xDDD5C0, dark: 0x2A3A2F)
    static let water = Color(light: 0x2F6E8F, dark: 0x6FB3D6)
    static let blossom = Color(light: 0xE79AB2, dark: 0xE7A6BB)
    static let fruit = Color(light: 0xE0823D, dark: 0xF09A55)
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
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

extension View {
    func card() -> some View { modifier(CardBackground()) }
}
