import Foundation

/// High-level shape of a generated candidate (for UI labels and debugging).
enum RoutePatternKind: String, Codable, Hashable, Sendable {
    /// Closed loop returning to the start (or very close).
    case loopPolygon
    /// Loop-like path with a deliberate gap before closing (still scored for closure).
    case nearLoop
    /// Start → turnaround → return along the same corridor (two legs).
    case outAndBack
}
