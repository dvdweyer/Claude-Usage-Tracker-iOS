import WidgetKit
import SwiftUI

// MARK: - Provider

struct ClaudeUsageProvider: TimelineProvider {
    private let store = WidgetDataStore()

    func placeholder(in context: Context) -> ClaudeUsageEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (ClaudeUsageEntry) -> Void) {
        completion(context.isPreview ? .placeholder : currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ClaudeUsageEntry>) -> Void) {
        Task {
            var entry = currentEntry()
            if let key = store.readSessionKey(), let orgId = store.readOrgId(),
               let fresh = await WidgetNetworkService.fetchUsage(sessionKey: key, orgId: orgId) {
                entry = .from(usage: fresh, profileName: store.readProfileName())
            }
            let now = Date()
            var next = now.addingTimeInterval(Constants.RefreshIntervals.widgetRefresh)
            // Wake up 1 min after each reset so the widget fetches fresh post-reset data.
            for resetTime in [entry.sessionResetTime, entry.weeklyResetTime] {
                let candidate = resetTime.addingTimeInterval(60)
                if candidate > now { next = min(next, candidate) }
            }
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private func currentEntry() -> ClaudeUsageEntry {
        guard let usage = store.readUsage() else { return .empty }
        return .from(usage: usage, profileName: store.readProfileName())
    }
}

// MARK: - Minimal local store (reads from App Group UserDefaults)

private struct WidgetDataStore {
    private let defaults = UserDefaults(suiteName: Constants.appGroupIdentifier)
    private let usageKey = "widget.claudeUsage"
    private let profileNameKey = "widget.profileName"

    func readUsage() -> ClaudeUsage? {
        guard let data = defaults?.data(forKey: usageKey) else { return nil }
        return try? JSONDecoder().decode(ClaudeUsage.self, from: data)
    }

    func readProfileName() -> String {
        defaults?.string(forKey: profileNameKey) ?? "Claude"
    }

    func readSessionKey() -> String? {
        defaults?.string(forKey: "widget.sessionKey")
    }

    func readOrgId() -> String? {
        defaults?.string(forKey: "widget.orgId")
    }
}

// MARK: - Widget Definition

struct ClaudeUsageWidget: Widget {
    let kind = "ClaudeUsageWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ClaudeUsageProvider()) { entry in
            ClaudeUsageWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Claude Usage")
        .description("Monitor your Claude AI session and weekly usage.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Entry Views

struct ClaudeUsageWidgetEntryView: View {
    let entry: ClaudeUsageEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:  SmallWidgetView(entry: entry)
        case .systemMedium: MediumWidgetView(entry: entry)
        default:            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: ClaudeUsageEntry

    private var sessionColor: Color { statusColor(for: entry.sessionPercentage) }
    private var weeklyColor: Color { statusColor(for: entry.weeklyPercentage) }

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.caption2.bold())
                    .foregroundStyle(sessionColor)
                Spacer()
            }

            if entry.hasData {
                // Main session gauge
                ZStack {
                    Circle()
                        .stroke(sessionColor.opacity(0.15), lineWidth: 7)
                    Circle()
                        .trim(from: 0, to: CGFloat(entry.sessionPercentage / 100))
                        .stroke(sessionColor, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 1) {
                        Text("\(Int(entry.sessionPercentage.rounded()))%")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(sessionColor)
                        Text("Session")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 72, height: 72)

                // Weekly bar
                VStack(spacing: 2) {
                    HStack {
                        Text("Weekly")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(entry.weeklyPercentage.rounded()))%")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(weeklyColor)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(weeklyColor.opacity(0.15))
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(weeklyColor)
                                .frame(width: geo.size.width * CGFloat(entry.weeklyPercentage / 100), height: 4)
                        }
                    }
                    .frame(height: 4)
                }

                // Reset times
                VStack(spacing: 1) {
                    HStack {
                        Text("⚡")
                            .font(.system(size: 9))
                        Text(entry.sessionResetTime.resetTimeString())
                            .font(.system(size: 10))
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    HStack {
                        Text("📅")
                            .font(.system(size: 9))
                        Text(entry.weeklyResetTime.resetTimeString())
                            .font(.system(size: 10))
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                }
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("No data")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(12)
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: ClaudeUsageEntry

    private var sessionColor: Color { statusColor(for: entry.sessionPercentage) }
    private var weeklyColor: Color { statusColor(for: entry.weeklyPercentage) }

    var body: some View {
        HStack(spacing: 0) {
            metricColumn(
                title: "Session",
                subtitle: "5-hour window",
                percentage: entry.sessionPercentage,
                resetTime: entry.sessionResetTime,
                color: sessionColor
            )

            Divider()
                .padding(.vertical, 12)

            metricColumn(
                title: "Weekly",
                subtitle: "7-day window",
                percentage: entry.weeklyPercentage,
                resetTime: entry.weeklyResetTime,
                color: weeklyColor
            )
        }
        .padding(.horizontal, 16)
        .overlay(alignment: .top) {
            HStack {
                Spacer()
                if let updated = entry.hasData ? entry.date : nil {
                    Text(updated, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
    }

    private func metricColumn(
        title: String,
        subtitle: String,
        percentage: Double,
        resetTime: Date,
        color: Color
    ) -> some View {
        VStack(spacing: 8) {
            Spacer()

            if entry.hasData {
                ZStack {
                    Circle()
                        .stroke(color.opacity(0.15), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: CGFloat(percentage / 100))
                        .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 1) {
                        Text("\(Int(percentage.rounded()))%")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(color)
                        Text(title)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 76, height: 76)

                Text("Resets \(resetTime.resetTimeString())")
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            } else {
                Image(systemName: "minus.circle")
                    .foregroundStyle(.secondary)
                Text("—")
                    .font(.title2.bold())
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Color Helper

private func statusColor(for percentage: Double) -> Color {
    switch percentage {
    case 0..<50:  return .green
    case 50..<80: return .orange
    default:      return Color(red: 0.9, green: 0.2, blue: 0.2)
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    ClaudeUsageWidget()
} timeline: {
    ClaudeUsageEntry.placeholder
    ClaudeUsageEntry.empty
}

#Preview(as: .systemMedium) {
    ClaudeUsageWidget()
} timeline: {
    ClaudeUsageEntry.placeholder
}
