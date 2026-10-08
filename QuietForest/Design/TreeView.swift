import SwiftUI
import ForestCore

/// 성장 단계에 따라 그리는 나무. 100×100 격자 위에 그린 뒤 크기에 맞춰 늘린다.
struct TreeView: View {
    var stage: GrowthStage
    var isWilting = false
    /// 참는 중인 나무는 바람에 흔들린다.
    var isSwaying = false

    var body: some View {
        TimelineView(.animation(paused: !isSwaying)) { timeline in
            let angle = isSwaying ? sin(timeline.date.timeIntervalSinceReferenceDate * 3) * 4 : 0
            Canvas { context, size in
                draw(in: &context, size: size)
            }
            .rotationEffect(.degrees(angle), anchor: .bottom)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel(isWilting ? "\(stage.title), 잠깐 시든 상태" : stage.title)
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

        let leaf = isWilting ? Theme.wilt : Theme.leaf
        let leafDeep = isWilting ? Theme.wilt.opacity(0.8) : Theme.leafDeep
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
                let color = stage == .blossom ? Theme.blossom : Theme.fruit
                let dot: Double = stage == .blossom ? 4 : 5
                for (x, y) in dots {
                    oval(x, y + droop, dot, dot, color)
                }
            }
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
