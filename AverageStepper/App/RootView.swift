import SwiftUI

/// Chooses onboarding vs main shell; holds `AppDependencies` in the environment.
struct RootView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var resumeWalkPresented = false

    var body: some View {
        Group {
            if dependencies.preferences.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .animation(.easeInOut, value: dependencies.preferences.hasCompletedOnboarding)
        .onAppear {
            if dependencies.walkSessionManager.needsResumeWalkPresentation {
                resumeWalkPresented = true
            }
        }
        .onChange(of: dependencies.walkSessionManager.needsResumeWalkPresentation) { _, shouldOfferResume in
            if shouldOfferResume {
                resumeWalkPresented = true
            }
        }
        .fullScreenCover(isPresented: $resumeWalkPresented) {
            ResumeWalkNavigationStack()
                .environment(dependencies)
                .onDisappear {
                    dependencies.walkSessionManager.acknowledgeResumePresentation()
                }
        }
    }
}

#Preview {
    RootView()
        .environment(AppDependencies.preview)
}
