import SwiftUI
import TasteCore

/// 이번 주 체크인과 실험 세 장.
struct ThisWeekView: View {
    @Environment(AppModel.self) private var model
    @State private var showSettings = false
    @State private var editingCheckIn = false
    @State private var swapping: Pick?
    @State private var path: [Experiment] = []
    @State private var working: String?
    @State private var showMap = false
    @State private var locationService = LocationService()

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if model.needsCheckIn() {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("이번 주 어때요?").font(.title2.bold())
                            Text("답에 맞춰 실험 세 장을 골라 드려요.").foregroundStyle(Theme.muted)
                        }
                        CheckInForm(answer: model.checkIn, isFirstThisWeek: true) { answer in
                            Task { await submit(answer) }
                        }
                        .card()
                    } else {
                        CheckInSummary(checkIn: model.checkIn, weather: model.weather) { editingCheckIn = true }

                        if model.shouldAskReminders {
                            ReminderPrompt()
                        }

                        ForEach(model.picks) { pick in
                            // 카드 안의 "다른 걸로" 버튼이 먼저 눌리게, 링크 대신 탭으로 연다.
                            PickCard(pick: pick, entry: model.entry(for: pick.experiment)) {
                                swapping = pick
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { path.append(pick.experiment) }
                            .accessibilityAddTraits(.isButton)
                        }

                        if model.picks.isEmpty {
                            Text("이번 답에 맞는 실험이 없어요. 예산이나 시간을 조금 넓혀 볼까요?")
                                .foregroundStyle(Theme.muted)
                                .card()
                        }

                        if model.allPicksDone {
                            VStack(spacing: 10) {
                                Text("이번 주 엽서를 다 모았어요 🎉").font(.headline)
                                Button("처음 가 보는 쪽에서 한 장 더") {
                                    withAnimation { model.addOneMore() }
                                }
                                .buttonStyle(.bordered)
                            }
                            .frame(maxWidth: .infinity)
                            .card()
                        }
                    }
                }
                .padding(20)
            }
            .overlay {
                if let working { ProgressView(working).padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12)) }
            }
            .background(Theme.background.ignoresSafeArea())
            .foregroundStyle(Theme.ink)
            .navigationTitle("이번 주")
            .navigationDestination(for: Experiment.self) { ExperimentDetailView(experiment: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showMap = true } label: { Image(systemName: "map") }
                        .accessibilityLabel("동네 지도")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("설정")
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showMap) { NavigationStack { NeighborhoodMapView() } }
            .sheet(isPresented: $editingCheckIn) {
                NavigationStack {
                    ScrollView {
                        CheckInForm(answer: model.checkIn, isFirstThisWeek: false) { answer in
                            editingCheckIn = false
                            Task { await submit(answer) }
                        }
                        .padding(20)
                    }
                    .navigationTitle("이번 주 바꾸기")
                    .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.large])
            }
            .confirmationDialog("왜 바꿀까요?", isPresented: Binding(get: { swapping != nil }, set: { if !$0 { swapping = nil } }), titleVisibility: .visible, presenting: swapping) { pick in
                ForEach(SwapReason.allCases, id: \.self) { reason in
                    Button(reason.title) { withAnimation { model.swap(pick, reason: reason) } }
                }
                Button("그냥 바꿀래요") { withAnimation { model.swap(pick, reason: nil) } }
                Button("취소", role: .cancel) {}
            } message: { _ in
                Text("이유를 알려 주면 다음 실험이 더 잘 맞아요. '돈이 들어서'를 고르면 이번 주 예산도 한 칸 낮춰요.")
            }
            .task { model.refreshWeekIfNeeded() }
        }
    }

    /// 대략적 위치를 쓰기로 했으면 실험을 받기 직전에만 위치를 묻는다.
    private func submit(_ answer: CheckIn) async {
        if model.location.kind == .approximate {
            working = "위치를 대략 확인하는 중"
            if let coordinate = await locationService.requestApproximate() {
                model.updateApproximateLocation(coordinate)
            }
        }
        // 공원, 한강, 도서관 같은 곳이 동네에 실제로 있는지(한 달에 한 번)와 이번 주 날씨를 확인한다.
        if model.location.origin != nil {
            working = model.placeSearchOrigin() != nil ? "동네 지도와 날씨를 확인하는 중" : "이번 주 날씨를 확인하는 중"
            await model.prepareWeek()
        }
        working = nil
        withAnimation { model.checkIn(answer) }
    }
}

struct PickCard: View {
    let pick: Pick
    let entry: Entry?
    let onSwap: () -> Void

    var body: some View {
        let experiment = pick.experiment
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Chip(text: pick.slot.title, color: Theme.slotColor(pick.slot))
                if experiment.isSponsored { Chip(text: "광고", color: Theme.ad) }
                if experiment.kit != nil { Chip(text: "키트", color: Theme.kit) }
                Spacer()
                Text("\(experiment.domain.emoji) \(experiment.domain.stampName)")
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
            }
            Text(experiment.title)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.leading)
            Text(pick.reason)
                .font(.footnote)
                .foregroundStyle(Theme.muted)
            VStack(alignment: .leading, spacing: 4) {
                if let venue = pick.venue {
                    Label(venue.name, systemImage: "mappin.and.ellipse")
                }
                Label(Formats.time(minutes: experiment.minutes, travel: pick.travelMinutes), systemImage: "clock")
                Label(Formats.cost(experiment.effectiveCost), systemImage: "wonsign.circle")
                if let note = pick.weatherNote {
                    Label(note, systemImage: "cloud.sun")
                }
            }
            .font(.caption)
            .foregroundStyle(Theme.muted)
            HStack {
                Spacer()
                if let entry {
                    Text("💌 엽서 완성 · \(entry.feeling.title)")
                        .font(.footnote.weight(.semibold))
                } else {
                    Button("다른 걸로", action: onSwap)
                        .font(.footnote)
                        .buttonStyle(.bordered)
                }
            }
        }
        .card()
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Theme.slotColor(pick.slot).opacity(entry == nil ? 0.35 : 0), lineWidth: 1.5)
        )
        .opacity(entry == nil ? 1 : 0.75)
    }
}
