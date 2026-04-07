import Foundation

/// Persists `UserPreferences` to `UserDefaults` (MVP; can migrate to App Group / SwiftData later).
enum UserPreferencesStore {
    private static let key = "AverageStepper.userPreferences.v1"

    static func load() -> UserPreferences {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return .default
        }
        return (try? JSONDecoder().decode(UserPreferences.self, from: data)) ?? .default
    }

    static func save(_ preferences: UserPreferences) {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
