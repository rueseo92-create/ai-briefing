import SwiftUI
import TasteCore

/// 이번 주 체크인. 예산, 에너지, 시간, 함께. 지난번 답이 기본으로 잡혀 있다.
struct CheckInForm: View {
    @State var answer: CheckIn
    let isFirstThisWeek: Bool
    let onDone: (CheckIn) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            question("이번 주 얼마까지 쓸 수 있어요?", options: CheckIn.Budget.allCases, selection: $answer.budget, title: \.title)
            question("에너지는 어때요?", options: CheckIn.Energy.allCases, selection: $answer.energy, title: \.title)
            question("시간은요? (오가는 시간 포함)", options: CheckIn.TimeBudget.allCases, selection: $answer.time, title: \.title)
            question("누구와요?", options: CheckIn.Company.allCases, selection: $answer.company, title: \.title)

            Button {
                onDone(answer)
            } label: {
                Text(isFirstThisWeek ? "이걸로 실험 받기" : "바꾼 대로 맞추기")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            Text("답은 이 폰에만 남아요. 광고주는 내 예산을 알 수 없어요.")
                .font(.caption)
                .foregroundStyle(Theme.muted)
        }
    }

    private func question<Option: Hashable>(_ text: String, options: [Option], selection: Binding<Option>, title: KeyPath<Option, String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text).font(.subheadline.weight(.semibold))
            FlowChips(options: options, selection: selection, title: title)
        }
    }
}

/// 한 줄에 다 안 들어가면 줄을 바꾸는 선택 칩.
struct FlowChips<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: KeyPath<Option, String>

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { chips }
            VStack(alignment: .leading, spacing: 8) { chips }
        }
    }

    @ViewBuilder
    private var chips: some View {
        ForEach(options, id: \.self) { option in
            let chosen = option == selection
            Button {
                selection = option
            } label: {
                Text(option[keyPath: title])
                    .font(.callout)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(chosen ? Theme.accent.opacity(0.18) : Theme.card, in: Capsule())
                    .overlay(Capsule().stroke(chosen ? Theme.accent : Theme.muted.opacity(0.3), lineWidth: chosen ? 1.5 : 1))
                    .foregroundStyle(Theme.ink)
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(chosen ? .isSelected : [])
        }
    }
}

/// 체크인을 마친 뒤 이번 주 화면 위에 보이는 요약.
struct CheckInSummary: View {
    let checkIn: CheckIn
    let onEdit: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("이번 주").font(.caption.weight(.bold)).foregroundStyle(Theme.muted)
                Text([checkIn.budget.title, "에너지 " + checkIn.energy.title, checkIn.time.title, checkIn.company.title].joined(separator: " · "))
                    .font(.callout)
            }
            Spacer()
            Button("바꾸기", action: onEdit)
                .font(.callout)
        }
        .card()
    }
}
