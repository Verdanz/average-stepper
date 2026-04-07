import SwiftUI

struct AchievementsView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var model = AchievementsViewModel()

    private let columns = [GridItem(.adaptive(minimum: 156), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
                summarySection

                if let nudge = model.streakNudge {
                    ASCard {
                        Text(nudge)
                            .font(Theme.body)
                            .foregroundStyle(.secondary)
                    }
                }

                Text("Badges")
                    .font(Theme.headline)
                    .accessibilityAddTraits(.isHeader)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(model.achievements) { item in
                        badgeCell(item)
                    }
                }
            }
            .padding()
            .frame(maxWidth: Theme.contentMaxWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Achievements")
        .onAppear {
            model.reload(using: dependencies)
        }
        .onChange(of: dependencies.walkHistory.count) { _, _ in
            model.reload(using: dependencies)
        }
    }

    private var summarySection: some View {
        ASCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your progress")
                    .font(Theme.headline)
                HStack(spacing: 12) {
                    summaryTile(title: "Walks", value: "\(model.totals.totalCompletedWalks)")
                    summaryTile(title: "Streak", value: "\(model.streaks.current)d")
                    summaryTile(title: "Best", value: "\(model.streaks.longest)d")
                }
                Divider()
                LabeledContent("Estimated steps (all walks)") {
                    Text(Formatting.steps(model.totals.totalEstimatedSteps))
                }
                LabeledContent("Distance (all walks)") {
                    Text(Formatting.distance(model.totals.totalDistanceMeters, units: dependencies.preferences.units))
                }
            }
            .font(Theme.body)
        }
    }

    private func summaryTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(Theme.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(Theme.metric)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func badgeCell(_ item: Achievement) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: item.badge.systemImageName ?? "star.circle")
                    .font(.title2)
                    .foregroundStyle(item.isUnlocked ? Theme.Colors.accent : Theme.Colors.muted)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.badge.title)
                        .font(Theme.body.weight(.semibold))
                        .foregroundStyle(item.isUnlocked ? .primary : .secondary)
                    Text(item.badge.detail)
                        .font(Theme.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                Spacer(minLength: 0)
            }

            if item.isUnlocked, let unlockedAt = item.unlockedAt {
                Text(unlockedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(Theme.caption)
                    .foregroundStyle(Theme.Colors.muted)
            } else if let p = item.progress01 {
                ProgressView(value: p)
                    .tint(Theme.Colors.accent)
                Text("\(Int(round(p * 100)))% toward unlock")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.Colors.muted)
            } else {
                Text("Locked")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.Colors.muted)
            }
        }
        .padding(Theme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .stroke(item.isUnlocked ? Theme.Colors.accent.opacity(0.25) : Color.clear, lineWidth: 1)
        )
        .opacity(item.isUnlocked ? 1 : 0.88)
    }
}

#Preview {
    NavigationStack {
        AchievementsView()
            .environment(AppDependencies.preview)
    }
}
