import Foundation

/// 내 나무 꾸미기. 사는 것도, 출석 체크도 없다. 참은 날과 버텨 낸 순간, 받은 물로만 하나씩 생긴다.
/// 이 기기에만 저장되고 숲에는 보이지 않는다.
public enum GardenCategory: String, Codable, CaseIterable, Sendable {
    case leaf
    case sky
    case decoration

    public var title: String {
        switch self {
        case .leaf: "잎 색"
        case .sky: "하늘"
        case .decoration: "장식"
        }
    }
}

/// 꾸밀 것이 생기는 조건.
public enum Unlock: Equatable, Sendable {
    case free
    case cleanDays(Int)
    case urgeWins(Int)
    case cheers(Int)

    public var hint: String {
        switch self {
        case .free: "처음부터"
        case .cleanDays(let days): "\(days)일 참으면"
        case .urgeWins(let count): "참기를 \(count)번 버티면"
        case .cheers(let count): "물을 \(count)방울 받으면"
        }
    }
}

/// 지금까지 한 것. 꾸밀 것이 생겼는지 확인하는 데 쓴다.
public struct GardenProgress: Equatable, Sendable {
    public var cleanDays: Int
    public var urgeWins: Int
    public var cheers: Int

    public init(cleanDays: Int, urgeWins: Int, cheers: Int) {
        self.cleanDays = cleanDays
        self.urgeWins = urgeWins
        self.cheers = cheers
    }

    public func meets(_ unlock: Unlock) -> Bool {
        switch unlock {
        case .free: true
        case .cleanDays(let days): cleanDays >= days
        case .urgeWins(let count): urgeWins >= count
        case .cheers(let count): cheers >= count
        }
    }
}

public enum GardenItem: String, Codable, CaseIterable, Identifiable, Sendable {
    // 잎 색
    case leafSpring, leafMaple, leafGinkgo, leafCherry, leafSnow
    // 하늘
    case skyDay, skySunset, skyNight, skyRainbow
    // 장식
    case daisy, pebble, butterfly, mushroom, ladybug, squirrel, firefly, nest, bird, rabbit, owl, lantern, deer

    public var id: String { rawValue }

    public var category: GardenCategory {
        switch self {
        case .leafSpring, .leafMaple, .leafGinkgo, .leafCherry, .leafSnow: .leaf
        case .skyDay, .skySunset, .skyNight, .skyRainbow: .sky
        default: .decoration
        }
    }

    public var title: String {
        switch self {
        case .leafSpring: "초록 잎"
        case .leafMaple: "단풍"
        case .leafGinkgo: "은행잎"
        case .leafCherry: "벚꽃"
        case .leafSnow: "눈꽃"
        case .skyDay: "맑은 날"
        case .skySunset: "노을"
        case .skyNight: "별밤"
        case .skyRainbow: "비 갠 하늘"
        case .daisy: "들꽃"
        case .pebble: "조약돌"
        case .butterfly: "나비"
        case .mushroom: "버섯"
        case .ladybug: "무당벌레"
        case .squirrel: "다람쥐"
        case .firefly: "반딧불"
        case .nest: "새 둥지"
        case .bird: "작은 새"
        case .rabbit: "토끼"
        case .owl: "부엉이"
        case .lantern: "등불"
        case .deer: "사슴"
        }
    }

    public var emoji: String {
        switch self {
        case .leafSpring: "🌿"
        case .leafMaple: "🍁"
        case .leafGinkgo: "🍂"
        case .leafCherry: "🌸"
        case .leafSnow: "❄️"
        case .skyDay: "☀️"
        case .skySunset: "🌇"
        case .skyNight: "🌙"
        case .skyRainbow: "🌈"
        case .daisy: "🌼"
        case .pebble: "🪨"
        case .butterfly: "🦋"
        case .mushroom: "🍄"
        case .ladybug: "🐞"
        case .squirrel: "🐿️"
        case .firefly: "✨"
        case .nest: "🪺"
        case .bird: "🐦"
        case .rabbit: "🐇"
        case .owl: "🦉"
        case .lantern: "🏮"
        case .deer: "🦌"
        }
    }

