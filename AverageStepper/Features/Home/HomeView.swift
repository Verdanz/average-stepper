import SwiftUI

struct HomeView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var path: [HomeStack] = []
    @State private var model: HomeViewModel?

    var body: some View {
        Group {
            if let model {
                NavigationStack(path: $path) {
                    HomePlanBody(model: model, path: $path)
                        .navigationDestination(for: HomeStack.self) { destination in
                            switch destination {
                            case .routePreview(let route):
                                RoutePreviewView(route: route, path: $path)
                            case .activeWalk:
                                ActiveWalkView(path: $path)
                            case .walkComplete:
                                WalkCompleteView(path: $path)
                            }
                        }
                }
                .navigationTitle("Plan a walk")
                .navigationBarTitleDisplayMode(.large)
            } else {
                ProgressView()
                    .onAppear {
                        model = HomeViewModel(
                            routeService: dependencies.routeGenerationService,
                            locationService: dependencies.locationService,
                            preferences: dependencies.preferences,
                            stepEstimator: dependencies.stepEstimator
                        )
                    }
            }
        }
    }
}

private struct HomePlanBody: View {
    @Environment(AppDependencies.self) private var dependencies
    @Bindable var model: HomeViewModel
    @Binding var path: [HomeStack]

    var body: some View {
        @Bindable var walk = dependencies.walkSessionManager
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
                if walk.session.status == .active {
                    ASCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Walk in progress")
                                .font(Theme.headline)
                            Text("You have an active session. Continue tracking or end it from the walk screen.")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.Colors.muted)
                            PrimaryButton("Continue walk", systemImage: "location.fill") {
                                path.append(.activeWalk)
                            }
                        }
                    }
                }

                ASCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target steps")
                            .font(Theme.headline)
                        Stepper(value: $model.targetSteps, in: 1000...20_000, step: 500) {
                            Text("\(model.targetSteps) steps")
                                .font(Theme.body)
                                .accessibilityLabel("Target steps \(model.targetSteps)")
                        }
                        Text("Quick picks")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.Colors.muted)
                        HStack {
                            ForEach([3000, 5000, 8000, 10_000], id: \.self) { value in
                                Button("\(value / 1000)k") {
                                    model.targetSteps = value
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }

                HStack(spacing: 12) {
                    MetricCard(
                        title: "Est. distance",
                        value: Formatting.distance(model.estimatedDistanceMeters(), units: dependencies.preferences.units),
                        subtitle: "Stride \(Int(dependencies.preferences.strideMeters * 100)) cm"
                    )
                    MetricCard(
                        title: "Est. time",
                        value: Formatting.duration(model.estimatedWalkDuration()),
                        subtitle: "Walking pace"
                    )
                }
                .frame(maxWidth: .infinity)

                if let lastError = model.lastError {
                    ASCard {
                        Text(lastError)
                            .font(Theme.caption)
                            .foregroundStyle(.red)
                    }
                }

                PrimaryButton("Generate route", systemImage: "map") {
                    Task {
                        if let route = await model.generateRoute() {
                            path.append(.routePreview(route))
                        }
                    }
                }
                .disabled(model.isGenerating)

                if model.isGenerating {
                    ProgressView("Generating…")
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .frame(maxWidth: Theme.contentMaxWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    HomeView()
        .environment(AppDependencies.preview)
}
