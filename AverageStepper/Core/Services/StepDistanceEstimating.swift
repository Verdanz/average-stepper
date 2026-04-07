import Foundation

/// Converts between step goals and distance using stride heuristics.
protocol StepDistanceEstimating: Sendable {
    /// Maps step goal + stride to an approximate target distance (meters).
    func targetMeters(forSteps steps: Int, strideMeters: Double) -> Double
    func estimatedDistanceMeters(forSteps steps: Int, strideMeters: Double) -> Double
    func estimatedSteps(forDistanceMeters distance: Double, strideMeters: Double) -> Int
    func estimatedDuration(distanceMeters: Double, speedMetersPerSecond: Double) -> TimeInterval
}
