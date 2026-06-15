import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showCredentials = false
    @State private var notificationsEnabled = false
    @State private var refreshInterval: Double = 30
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    private let refreshOptions: [(label: String, value: Double)] = [
        ("15 seconds", 15),
        ("30 seconds", 30),
        ("1 minute", 60),
        ("5 minutes", 300),
        ("15 minutes", 900)
    ]

    var body: some View {
        NavigationStack {
            Form {
                activeProfileSection
                refreshSection
                notificationsSection
                aboutSection
            }
            .navigationTitle("Settings")
            .onAppear { loadSettings() }
            .sheet(isPresented: $showCredentials) {
                if let profile = appState.activeProfile {
                    NavigationStack {
                        ProfileDetailView(profile: profile) { updated in
                            appState.updateProfile(updated)
                            showCredentials = false
                            Task { await appState.refresh() }
                        }
                        .navigationTitle("Credentials")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") { showCredentials = false }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var activeProfileSection: some View {
        Section("Active Profile") {
            if let profile = appState.activeProfile {
                HStack {
                    Label(profile.name, systemImage: "person.circle")
                    Spacer()
                    if profile.hasUsageCredentials {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(.green)
                    } else {
                        Image(systemName: "exclamationmark.shield")
                            .foregroundStyle(.orange)
                    }
                }

                Button {
                    showCredentials = true
                } label: {
                    Label(
                        profile.hasUsageCredentials ? "Update Credentials" : "Add Credentials",
                        systemImage: "key"
                    )
                }
            }
        }
    }

    private var refreshSection: some View {
        Section {
            Picker("Refresh Interval", selection: $refreshInterval) {
                ForEach(refreshOptions, id: \.value) { option in
                    Text(option.label).tag(option.value)
                }
            }
            .onChange(of: refreshInterval) { _, newValue in
                saveRefreshInterval(newValue)
            }
        } header: {
            Text("Auto-Refresh")
        } footer: {
            Text("How often the app automatically checks for updated usage data.")
        }
    }

    private var notificationsSection: some View {
        Section {
            HStack {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { _, enabled in
                        if enabled {
                            requestNotificationPermission()
                        } else {
                            saveNotificationsEnabled(false)
                        }
                    }
            }

            if notificationStatus == .denied {
                Label("Notifications blocked in Settings", systemImage: "bell.slash")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.caption)
            }

            if notificationsEnabled {
                notificationThresholdsView
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text("Get notified when your usage reaches a threshold.")
        }
    }

    private var notificationThresholdsView: some View {
        Group {
            if var profile = appState.activeProfile {
                Toggle("Notify on reset", isOn: Binding(
                    get: { profile.notificationSettings.resetNotificationEnabled },
                    set: { val in
                        profile.notificationSettings.resetNotificationEnabled = val
                        appState.updateProfile(profile)
                    }
                ))
                Toggle("Alert at 75%", isOn: Binding(
                    get: { profile.notificationSettings.threshold75Enabled },
                    set: { val in
                        profile.notificationSettings.threshold75Enabled = val
                        appState.updateProfile(profile)
                    }
                ))
                Toggle("Alert at 90%", isOn: Binding(
                    get: { profile.notificationSettings.threshold90Enabled },
                    set: { val in
                        profile.notificationSettings.threshold90Enabled = val
                        appState.updateProfile(profile)
                    }
                ))
                Toggle("Alert at 95%", isOn: Binding(
                    get: { profile.notificationSettings.threshold95Enabled },
                    set: { val in
                        profile.notificationSettings.threshold95Enabled = val
                        appState.updateProfile(profile)
                    }
                ))
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("App", value: "Claude Usage Tracker")
            LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
            LabeledContent("Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—")
            Link(destination: URL(string: "https://github.com/dvdweyer/Claude-Usage-Tracker-iOS")!) {
                Label("View on GitHub", systemImage: "safari")
            }
        }
    }

    // MARK: - Helpers

    private func loadSettings() {
        refreshInterval = appState.activeProfile?.refreshInterval ?? 30
        let settings = appState.activeProfile?.notificationSettings
        notificationsEnabled = settings?.enabled ?? false

        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            await MainActor.run { notificationStatus = settings.authorizationStatus }
        }
    }

    private func saveRefreshInterval(_ interval: Double) {
        guard var profile = appState.activeProfile else { return }
        profile.refreshInterval = interval
        appState.updateProfile(profile)
    }

    private func saveNotificationsEnabled(_ enabled: Bool) {
        guard var profile = appState.activeProfile else { return }
        profile.notificationSettings.enabled = enabled
        appState.updateProfile(profile)
    }

    private func requestNotificationPermission() {
        Task {
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                await MainActor.run {
                    notificationsEnabled = granted
                    saveNotificationsEnabled(granted)
                    if !granted { notificationStatus = .denied }
                }
            } catch {
                await MainActor.run { notificationsEnabled = false }
            }
        }
    }
}
