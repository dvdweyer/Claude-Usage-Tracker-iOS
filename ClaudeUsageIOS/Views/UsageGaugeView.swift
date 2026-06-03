import SwiftUI

struct UsageGaugeView: View {
    let percentage: Double
    let label: String
    let resetTime: Date?
    let size: CGFloat

    private var status: UsageStatusLevel {
        UsageStatusCalculator.calculateStatus(usedPercentage: percentage, showRemaining: false)
    }

    private var gaugeColor: Color {
        switch status {
        case .safe:     return .green
        case .moderate: return .orange
        case .critical: return Color(red: 0.9, green: 0.2, blue: 0.2)
        }
    }

    private var trimEnd: CGFloat {
        CGFloat(min(percentage / 100.0, 1.0))
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(gaugeColor.opacity(0.15), lineWidth: size * 0.09)

                Circle()
                    .trim(from: 0, to: trimEnd)
                    .stroke(
                        gaugeColor,
                        style: StrokeStyle(lineWidth: size * 0.09, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.6), value: percentage)

                VStack(spacing: 2) {
                    Text("\(Int(percentage.rounded()))%")
                        .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                        .foregroundStyle(gaugeColor)
                    Text(label)
                        .font(.system(size: size * 0.11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: size, height: size)

            if let reset = resetTime {
                Text(reset.timeRemainingString())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }
}

#Preview {
    HStack(spacing: 24) {
        UsageGaugeView(percentage: 72, label: "Session", resetTime: Date().addingTimeInterval(3600), size: 110)
        UsageGaugeView(percentage: 45, label: "Weekly", resetTime: Date().addingTimeInterval(3 * 24 * 3600), size: 110)
    }
    .padding()
}
