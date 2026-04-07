import SwiftUI

/// Primary navigation: Home (planning), Achievements, Settings.
struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
            .tabItem {
                Label("Plan", systemImage: "figure.walk")
            }

            NavigationStack {
                AchievementsView()
            }
            .tabItem {
                Label("Achievements", systemImage: "trophy")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppDependencies.preview)
}
