import SwiftUI

struct UsageView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            Group {
                if let usage = appState.activeProfile?.claudeUsage {
                    usageContent(usage)
                } else if appState.isLoading {
                    loadingView
                } else if let error = appState.lastError {
                    errorView(error)
                } else {
                    emptyView
                }
            }
            .navigationTitle("Usage")
            .toolbar { refreshButton }
            .refreshable { await appState.refresh() }
        }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private func usageContent(_ usage: ClaudeUsage) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                profileHeader
                gaugesRow(usage)
                if usage.opusWeeklyPercentage > 0 || usage.sonnetWeeklyPercentage > 0 {
                    modelBreakdownCard(usage)
                }
                if let costUsed = usage.costUsed, let costLimit = usage.costLimit {
                    overageCard(used: costUsed, limit: costLimit, currency: usage.costCurrency ?? "USD")
                }
                if let balance = usage.overageBalance {
                    creditGrantCard(balance: balance, currency: usage.overageBalanceCurrency ?? "USD")
                }
                lastRefreshedFooter
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }

    private var profileHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(appState.activeProfile?.name ?? "Claude")
                    .font(.title2.bold())
                if let refreshed = appState.lastRefreshed {
                    Text("Updated \(refreshed.timeRemainingString(from: Date())) ago")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if appState.isLoading {
                ProgressView().scaleEffect(0.8)
            }
        }
        .padding(.top, 8)
    }

    private func gaugesRow(_ usage: ClaudeUsage) -> some View {
        HStack(spacing: 16) {
            usageCard(
                title: "Session",
                subtitle: "5-hour window",
                percentage: usage.effectiveSessionPercentage,
                resetTime: usage.sessionResetTime,
                systemImage: "bolt.fill"
            )
            usageCard(
                title: "Weekly",
                subtitle: "7-day window",
                percentage: usage.weeklyPercentage,
                resetTime: usage.weeklyResetTime,
                systemImage: "calendar"
            )
        }
    }

    private func usageCard(
        title: String,
        subtitle: String,
        percentage: Double,
        resetTime: Date,
        systemImage: String
    ) -> some View {
        let status = UsageStatusCalculator.calculateStatus(usedPercentage: percentage, showRemaining: false)
        let color: Color = {
            switch status {
            case .safe: return .green
            case .moderate: return .orange
            case .critical: return Color(red: 0.9, green: 0.2, blue: 0.2)
            }
        }()

        return VStack(spacing: 12) {
            HStack {
                Image(systemName: systemImage)
                    .font(.caption.bold())
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline.bold())
                Spacer()
            }

            UsageGaugeView(
                percentage: percentage,
                label: title,
                resetTime: nil,
                size: 100
            )

            VStack(spacing: 4) {
                Text("Resets \(resetTime.resetTimeString())")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func modelBreakdownCard(_ usage: ClaudeUsage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Model Breakdown", systemImage: "cpu")
                .font(.subheadline.bold())
                .foregroundStyle(.primary)

            if usage.opusWeeklyPercentage > 0 {
                modelRow(name: "Opus", percentage: usage.opusWeeklyPercentage, color: .purple)
            }
            if usage.sonnetWeeklyPercentage > 0 {
                modelRow(name: "Sonnet", percentage: usage.sonnetWeeklyPercentage, color: .blue)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func modelRow(name: String, percentage: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(name)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(percentage.rounded()))%")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.15))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(percentage / 100), height: 6)
                        .animation(.easeInOut, value: percentage)
                }
            }
            .frame(height: 6)
        }
    }

    private func overageCard(used: Double, limit: Double, currency: String) -> some View {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        let usedStr = formatter.string(from: NSNumber(value: used)) ?? "\(used)"
        let limitStr = formatter.string(from: NSNumber(value: limit)) ?? "\(limit)"
        let pct = limit > 0 ? used / limit * 100 : 0

        return VStack(alignment: .leading, spacing: 8) {
            Label("Monthly Overage", systemImage: "dollarsign.circle")
                .font(.subheadline.bold())
            HStack {
                Text("\(usedStr) / \(limitStr)")
                    .font(.subheadline)
                Spacer()
                Text("\(Int(pct.rounded()))%")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(pct > 80 ? .red : .primary)
            }
            ProgressView(value: pct / 100)
                .tint(pct > 80 ? .red : pct > 50 ? .orange : .green)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func creditGrantCard(balance: Double, currency: String) -> some View {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        let balanceStr = formatter.string(from: NSNumber(value: balance)) ?? "\(balance)"

        return HStack {
            Label("Overage Credit Balance", systemImage: "creditcard")
                .font(.subheadline.bold())
            Spacer()
            Text(balanceStr)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.green)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var lastRefreshedFooter: some View {
        Group {
            if let refreshed = appState.lastRefreshed {
                Text("Last updated: \(refreshed, style: .time)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Fetching usage data…")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ error: AppError) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(error.message)
                .font(.headline)
                .multilineTextAlignment(.center)
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button("Try Again") {
                Task { await appState.refresh() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No data yet")
                .font(.headline)
            Text("Pull down to refresh or check your credentials in Settings.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ToolbarContentBuilder
    private var refreshButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                Task { await appState.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(appState.isLoading)
        }
    }
}

#Preview {
    let state = AppState()
    return UsageView().environmentObject(state)
}
