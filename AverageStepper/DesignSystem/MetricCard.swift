import SwiftUI

/// Compact metric display for steps, distance, and time.
struct MetricCard: View {
    let title: String
    let value: String
    var subtitle: String?

    var body: some View {
        ASCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(title.uppercased())
                    .font(Theme.caption)
                    .foregroundStyle(Theme.Colors.muted)
                Text(value)
                    .font(Theme.metric)
                    .foregroundStyle(.primary)
                    .accessibilityLabel("\(title), \(value)")
                if let subtitle {
                    Text(subtitle)
                        .font(Theme.caption)
                        .foregroundStyle(Theme.Colors.muted)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    MetricCard(title: "Steps", value: "5,240", subtitle: "Goal: 5,000")
        .padding()
}
