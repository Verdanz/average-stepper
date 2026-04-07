import SwiftUI

struct WalkCompleteView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
        .navigationTitle("Walk complete")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func content(model: WalkCompleteViewModel) -> some View {
        ZStack(alignment: .top) {
            if dependencies.preferences.celebratoryAnimationsEnabled, !reduceMotion {
                CelebrationConfettiView()
                    .frame(height: 160)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
                    ASCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Nice work")
                                .font(Theme.title)
                            Text(reasonText(for: model.session))
                                .font(Theme.body)
                                .foregroundStyle(.secondary)
                            Text(model.encouragement)
                                .font(Theme.body)
                                .foregroundStyle(.primary)
                                .padding(.top, 4)
                        }
                    }

                    HStack(spacing: 12) {
                        MetricCard(
                            title: "This walk",
                            value: Formatting.steps(model.session.liveSteps),
                            subtitle: "Estimated steps"
                        )
                        MetricCard(
                            title: "Distance",
                            value: Formatting.distance(model.session.liveDistanceMeters, units: dependencies.preferences.units),
                            subtitle: "Session total"
                        )
                    }

                    streakCard(model: model)

                    lifetimeTotalsCard(model: model)

                    if !model.newAchievements.isEmpty {
                        ASCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Earned")
                                    .font(Theme.headline)
                                ForEach(model.newAchievements) { achievement in
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: achievement.badge.systemImageName ?? "star.fill")
                                            .font(.title2)
                                            .foregroundStyle(Theme.Colors.accent)
                                            .frame(width: 28, alignment: .center)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(achievement.badge.title)
                                                .font(Theme.body.weight(.semibold))
                                            Text(achievement.badge.detail)
                                                .font(Theme.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    PrimaryButton("Plan next walk", systemImage: "house.fill") {
                        dependencies.walkSessionManager.resetIdle()
                        path = []
                        onBackToHome?()
                    }
                }
                .padding()
                .frame(maxWidth: Theme.contentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.top, dependencies.preferences.celebratoryAnimationsEnabled && !reduceMotion ? 120 : 16)
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    private func streakCard(model: WalkCompleteViewModel) -> some View {
        ASCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Streak")
                    .font(Theme.headline)
                HStack(spacing: 12) {
                    streakPill(title: "Current", value: "\(model.streakAfter)", highlight: model.streakAfter > model.streakBefore)
                    streakPill(title: "Best streak", value: "\(model.longestStreak)", highlight: false)
                }
                if model.streakAfter > model.streakBefore {
                    Text("Consecutive days with a completed walk — keep the chain going.")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.Colors.muted)
                }
            }
        }
    }

    private func streakPill(title: String, value: String, highlight: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(Theme.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(Theme.metric)
                .foregroundStyle(highlight ? Theme.Colors.accent : .primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func lifetimeTotalsCard(model: WalkCompleteViewModel) -> some View {
        ASCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("All-time")
                    .font(Theme.headline)
                LabeledContent("Completed walks") {
                    Text("\(model.lifetimeTotals.totalCompletedWalks)")
                }
                LabeledContent("Estimated steps") {
                    Text(Formatting.steps(model.lifetimeTotals.totalEstimatedSteps))
                }
                LabeledContent("Distance") {
                    Text(Formatting.distance(model.lifetimeTotals.totalDistanceMeters, units: dependencies.preferences.units))
                }
            }
            .font(Theme.body)
        }
    }

    private func reasonText(for session: WalkSession) -> String {
        switch session.completionReason {
        case .reachedStepGoal:
            return "You hit your step target."
        case .routeCompleted:
            return "You covered your planned route."
        case .userEnded:
            return "Session saved — you stopped when it was right for you."
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