    /// 참은 날로 생기는 것이 대부분이고, 버텨 낸 순간과 받은 물로 생기는 것이 몇 개 섞여 있다.
    public var unlock: Unlock {
        switch self {
        case .leafSpring, .skyDay: .free
        case .daisy: .cleanDays(1)
        case .pebble: .cleanDays(3)
        case .butterfly: .urgeWins(1)
        case .leafMaple, .mushroom: .cleanDays(7)
        case .ladybug: .cheers(3)
        case .skySunset: .urgeWins(3)
        case .skyRainbow: .cheers(5)
        case .skyNight, .squirrel: .cleanDays(14)
        case .firefly: .urgeWins(5)
        case .leafGinkgo: .cleanDays(21)
        case .nest: .cleanDays(30)
        case .bird: .cheers(10)
        case .leafCherry: .cleanDays(50)
        case .rabbit: .cleanDays(60)
        case .owl: .urgeWins(15)
        case .leafSnow, .lantern: .cleanDays(100)
        case .deer: .cleanDays(365)
        }
    }

    public static func items(in category: GardenCategory) -> [GardenItem] {
        allCases.filter { $0.category == category }
    }
}

/// 지금 내 나무의 모습.
public struct GardenStyle: Codable, Equatable, Sendable {
    /// 장식은 이만큼만. 조금씩 골라 다는 맛이 있게.
    public static let maxDecorations = 5

    public private(set) var leaf: GardenItem
    public private(set) var sky: GardenItem
    public private(set) var decorations: [GardenItem]

    public init() {
        leaf = .leafSpring
        sky = .skyDay
        decorations = []
    }

    public func isUsing(_ item: GardenItem) -> Bool {
        switch item.category {
        case .leaf: leaf == item
        case .sky: sky == item
        case .decoration: decorations.contains(item)
        }
    }

    /// 잎과 하늘은 바꾸고, 장식은 달거나 뗀다. 아직 없는 것이거나 장식이 꽉 찼으면 false.
    public mutating func toggle(_ item: GardenItem, unlocked: Set<GardenItem>) -> Bool {
        guard unlocked.contains(item) else { return false }
        switch item.category {
        case .leaf:
            leaf = item
        case .sky:
            sky = item
        case .decoration:
            if let index = decorations.firstIndex(of: item) {
                decorations.remove(at: index)
            } else {
                guard decorations.count < Self.maxDecorations else { return false }
                decorations.append(item)
            }
        }
        return true
    }
}

/// 가진 것과 지금 모습. 한 번 생긴 것은 다시 해도 사라지지 않는다.
public struct GardenCollection: Codable, Equatable, Sendable {
    public private(set) var unlocked: Set<GardenItem>
    /// 꾸미기 화면에서 이미 본 것. 나머지에는 "새로" 표시를 단다.
    public private(set) var seen: Set<GardenItem>
    public private(set) var style: GardenStyle

    public init() {
        let free = Set(GardenItem.allCases.filter { $0.unlock == .free })
        unlocked = free
        seen = free
        style = GardenStyle()
    }

    /// 새로 생긴 것을 순서대로 돌려준다.
    public mutating func update(with progress: GardenProgress) -> [GardenItem] {
        let fresh = GardenItem.allCases.filter { !unlocked.contains($0) && progress.meets($0.unlock) }
        unlocked.formUnion(fresh)
        return fresh
    }

    public var unseen: [GardenItem] {
        GardenItem.allCases.filter { unlocked.contains($0) && !seen.contains($0) }
    }

    public mutating func markSeen() {
        seen = unlocked
    }

    @discardableResult
    public mutating func toggle(_ item: GardenItem) -> Bool {
        style.toggle(item, unlocked: unlocked)
    }
}
