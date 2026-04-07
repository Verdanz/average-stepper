import Foundation

/// A single unlockable badge entry: presentation (`Badge`) plus machine-evaluated `BadgeRule`.
/// The catalog lives in `BadgeCatalog`; add rows there to extend gamification without changing engine code.
struct BadgeDefinition: Equatable, Sendable {
    var id: String
    var badge: Badge
    var rule: BadgeRule
}
