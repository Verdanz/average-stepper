import Foundation

/// Running totals (walk count, steps, distance) derived only from `WalkSession`s with `status == .completed`.
struct GamificationTotals: Equatable, Sendable {
    var totalCompletedWalks: Int
    var totalEstimatedSteps: Int
    var totalDistanceMeters: Double

    static func from(completedWalks: [WalkSession]) -> GamificationTotals {
        let completed = completedWalks.filter { $0.status == .completed }
        let steps = completed.reduce(0) { $0 + $1.liveSteps }
        let distance = completed.reduce(0.0) { $0 + $1.liveDistanceMeters }
        return GamificationTotals(
            totalCompletedWalks: completed.count,
            totalEstimatedSteps: steps,
            totalDistanceMeters: distance
        )
    }
}
