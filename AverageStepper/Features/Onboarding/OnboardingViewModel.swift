import Foundation
import Observation

@Observable
@MainActor
final class OnboardingViewModel {
    var stepIndex: Int = 0
    let pageCount = 5

    func advance() {
        stepIndex = min(stepIndex + 1, pageCount - 1)
    }

    func goBack() {
        stepIndex = max(stepIndex - 1, 0)
    }

    func requestLocation(dependencies: AppDependencies) {
        dependencies.locationForObservation.requestWhenInUseAuthorization()
    }

    func completeOnboarding(dependencies: AppDependencies) {
        var prefs = dependencies.preferences
        prefs.hasCompletedOnboarding = true
        dependencies.preferences = prefs
    }
}
