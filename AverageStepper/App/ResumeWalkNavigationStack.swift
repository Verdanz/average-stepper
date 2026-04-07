import SwiftUI

/// Full-screen resume flow after relaunch: active walk → completion without losing the cover mid-session.
struct ResumeWalkNavigationStack: View {
    @Environment(\.dismiss) private var dismiss
    @State private var path: [HomeStack] = []

    var body: some View {
        NavigationStack(path: $path) {
            ActiveWalkView(path: $path)
                .navigationDestination(for: HomeStack.self) { destination in
                    switch destination {
                    case .walkComplete:
                        WalkCompleteView(path: $path, onBackToHome: { dismiss() })
                    case .routePreview, .activeWalk:
                        EmptyView()
                    }
                }
        }
    }
}
