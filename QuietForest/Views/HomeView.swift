import SwiftUI
import ForestCore

struct HomeView: View {
    @Environment(AppModel.self) private var model
    @State private var confirmSlip = false
    @State private var editingGoal = false
    @State private var showGarden = false
    @State private var poke = 0

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            ScrollView {
                if let habit = model.habit {
                    TimelineView(.periodic(from: .now, by: 1)) { timeline in
                        content(habit: habit, now: timeline.date)
                    }
                    .padding(20)
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .foregroundStyle(Theme.ink)
            .navigationTitle("내 나무")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showGarden = true } label: {
                        Image(systemName: "paintpalette")
                            .overlay(alignment: .topTrailing) {
                                if !model.garden.unseen.isEmpty {
                                    Circle().fill(Theme.blossom).frame(width: 8, height: 8).offset(x: 4, y: -3)
                                }
                            }
                    }
                    .accessibilityLabel("꾸미기")
                }
            }
            .navigationDestination(isPresented: $showGarden) { GardenView() }
            .overlay(alignment: .top) {
                if let items = model.newGardenItems, !items.isEmpty {
                    GardenToast(items: items)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onTapGesture {
                            model.newGardenItems = nil
                            showGarden = true
                        }
                }
            }
            .animation(.spring(duration: 0.4), value: model.newGardenItems)
            .task(id: model.newGardenItems) {
                guard model.newGardenItems != nil else { return }
                try? await Task.sleep(for: .seconds(5))
                if !Task.isCancelled { model.newGardenItems = nil }
            }
            .safeAreaInset(edge: .bottom) { actions }
            .confirmationDialog("다시 했나요?", isPresented: $confirmSlip, titleVisibility: .visible) {
                Button("네, 다시 했어요") { model.recordSlip() }
                Button("아니요", role: .cancel) {}
            } message: {
                Text("괜찮아요. 나무는 하루 동안 시들었다가 다시 자라요. 지금까지 참은 날은 하루만 빠져요.")
            }
            .fullScreenCover(isPresented: Binding(
                get: { model.urge != nil },
                set: { if !$0 { model.endUrge(succeeded: false) } }
            )) {
                UrgeView()
            }
            .sheet(item: $model.newMilestone) { milestone in
                MilestoneSheet(milestone: milestone)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: Binding(
                get: { editingGoal || model.reachedGoal != nil },
                set: { if !$0 { editingGoal = false; model.reachedGoal = nil } }
            )) {
                GoalSheet(reached: model.reachedGoal, cleanDays: model.habit?.totalCleanDays(at: Date()) ?? 0) { goal in
                    model.setGoal(goal)
                }
            }
            .task { model.checkProgress() }
            .onChange(of: model.incomingCheers) { _, count in
                // 참는 중이 아닐 때 온 물방울은 "오늘 받은 물"에만 쌓는다.
                if count != nil, model.urge == nil { model.incomingCheers = nil }
            }
        }
    }

    @ViewBuilder
    private func content(habit: Habit, now: Date) -> some View {
        let stage = habit.stage(at: now)
        let streak = Format.elapsed(habit.currentStreak(at: now))
        let saved = habit.moneySaved(at: now)

        VStack(spacing: 20) {
            VStack(spacing: 6) {
                TreeView(stage: stage, isWilting: habit.isWilting(at: now), style: model.garden.style, showsSky: true, poke: poke)
                    .frame(height: 240)
                    .overlay {
                        if stage > .seed {
                            FallingLeaves(trigger: poke, emoji: Theme.fallingLeaf(model.garden.style.leaf))
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { poke += 1 }
                    .sensoryFeedback(.impact(weight: .light), trigger: poke)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityHint("톡 건드리면 나무가 흔들려요")
                Text(model.treeName)
                    .font(.title3.weight(.semibold))
                Text(stageCaption(habit: habit, stage: stage, now: now))
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)
            }

            VStack(spacing: 4) {
                Text("\(habit.title) 끊은 지")
                    .foregroundStyle(Theme.muted)
                Text("\(streak.days)일")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                Text(streak.clock)
                    .font(.title2.monospacedDigit())
                    .foregroundStyle(Theme.muted)
            }
            .frame(maxWidth: .infinity)
            .card()

            if model.shouldAskReminders {
                ReminderPrompt()
            }

            if let goal = habit.goal {
                GoalCard(goal: goal, cleanDays: habit.totalCleanDays(at: now)) { editingGoal = true }
            } else {
                Button("🎯 목표 정하기") { editingGoal = true }
                    .frame(maxWidth: .infinity)
                    .card()
            }

            HStack(spacing: 12) {
                stat(title: "지금까지 참은 날", value: "\(habit.totalCleanDays(at: now))일")
                stat(title: "버텨 낸 순간", value: "\(habit.urgeWins)번")
            }
            HStack(spacing: 12) {
                stat(title: "아낀 돈", value: habit.dailyCost > 0 ? Format.won(saved) : "—")
                stat(title: "오늘 받은 물", value: "💧 \(model.receivedToday(at: now))")
            }

            if let wish = habit.wish, wish.price > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("🎁 \(wish.title)").font(.headline)
                    ProgressView(value: wish.progress(saved: saved))
                        .tint(Theme.leaf)
                    Text("\(Format.won(saved)) / \(Format.won(wish.price))")
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(Theme.muted)
                }
                .card()
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 8) {
            Button {
                model.startUrge()
            } label: {
                Label("참기", systemImage: "hand.raised")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            Button("다시 했어요") { confirmSlip = true }
                .font(.footnote)
                .foregroundStyle(Theme.muted)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private func stat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(Theme.muted)
            Text(value).font(.title3.weight(.semibold)).monospacedDigit()
        }
        .card()
    }

    private func stageCaption(habit: Habit, stage: GrowthStage, now: Date) -> String {
        if habit.isWilting(at: now) {
            return "잠깐 시들었어요. 내일이면 다시 기운을 차려요"
        }
        guard let next = stage.next else { return stage.title }
        let left = next.requiredDays - habit.totalCleanDays(at: now)
        return "\(stage.title) · \(left)일 더 참으면 \(next.title)"
    }
}

/// 처음 한 번만 알림을 켤지 묻는다. 시스템 권한 창은 "켜기"를 누른 뒤에만 띄운다.
struct ReminderPrompt: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("🔔 나무가 자랄 때 알려 드릴까요?").font(.headline)
            Text("잠금 화면에는 무엇을 끊는지 나오지 않아요. 밤에는 울리지 않아요.")
                .font(.footnote)
                .foregroundStyle(Theme.muted)
            HStack {
                Button("켜기") { Task { await model.setReminders(true) } }
                    .buttonStyle(.borderedProminent)
                Button("괜찮아요") { Task { await model.setReminders(false) } }
                    .foregroundStyle(Theme.muted)
            }
        }
        .card()
    }
}

struct MilestoneSheet: View {
    let milestone: Milestone
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("🎉").font(.system(size: 64))
            Text(milestone.title).font(.largeTitle.bold())
            Text("지금까지 \(milestone.days)일을 참았어요. 이 배지는 사라지지 않아요.")
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.muted)
            Button("고마워요") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
        .padding(32)
    }
}
