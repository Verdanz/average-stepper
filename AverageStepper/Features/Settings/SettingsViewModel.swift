import Foundation
import Observation

@Observable
@MainActor
final class SettingsViewModel {
    var showResetAchievementsConfirm = false
    var showResetAllDataConfirm = false
}
