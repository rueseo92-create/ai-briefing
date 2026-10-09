import SwiftUI
import ForestCore

/// 목표 고르기: 7일, 30일, 70일, 100일, 1년, 평생, 직접 입력.
struct GoalPicker: View {
    @Binding var selection: Goal?
    /// 지금까지 참은 날. 이미 넘긴 목표는 고를 수 없다.
    let cleanDays: Int

    @State private var customText = ""

    private var customDays: Int? { Int(customText.filter(\.isNumber)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                ForEach(Goal.choices(cleanDays: cleanDays), id: \.self) { goal in
                    Button {
                        selection = goal
                        customText = ""
                    } label: {
                        Text(goal.title)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(selection == goal ? Theme.leaf.opacity(0.18) : Theme.card)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(selection == goal ? Theme.leaf : .clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack {
                Text("직접 입력")
                TextField("예: 50", text: $customText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                Text("일")
            }
            if let days = customDays, days <= cleanDays {
                Text("지금까지 참은 날(\(cleanDays)일)보다 길게 정해 주세요.")
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
            }
        }
        .onChange(of: customText) { _, _ in
            guard let days = customDays else { return }
            let goal = Goal.custom(days)
            if let target = goal.targetDays, target > cleanDays {
                selection = goal
            }
        }
    }
}

/// 목표를 달성했을 때, 또는 설정에서 목표를 바꿀 때 뜨는 화면.
struct GoalSheet: View {
    /// 방금 달성한 목표. nil이면 그냥 목표 바꾸기.
    let reached: Goal?
    let cleanDays: Int
    let onSelect: (Goal) -> Void

    @State private var selection: Goal?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let reached {
                        Text("🎯").font(.system(size: 56))
                        Text("\(reached.title) 목표 달성!")
                            .font(.largeTitle.bold())
                        Text("나무는 계속 자라요. 다음 목표를 정해 볼까요?")
                            .foregroundStyle(Theme.muted)
                    } else {
                        Text("목표 바꾸기")
                            .font(.title.bold())
                        Text("지금까지 참은 날 \(cleanDays)일. 다시 해도 목표는 그대로예요.")
                            .foregroundStyle(Theme.muted)
                    }
                    GoalPicker(selection: $selection, cleanDays: cleanDays)
                }
                .padding(24)
            }
            .background(Theme.background.ignoresSafeArea())
            .foregroundStyle(Theme.ink)
            .safeAreaInset(edge: .bottom) {
                Button {
                    if let selection { onSelect(selection) }
                    dismiss()
                } label: {
                    Text("이 목표로").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selection == nil)
                .padding(20)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("나중에") { dismiss() }
                }
            }
        }
    }
}

/// 내 나무 화면의 목표 카드.
struct GoalCard: View {
    let goal: Goal
    let cleanDays: Int
    let onChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("🎯 목표 \(goal.title)").font(.headline)
                Spacer()
                if let target = goal.targetDays {
                    Text("\(min(cleanDays, target)) / \(target)일")
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(Theme.muted)
                }
            }
            if let progress = goal.progress(cleanDays: cleanDays) {
                ProgressView(value: progress).tint(Theme.leaf)
            }
            HStack {
                Text(caption)
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)
                Spacer()
                Button(goal.isReached(cleanDays: cleanDays) ? "다음 목표" : "바꾸기", action: onChange)
                    .font(.footnote.weight(.semibold))
            }
        }
        .card()
    }

    private var caption: String {
        if goal.isReached(cleanDays: cleanDays) {
            return "달성했어요!"
        }
        if let remaining = goal.remaining(cleanDays: cleanDays) {
            return "\(remaining)일 남음"
        }
        if let next = Milestones.next(cleanDays: cleanDays) {
            return "다음 이정표 \(next.title)까지 \(next.days - cleanDays)일"
        }
        return "모든 이정표를 지났어요. 계속 걸어요"
    }
}
