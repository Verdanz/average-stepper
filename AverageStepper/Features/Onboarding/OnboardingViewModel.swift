import Foundation
import Observation

@Observable
@MainActor
final class OnboardingViewModel {
    var isRequestingPermission = false

    func completeIntro(dependencies: AppDependencies) {
        // TODO: Persist `hasCompletedOnboarding` to UserDefaults / SwiftData.
        dependencies.preferences.hasCompletedOnboarding = true
    }

    func requestLocation(dependencies: AppDependencies) {
        isRequestingPermission = true
        dependencies.locationService.requestWhenInUseAuthorization()
        // TODO: Observe authorization callback and continue flow when authorized.
        isRequestingPermission = false
    }
}
