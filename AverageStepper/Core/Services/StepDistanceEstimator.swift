import Foundation

/// Stateless stride math used by planning UI and route scoring previews.
struct StepDistanceEstimator: StepDistanceEstimating {
    func targetMeters(forSteps steps: Int, strideMeters: Double) -> Double {
        estimatedDistanceMeters(forSteps: steps, strideMeters: strideMeters)
    }

    func estimatedDistanceMeters(forSteps steps: Int, strideMeters: Double) -> Double {
        guard steps > 0, strideMeters > 0 else { return 0 }
        return Double(steps) * strideMeters
    }

    func estimatedSteps(forDistanceMeters distance: Double, strideMeters: Double) -> Int {
        guard distance > 0, strideMeters > 0 else { return 0 }
        return Int((distance / strideMeters).rounded())
    }

    func estimatedDuration(distanceMeters: Double, speedMetersPerSecond: Double) -> TimeInterval {
        guard distanceMeters > 0, speedMetersPerSecond > 0 else { return 0 }
        return distanceMeters / speedMetersPerSecond
    }
}
