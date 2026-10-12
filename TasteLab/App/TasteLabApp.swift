import SwiftUI
import TasteCore

@main
struct TasteLabApp: App {
    @State private var model = AppModel(
        offerService: AppConfig.cloudKitContainer.map { CloudKitOfferService(containerID: $0) as OfferService } ?? SampleOfferService(),
        backupService: AppConfig.cloudKitContainer.map { CloudKitBackup(containerID: $0) },
        metricsService: AppConfig.cloudKitContainer.map { CloudKitMetrics(containerID: $0) },
        reminderSink: LocalReminders(),
        weatherProvider: WeatherKitProvider(),
        placeSearcher: MapKitPlaceSearcher()
    )
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .tint(Theme.accent)
                .task { await model.appBecameActive() }
                .onOpenURL { url in model.pendingInvite = Invite(url: url) }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { Task { await model.appBecameActive() } }
                    if phase == .background { Task { await model.backupNow() } }
                }
        }
    }
}

struct RootView: View {
    enum Tab: Hashable {
        case box, week, weekend, me
    }

    @Environment(AppModel.self) private var model
    @State private var tab: Tab = .week

    var body: some View {
        if !model.saved.onboarded {
            OnboardingView()
        } else {
            TabView(selection: $tab) {
                PostcardBoxView()
                    .tabItem { Label("엽서함", systemImage: "rectangle.stack") }
                    .tag(Tab.box)
                ThisWeekView()
                    .tabItem { Label("이번 주", systemImage: "sparkles") }
                    .badge(model.needsCheckIn() ? Text("!") : nil)
                    .tag(Tab.week)
                WeekendView()
                    .tabItem { Label("주말", systemImage: "shippingbox") }
                    .tag(Tab.weekend)
                MeView()
                    .tabItem { Label("나", systemImage: "envelope") }
                    .tag(Tab.me)
            }
            .onAppear {
                // 체크인할 게 없고 엽서가 있으면 엽서함부터.
                if !model.needsCheckIn(), !model.postcards.isEmpty { tab = .box }
            }
            .sheet(isPresented: Binding(get: { model.pendingInvite != nil }, set: { if !$0 { model.pendingInvite = nil } })) {
                if let invite = model.pendingInvite {
                    InviteSheet(invite: invite) { tab = .week }
                }
            }
        }
    }
}
