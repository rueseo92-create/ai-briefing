import SwiftUI

@main
struct TasteLabApp: App {
    @State private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .tint(Theme.accent)
                .task { await model.appBecameActive() }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { Task { await model.appBecameActive() } }
                }
        }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if !model.saved.onboarded {
            OnboardingView()
        } else {
            TabView {
                ThisWeekView()
                    .tabItem { Label("이번 주", systemImage: "flask") }
                WeekendView()
                    .tabItem { Label("주말", systemImage: "shippingbox") }
                MapView()
                    .tabItem { Label("취향 지도", systemImage: "map") }
                JournalView()
                    .tabItem { Label("기록", systemImage: "book.closed") }
            }
        }
    }
}
