import Foundation

/// Centralized user-facing copy for errors, permissions, and coaching (MVP).
enum AppCopy {
    enum Location {
        static let whyWeNeedIt = "We use your approximate position to build a route near you and to show your movement along that route while you walk."
        static let accuracy = "GPS works best outdoors with a clear view of the sky. Indoors or dense areas, accuracy can vary — we filter noisy points so your progress stays reasonable."
        static let deniedTitle = "Location is off"
        static let deniedBody = "Turn on location access for Average Stepper in Settings to generate routes and track walks. You can change this anytime."
        static let openSettings = "Open Settings"
    }

    enum Routes {
        static let fromSteps = "You choose a step goal; we estimate distance from your stride and generate walking paths that aim to match that effort."
        static let tracking = "During a walk, the app tracks your position against the planned route, estimates steps from distance, and records your progress locally on this device."
    }

    enum Generation {
        static func noRouteNearby() -> String {
            "No walking route found nearby. Try a smaller or larger step target, or move to an area with more pedestrian paths."
        }

        static func directionsFailed(_ detail: String) -> String {
            "Couldn’t build a route. \(detail) Check your connection and try again."
        }

        static let noLocationFix = "Waiting for a location fix. Move outdoors if you can, then try again."
        static let deniedShort = "Location access is required to build a route here."
    }

    enum GPS {
        static let lowAccuracy = "GPS accuracy is limited right now. Results improve near windows or outdoors — you can still try generating a route."
    }

    enum Privacy {
        static let summary = "Average Stepper keeps walks, preferences, and achievements on this device. Nothing is uploaded to a server in this MVP. Location is used only to plan routes and track active walks."
    }
}
