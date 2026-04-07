import Foundation

/// Navigation destinations from the home planning flow.
enum HomeStack: Hashable {
    case routePreview(GeneratedRoute)
    case activeWalk
    case walkComplete
}
