import SwiftUI

struct AchievementsView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var model = AchievementsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
                Text("Achievements")
                    .font(Theme.title)
                    .accessibilityAddTraits(.isHeader)

                Text("Unlock badges by walking consistently and hitting bigger step goals.")
                    .font(Theme.body)
                    .foregroundStyle(.secondary)

                ForEach(model.achievements) { item in
                    ASCard {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: item.badge.systemImageName ?? "star.circle")
                                .font(.title2)
                                .foregroundStyle(item.isUnlocked ? Theme.Colors.success : Theme.Colors.muted)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.badge.title)
                                    .font(Theme.headline)
                                Text(item.badge.detail)
                                    .font(Theme.caption)
                                    .foregroundStyle(.secondary)
                                if let unlockedAt = item.unlockedAt {
                                    Text("Unlocked \(unlockedAt.formatted(date: .abbreviated, time: .omitted))")
                                        .font(Theme.caption)
                                        .foregroundStyle(Theme.Colors.muted)
                                } else {
                                    Text("Locked")
                                        .font(Theme.caption)
                                        .foregroundStyle(Theme.Colors.muted)
                                }
                            }
                            Spacer(minLength: 0)
                        }
                    }
                    .opacity(item.isUnlocked ? 1 : 0.55)
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
}

#Preview {
    NavigationStack {
        AchievementsView()
            .environment(AppDependencies.preview)
    }
}
