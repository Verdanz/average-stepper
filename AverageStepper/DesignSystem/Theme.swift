import SwiftUI

/// Central spacing, typography, and color tokens for a consistent MVP UI.
enum Theme {
    static let cornerRadius: CGFloat = 16
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 20
    static let contentMaxWidth: CGFloat = 560

    static let title = Font.system(.title, design: .rounded).weight(.semibold)
    static let headline = Font.system(.title3, design: .rounded).weight(.semibold)
    static let body = Font.system(.body, design: .default)
    static let caption = Font.system(.caption, design: .default)
    static let metric = Font.system(.title2, design: .rounded).weight(.semibold).monospacedDigit()

    struct Colors {
        static let cardBackground = Color(.secondarySystemBackground)
        static let accent = Color.accentColor
        static let success = Color.green
        static let muted = Color.secondary
    }
}
