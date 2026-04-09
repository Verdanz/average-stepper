import SwiftUI

struct HomeView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var path: [HomeStack] = []
    @State private var model: HomeViewModel?

    var body: some View {
        Group {
            if let model {
                NavigationStack(path: $path) {
                    HomePlanView(model: model, path: $path)
                        .navigationDestination(for: HomeStack.self) { destination in
                            switch destination {
                            case .routePreview(let route):
                                RoutePreviewView(path: $path, route: route)
                            case .activeWalk:
                                ActiveWalkView(path: $path)
                            case .walkComplete:
                                WalkCompleteView(path: $path)
                            }
                        }
                }
                .navigationTitle("Plan a walk")
                .navigationBarTitleDisplayMode(.large)
                .animation(.easeInOut(duration: 0.2), value: path.count)
            } else {
                ProgressView("Loading…")
                    .accessibilityLabel("Loading plan screen")
                    .onAppear {
                        model = HomeViewModel(
                            routeService: dependencies.routeGenerationService,
                            locationService: dependencies.locationService,
                            preferences: dependencies.preferences,
                            stepEstimator: dependencies.stepEstimator,
                            walkSession: dependencies.walkSessionManager
                        )
                    }
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(AppDependencies.preview)
}
