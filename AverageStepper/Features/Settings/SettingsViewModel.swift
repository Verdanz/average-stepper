import Foundation
import Observation

@Observable
@MainActor
final class SettingsViewModel {
    /// TODO: Persist preference changes via `UserSettingsRepository` / SwiftData.
    func markNeedsPersistence() {}
}
