import SwiftUI
import ForestCore

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var confirmReset = false
    @State private var editingGoal = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("이름", value: model.treeName)
                } header: {
                    Text("숲에 보이는 것")
                } footer: {
                    Text("숲에는 이 이름과 나무 모습, 지금 참는 중인지만 보여요. 이름은 바꿀 수 없어요.")
                }

                Section {
                    LabeledContent("끊는 것", value: model.habit?.title ?? "")
                    LabeledContent("하루에 쓰던 돈") {
                        TextField("0", value: habitBinding(\.dailyCost, default: 0), format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    TextField("끊는 이유", text: habitBinding(\.reason, default: ""), axis: .vertical)
                } header: {
                    Text("이 폰에만 저장되는 것")
                } footer: {
                    Text("끊는 것, 날짜, 돈, 이유는 서버로 보내지 않아요. 우리도 당신이 무엇을 끊는지 몰라요.")
                }

                Section("목표") {
                    LabeledContent("지금 목표", value: model.habit?.goal?.title ?? "없음")
                    Button("목표 바꾸기") { editingGoal = true }
                }

                Section("위시리스트") {
                    TextField("갖고 싶은 것 (예: 운동화)", text: wishTitle)
                    LabeledContent("가격") {
                        TextField("0", value: wishPrice, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("배지") {
                    NavigationLink("받은 배지 보기") { MilestonesView() }
                }

                Section {
                    Button("처음부터 다시 시작", role: .destructive) { confirmReset = true }
                } footer: {
                    Text("기록이 모두 지워지고, 숲에서도 새 이름의 새 나무로 시작해요.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("설정")
            .sheet(isPresented: $editingGoal) {
                GoalSheet(reached: nil, cleanDays: model.habit?.totalCleanDays(at: Date()) ?? 0) { goal in
                    model.setGoal(goal)
                }
            }
            .confirmationDialog("모든 기록을 지울까요?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("지우고 다시 시작", role: .destructive) { model.resetEverything() }
                Button("취소", role: .cancel) {}
            }
        }
    }

    private func habitBinding<Value>(_ keyPath: WritableKeyPath<Habit, Value>, default fallback: Value) -> Binding<Value> {
        Binding(
            get: { model.habit?[keyPath: keyPath] ?? fallback },
            set: { value in model.updateHabit { $0[keyPath: keyPath] = value } }
        )
    }

    private var wishTitle: Binding<String> {
        Binding(
            get: { model.habit?.wish?.title ?? "" },
            set: { title in
                model.updateHabit { habit in
                    habit.wish = Wish(title: title, price: habit.wish?.price ?? 0)
                }
            }
        )
    }

    private var wishPrice: Binding<Int> {
        Binding(
            get: { model.habit?.wish?.price ?? 0 },
            set: { price in
                model.updateHabit { habit in
                    habit.wish = Wish(title: habit.wish?.title ?? "", price: max(0, price))
                }
            }
        )
    }
}

struct MilestonesView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let days = model.habit?.totalCleanDays(at: Date()) ?? 0
        List(Milestones.all) { milestone in
            let reached = milestone.days <= days
            HStack {
                Text(reached ? "🏅" : "⚪️")
                Text(milestone.title)
                Spacer()
                Text(reached ? "받음" : "\(milestone.days - days)일 남음")
                    .foregroundStyle(Theme.muted)
            }
            .opacity(reached ? 1 : 0.6)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("배지")
    }
}
