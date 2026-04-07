import Foundation

enum Formatting {
    static func distance(_ meters: Double, units: MeasurementUnits) -> String {
        switch units {
        case .metric:
            if meters >= 1000 {
                return String(format: "%.1f km", meters / 1000)
            }
            return String(format: "%.0f m", meters)
        case .imperial:
            let feet = meters * 3.28084
            if feet >= 5280 {
                let mi = feet / 5280
                return String(format: "%.1f mi", mi)
            }
            return String(format: "%.0f ft", feet)
        }
    }

    static func duration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        if minutes < 60 {
            return "\(minutes) min"
        }
        let h = minutes / 60
        let m = minutes % 60
        return "\(h) hr \(m) min"
    }

    /// Compact clock for active timers (e.g. `12:34` or `1:02:03`).
    static func elapsedClock(_ seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds))
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, sec)
        }
        return String(format: "%d:%02d", m, sec)
    }

    static func steps(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
