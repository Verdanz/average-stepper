import Foundation
import Observation

@Observable
@MainActor
final class RoutePreviewViewModel {
    let route: GeneratedRoute
    private let preferences: UserPreferences

    /// Currently highlighted option for the map + detail cards.
    var selectedOptionID: UUID

    init(route: GeneratedRoute, preferences: UserPreferences) {
        self.route = route
        self.preferences = preferences
        self.selectedOptionID = route.options.first?.id ?? UUID()
    }

    var selectedOption: RouteOption? {
        route.options.first { $0.id == selectedOptionID }
    }

    var goalStepsText: String {
        Formatting.steps(route.goal.targetSteps)
    }

    var targetDistanceText: String {
        Formatting.distance(route.targetDistanceMeters, units: preferences.units)
    }

    func optionStepsText(_ option: RouteOption) -> String {
        Formatting.steps(option.estimatedSteps)
    }

    func optionDistanceText(_ option: RouteOption) -> String {
        Formatting.distance(option.distanceMeters, units: preferences.units)
    }

    func optionDurationText(_ option: RouteOption) -> String {
        Formatting.duration(option.estimatedDuration)
    }

    func optionScoreText(_ option: RouteOption) -> String {
        String(format: "%.2f", option.score)
    }

    func kindText(_ option: RouteOption) -> String {
        switch option.kind {
        case .loopPolygon:
            return "Loop"
        case .nearLoop:
            return "Near-loop"
        case .outAndBack:
            return "Out & back"
        }
    }
}
