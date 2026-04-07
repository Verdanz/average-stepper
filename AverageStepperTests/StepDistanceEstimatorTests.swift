import XCTest
@testable import AverageStepper

final class StepDistanceEstimatorTests: XCTestCase {
    func testTargetMetersMatchesStrideProduct() {
        let estimator = StepDistanceEstimator()
        let stride = 0.76
        XCTAssertEqual(estimator.targetMeters(forSteps: 5000, strideMeters: stride), 5000 * stride, accuracy: 0.001)
    }

    func testEstimatedStepsRounds() {
        let estimator = StepDistanceEstimator()
        XCTAssertEqual(estimator.estimatedSteps(forDistanceMeters: 760, strideMeters: 0.76), 1000)
    }

    func testDurationFromSpeed() {
        let estimator = StepDistanceEstimator()
        let d = estimator.estimatedDuration(distanceMeters: 1400, speedMetersPerSecond: 1.4)
        XCTAssertEqual(d, 1000, accuracy: 0.001)
    }
}
