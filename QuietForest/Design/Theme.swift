import SwiftUI
import UIKit
import ForestCore

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

// MARK: - 꾸미기

extension Theme {
    /// 잎 색. (밝은 잎, 짙은 잎)
    static func leafColors(_ item: GardenItem) -> (light: Color, deep: Color) {
        switch item {
        case .leafMaple: (Color(light: 0xE0703F, dark: 0xE8804F), Color(light: 0xB9492B, dark: 0xC45A3A))
        case .leafGinkgo: (Color(light: 0xE9BE36, dark: 0xF0C94A), Color(light: 0xC99A1E, dark: 0xD2A42C))
        case .leafCherry: (Color(light: 0xF4B3C6, dark: 0xF0B7C8), Color(light: 0xE08DA7, dark: 0xD9879F))
        case .leafSnow: (Color(light: 0xEDF3F6, dark: 0xDCE6EC), Color(light: 0xC3D3DD, dark: 0xA9BCC8))
        default: (leaf, leafDeep)
        }
    }

    /// 꽃·열매 점. 벚꽃 잎 위에서는 흰 꽃이 보이게.
    static func dotColor(stage: GrowthStage, leaf: GardenItem) -> Color {
        if stage == .blossom { return leaf == .leafCherry ? .white : blossom }
        return fruit
    }

    /// 나무를 톡 건드리면 떨어지는 것.
    static func fallingLeaf(_ item: GardenItem) -> String {
        switch item {
        case .leafMaple: "🍁"
        case .leafGinkgo: "🍂"
        case .leafCherry: "🌸"
        case .leafSnow: "❄️"
        default: "🍃"
        }
    }

    static func skyColors(_ item: GardenItem) -> [Color] {
        switch item {
        case .skySunset: [Color(light: 0xF7C98F, dark: 0x6B4250), Color(light: 0xF2A3A8, dark: 0x2E2440)]
        case .skyNight: [Color(light: 0x23305A, dark: 0x141B36), Color(light: 0x4A4F86, dark: 0x2C3062)]
        case .skyRainbow: [Color(light: 0xD5EAF5, dark: 0x1F3340), Color(light: 0xF1F6F2, dark: 0x1A2620)]
        default: [Color(light: 0xDCEBF3, dark: 0x1B2A33), Color(light: 0xF1F4EC, dark: 0x18221C)]
        }
    }
}
