import Foundation
import OSLog

enum RoutingLogger {
    static let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "AverageStepper", category: "Routing")
}
