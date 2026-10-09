import SwiftUI
import ForestCore

/// 성장 단계에 따라 그리는 나무. 100×100 격자 위에 그린 뒤 크기에 맞춰 늘린다.
struct TreeView: View {
    var stage: GrowthStage
    var isWilting = false
    /// 참는 중인 나무는 바람에 흔들린다.
    var isSwaying = false
    /// 내 나무를 꾸민 모습. 숲의 다른 나무는 nil(기본 모습)이다.
    var style: GardenStyle?
    var showsSky = false
    /// 바뀔 때마다 나무가 살짝 흔들린다. 톡 건드렸을 때.
    var poke = 0

    private var leafItem: GardenItem { style?.leaf ?? .leafSpring }

    var body: some View {
        ZStack {
            if showsSky {
                SkyBackdrop(sky: style?.sky ?? .skyDay)
            }
            TimelineView(.animation(paused: !isSwaying)) { timeline in
                let angle = isSwaying ? sin(timeline.date.timeIntervalSinceReferenceDate * 3) * 4 : 0
                Canvas { context, size in
                    draw(in: &context, size: size)
                }
                .rotationEffect(.degrees(angle), anchor: .bottom)
            }
            .keyframeAnimator(initialValue: 0.0, trigger: poke) { content, angle in
                content.rotationEffect(.degrees(angle), anchor: .bottom)
            } keyframes: { _ in
                KeyframeTrack {
                    SpringKeyframe(5, duration: 0.12)
                    SpringKeyframe(-3.5, duration: 0.16)
                    SpringKeyframe(1.5, duration: 0.16)
                    SpringKeyframe(0, duration: 0.24)
                }
            }
            if let style, !style.decorations.isEmpty {
                Canvas { context, size in
                    drawDecorations(style.decorations, in: &context, size: size)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var text = isWilting ? "\(stage.title), 잠깐 시든 상태" : stage.title
        if let style, !style.decorations.isEmpty {
            text += ", " + style.decorations.map(\.title).joined(separator: ", ")
        }
        return text
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let unit = min(size.width, size.height) / 100
        let originX = (size.width - unit * 100) / 2
        let originY = (size.height - unit * 100) / 2

        func rect(_ x: Double, _ y: Double, _ w: Double, _ h: Double) -> CGRect {
            CGRect(x: originX + x * unit, y: originY + y * unit, width: w * unit, height: h * unit)
        }
        func oval(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ color: Color) {
            context.fill(Path(ellipseIn: rect(x, y, w, h)), with: .color(color))
        }
        func trunk(_ x: Double, _ y: Double, _ w: Double, _ h: Double) {
            context.fill(Path(roundedRect: rect(x, y, w, h), cornerRadius: w * unit / 2), with: .color(Theme.bark))
        }

        let colors = Theme.leafColors(leafItem)
        let leaf = isWilting ? Theme.wilt : colors.light
        let leafDeep = isWilting ? Theme.wilt.opacity(0.8) : colors.deep
        // 시든 나무는 잎이 조금 처진다.
        let droop: Double = isWilting ? 3 : 0

        oval(14, 88, 72, 9, Theme.ground)

        switch stage {
        case .seed:
            oval(44, 83, 12, 9, Theme.bark)
        case .sprout:
            trunk(49, 72, 2.5, 18)
            oval(38, 68 + droop, 12, 7, leaf)
            oval(50.5, 66 + droop, 12, 7, leafDeep)
        case .sapling:
            trunk(48.5, 54, 3.5, 36)
            oval(35, 60 + droop, 14, 8, leaf)
            oval(51, 55 + droop, 14, 8, leafDeep)
            oval(39, 47 + droop, 13, 8, leaf)
            oval(49, 42 + droop, 11, 7, leafDeep)
        case .youngTree:
            trunk(47, 52, 6, 38)
            oval(30, 24 + droop, 40, 38, leafDeep)
            oval(36, 22 + droop, 30, 28, leaf)
        default:
            let grand = stage == .grand
            if grand {
                trunk(43.5, 46, 13, 44)
                oval(8, 30 + droop, 38, 36, leafDeep)
                oval(54, 30 + droop, 38, 36, leafDeep)
                oval(22, 6 + droop, 56, 48, leaf)
                oval(16, 22 + droop, 32, 30, leaf)
                oval(52, 22 + droop, 32, 30, leaf)
            } else {
                trunk(45.5, 50, 9, 40)
                oval(20, 30 + droop, 34, 32, leafDeep)
                oval(46, 30 + droop, 34, 32, leafDeep)
                oval(30, 12 + droop, 40, 38, leaf)
            }
            let dots: [(Double, Double)] = grand
                ? [(20, 34), (34, 18), (50, 12), (66, 20), (78, 38), (30, 46), (62, 44), (46, 32)]
                : [(28, 38), (40, 22), (56, 20), (66, 38), (48, 40), (36, 50), (60, 52)]
            if !isWilting, stage == .blossom || stage == .fruit || grand {
                let color = Theme.dotColor(stage: stage, leaf: leafItem)
                let dot: Double = stage == .blossom ? 4 : 5
                for (x, y) in dots {
                    oval(x, y + droop, dot, dot, color)
                }
            }
        }
    }

    /// 장식은 땅과 하늘에 자리가 정해져 있다. 둥지와 부엉이는 가지가 생기기 전엔 땅에 앉는다.
    private func drawDecorations(_ items: [GardenItem], in context: inout GraphicsContext, size: CGSize) {
        let unit = min(size.width, size.height) / 100
        let originX = (size.width - unit * 100) / 2
        let originY = (size.height - unit * 100) / 2
        let hasBranches = stage >= .youngTree

        for item in items {
            guard let spot = Self.spot(for: item, hasBranches: hasBranches) else { continue }
            let text = Text(item.emoji).font(.system(size: spot.size * unit))
            context.draw(text, at: CGPoint(x: originX + spot.x * unit, y: originY + spot.y * unit))
        }
    }

    /// (가운데 x, 가운데 y, 크기) — 100×100 격자 기준.
    private static func spot(for item: GardenItem, hasBranches: Bool) -> (x: Double, y: Double, size: Double)? {
        switch item {
        case .rabbit: (11, 84, 11)
        case .daisy: (22, 89, 8)
        case .mushroom: (31, 88, 8)
        case .pebble: (57, 93, 6)
        case .ladybug: (66, 92, 6)
        case .squirrel: (74, 85, 10)
        case .deer: (88, 81, 14)
        case .lantern: (88, 58, 8)
        case .firefly: (15, 46, 8)
        case .butterfly: (83, 30, 9)
        case .bird: (34, 10, 8)
        case .nest: hasBranches ? (62, 40, 10) : (40, 90, 7)
        case .owl: hasBranches ? (38, 42, 10) : (44, 86, 9)
        default: nil
        }
    }
}

/// 내 나무 뒤의 하늘.
struct SkyBackdrop: View {
    let sky: GardenItem

    var body: some View {
        Canvas { context, size in
            let colors = Theme.skyColors(sky)
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(Gradient(colors: colors), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height))
            )
            let w = size.width, h = size.height
            switch sky {
            case .skyNight:
                let stars: [(Double, Double, Double)] = [
                    (0.12, 0.10, 2), (0.30, 0.22, 1.5), (0.48, 0.08, 2.5), (0.70, 0.16, 1.5),
                    (0.86, 0.30, 2), (0.20, 0.38, 1.5), (0.62, 0.34, 1.5), (0.92, 0.08, 1.5),
                ]
                for (x, y, r) in stars {
                    context.fill(Path(ellipseIn: CGRect(x: x * w - r, y: y * h - r, width: r * 2, height: r * 2)), with: .color(.white.opacity(0.85)))
                }
                context.fill(Path(ellipseIn: CGRect(x: w * 0.76, y: h * 0.07, width: w * 0.1, height: w * 0.1)), with: .color(Color(light: 0xF6EBC5, dark: 0xE9DDB0)))
            case .skySunset:
                context.fill(Path(ellipseIn: CGRect(x: w * 0.62, y: h * 0.48, width: w * 0.22, height: w * 0.22)), with: .color(Color(light: 0xF7A35C, dark: 0xC9774A).opacity(0.7)))
            case .skyRainbow:
                let bands = [0xE8786B, 0xF0B35E, 0xEFD86A, 0x86C77E, 0x6FA9D8, 0x9A88CF]
                let center = CGPoint(x: w * 0.5, y: h * 0.78)
                for (index, hex) in bands.enumerated() {
                    let radius = w * (0.46 - Double(index) * 0.035)
                    var arc = Path()
                    for step in 0...30 {
                        let angle = Double.pi + Double.pi * Double(step) / 30
                        let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
                        if step == 0 { arc.move(to: point) } else { arc.addLine(to: point) }
                    }
                    context.stroke(arc, with: .color(Color(uiColor: UIColor(hex: UInt32(hex))).opacity(0.45)), lineWidth: w * 0.03)
                }
            default:
                context.fill(Path(ellipseIn: CGRect(x: w * 0.74, y: h * 0.08, width: w * 0.13, height: w * 0.13)), with: .color(Color(light: 0xF6D77A, dark: 0xC9AE5C).opacity(0.8)))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

/// 나무를 톡 건드리면 잎이 몇 장 떨어진다.
struct FallingLeaves: View {
    let trigger: Int
    let emoji: String

    private struct Drop: Identifiable {
        let id = UUID()
        let x: Double
        let delay: Double
        let drift: Double
    }

    @State private var drops: [Drop] = []

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(drops) { drop in
                    FallingLeaf(emoji: emoji, delay: drop.delay, drift: drop.drift, distance: proxy.size.height * 0.5)
                        .position(x: drop.x * proxy.size.width, y: proxy.size.height * 0.3)
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in
            let fresh = (0..<3).map { _ in
                Drop(x: .random(in: 0.3...0.7), delay: .random(in: 0...0.25), drift: .random(in: -30...30))
            }
            drops.append(contentsOf: fresh)
            let ids = Set(fresh.map(\.id))
            Task {
                try? await Task.sleep(for: .seconds(2.2))
                drops.removeAll { ids.contains($0.id) }
            }
        }
    }
}

private struct FallingLeaf: View {
    let emoji: String
    let delay: Double
    let drift: Double
    let distance: Double
    @State private var fallen = false

    var body: some View {
        Text(emoji)
            .font(.system(size: 18))
            .rotationEffect(.degrees(fallen ? drift * 4 : 0))
            .offset(x: fallen ? drift : 0, y: fallen ? distance : 0)
            .opacity(fallen ? 0 : 1)
            .onAppear {
                withAnimation(.easeIn(duration: 1.6).delay(delay)) { fallen = true }
            }
    }
}

#Preview {
    ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
            ForEach(GrowthStage.allCases, id: \.self) { stage in
                VStack {
                    TreeView(stage: stage, isSwaying: stage == .tree)
                    Text(stage.title).font(.caption)
                }
            }
            TreeView(stage: .tree, isWilting: true)
        }
        .padding()
    }
    .background(Theme.background)
}
