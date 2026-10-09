import SwiftUI
import ForestCore

/// 내 나무 꾸미기. 숲에는 보이지 않고 나만 본다.
struct GardenView: View {
    @Environment(AppModel.self) private var model
    @State private var poke = 0
    @State private var isFull = false
    /// 들어올 때 새로 생겨 있던 것. 나갈 때 본 것으로 친다.
    @State private var unseen: Set<GardenItem> = []

    private let columns = [GridItem(.adaptive(minimum: 84), spacing: 10)]

    var body: some View {
        let garden = model.garden
        let habit = model.habit
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                TreeView(
                    stage: habit?.stage(at: Date()) ?? .seed,
                    isWilting: habit?.isWilting(at: Date()) ?? false,
                    style: garden.style,
                    showsSky: true,
                    poke: poke
                )
                .frame(height: 260)
                .frame(maxWidth: .infinity)

                Text("한 번 생긴 것은 사라지지 않아요. 잎 색과 장식은 숲에서도 보이고, 하늘은 나만 봐요.")
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)

                ForEach(GardenCategory.allCases, id: \.self) { category in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(category.title).font(.headline)
                            Spacer()
                            if category == .decoration {
                                Text("\(garden.style.decorations.count)/\(GardenStyle.maxDecorations)")
                                    .font(.footnote.monospacedDigit())
                                    .foregroundStyle(Theme.muted)
                            }
                        }
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(GardenItem.items(in: category)) { item in
                                tile(item, garden: garden)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .foregroundStyle(Theme.ink)
        .navigationTitle("꾸미기")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.selection, trigger: poke)
        .alert("장식은 \(GardenStyle.maxDecorations)개까지 달 수 있어요", isPresented: $isFull) {
            Button("알겠어요", role: .cancel) {}
        } message: {
            Text("하나를 떼고 달아 봐요.")
        }
        .onAppear { unseen = Set(garden.unseen) }
        .onDisappear { model.finishGardening() }
    }

    private func tile(_ item: GardenItem, garden: GardenCollection) -> some View {
        let owned = garden.unlocked.contains(item)
        let using = garden.style.isUsing(item)
        return Button {
            if model.toggleGarden(item) {
                poke += 1
            } else if owned {
                isFull = true
            }
        } label: {
            VStack(spacing: 4) {
                Text(owned ? item.emoji : "🔒").font(.system(size: 30))
                Text(item.title).font(.caption.weight(.medium))
                if !owned {
                    Text(item.unlock.hint)
                        .font(.caption2)
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 86)
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(using ? Theme.leaf.opacity(0.18) : Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(using ? Theme.leaf : .clear, lineWidth: 2)
            )
            .overlay(alignment: .topTrailing) {
                if unseen.contains(item) {
                    Text("새로")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.blossom, in: Capsule())
                        .foregroundStyle(.white)
                        .padding(4)
                }
            }
            .opacity(owned ? 1 : 0.55)
        }
        .buttonStyle(.plain)
        .disabled(!owned)
        .accessibilityLabel(owned ? item.title : "\(item.title), \(item.unlock.hint) 생겨요")
        .accessibilityAddTraits(using ? .isSelected : [])
    }
}

/// 새 장식이 생겼을 때 내 나무 화면 위에 잠깐 뜬다.
struct GardenToast: View {
    let items: [GardenItem]

    var body: some View {
        HStack(spacing: 10) {
            Text(items.prefix(4).map(\.emoji).joined())
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(items.count == 1 ? "새로 생겼어요: \(items[0].title)" : "꾸밀 것이 \(items.count)개 생겼어요")
                    .font(.callout.weight(.semibold))
                Text("눌러서 꾸며 봐요").font(.caption).foregroundStyle(Theme.muted)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.card, in: Capsule())
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
    }
}
