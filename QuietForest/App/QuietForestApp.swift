import SwiftUI

@main
struct QuietForestApp: App {
    @State private var model = AppModel(service: AppConfig.makeService())
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .tint(Theme.leaf)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { model.appBecameActive() }
                }
        }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if model.habit == nil {
            OnboardingView()
        } else {
            TabView {
                HomeView()
                    .tabItem { Label("내 나무", systemImage: "leaf") }
                ForestView()
                    .tabItem { Label("숲", systemImage: "tree") }
                SettingsView()
                    .tabItem { Label("설정", systemImage: "gearshape") }
            }
        }
    }
}
