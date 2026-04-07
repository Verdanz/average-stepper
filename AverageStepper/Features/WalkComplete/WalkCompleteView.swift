import SwiftUI

struct WalkCompleteView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Binding var path: [HomeStack]
    /// Called after the session is cleared (e.g. dismiss resume `fullScreenCover`).
    var onBackToHome: (() -> Void)? = nil
    @State private var model: WalkCompleteViewModel?

    var body: some View {
        Group {
            if let model {
                content(model: model)
            } else {
                ProgressView()
                    .onAppear {
                        model = WalkCompleteViewModel(session: dependencies.walkSessionManager.session, dependencies: dependencies)
                    }
            }
        }
        .navigationTitle("Nice walk!")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func content(model: WalkCompleteViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
                ASCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("You wrapped a walk")
                            .font(Theme.title)
                        Text(reasonText(for: model.session))
                            .font(Theme.body)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 12) {
                    MetricCard(
                        title: "Steps",
                        value: Formatting.steps(model.session.liveSteps),
                        subtitle: "Goal \(Formatting.steps(model.session.goal.targetSteps))"
                    )
                    MetricCard(
                        title: "Distance",
                        value: Formatting.distance(model.session.liveDistanceMeters, units: dependencies.preferences.units),
                        subtitle: "Session total"
                    )
                }

                if !model.newAchievements.isEmpty {
                    ASCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New achievements")
                                .font(Theme.headline)
                            ForEach(model.newAchievements) { achievement in
                                Label(achievement.badge.title, systemImage: achievement.badge.systemImageName ?? "star.fill")
                                    .font(Theme.body)
                            }
                        }
                    }
                } else {
                    ASCard {
                        Text("Keep walking to unlock streaks and milestone badges.")
                            .font(Theme.body)
                            .foregroundStyle(.secondary)
                    }
                }

                PrimaryButton("Back to home", systemImage: "house.fill") {
                    dependencies.walkSessionManager.resetIdle()
                    path = []
                    onBackToHome?()
                }
            }
            .padding()
            .frame(maxWidth: Theme.contentMaxWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func reasonText(for session: WalkSession) -> String {
        switch session.completionReason {
        case .reachedStepGoal:
            return "You hit your step target. Great pacing."
        case .routeCompleted:
            return "You covered the planned route. Nice work staying on track."
        case .userEnded:
            return "You ended the session early — progress still counts."
        case .aborted:
            return "Session ended."
        case .none:
            return "Session complete."
        }
    }
}

#Preview {
    NavigationStack {
        WalkCompleteView(path: .constant([.walkComplete]))
            .environment(AppDependencies.preview)
    }
}
