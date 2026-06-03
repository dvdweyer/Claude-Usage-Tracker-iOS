import Foundation

final class UsageStatusCalculator {
    static func calculateStatus(
        usedPercentage: Double,
        showRemaining: Bool,
        elapsedFraction: Double? = nil
    ) -> UsageStatusLevel {
        let u = usedPercentage / 100.0
        if let t = elapsedFraction, t >= 0.15, t < 1.0, u > 0 {
            let projected = u / t
            switch projected {
            case ..<0.75:     return .safe
            case 0.75..<0.95: return .moderate
            default:          return .critical
            }
        }

        if showRemaining {
            let remaining = max(0, 100 - usedPercentage)
            switch remaining {
            case 20...:   return .safe
            case 10..<20: return .moderate
            default:      return .critical
            }
        } else {
            switch usedPercentage {
            case 0..<50:  return .safe
            case 50..<80: return .moderate
            default:      return .critical
            }
        }
    }

    static func elapsedFraction(
        resetTime: Date?,
        duration: TimeInterval,
        showRemaining: Bool
    ) -> Double? {
        guard let reset = resetTime, duration > 0 else { return nil }
        guard reset > Date() else { return showRemaining ? 0.0 : 1.0 }
        let remaining = reset.timeIntervalSince(Date())
        let elapsed = duration - remaining
        let fraction = min(max(elapsed / duration, 0), 1)
        return showRemaining ? 1.0 - fraction : fraction
    }

    static func getDisplayPercentage(usedPercentage: Double, showRemaining: Bool) -> Double {
        showRemaining ? max(0, 100 - usedPercentage) : usedPercentage
    }
}
