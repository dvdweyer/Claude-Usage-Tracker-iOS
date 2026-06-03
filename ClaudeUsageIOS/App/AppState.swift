import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var profiles: [Profile] = []
    @Published var activeProfile: Profile?
    @Published var isLoading = false
    @Published var lastError: AppError?
    @Published var lastRefreshed: Date?

    private let profileManager = ProfileManager.shared
    private var refreshTimer: Timer?

    init() {
        syncFromManager()
        if activeProfile?.hasUsageCredentials == true {
            scheduleRefresh()
        }
        NetworkMonitor.shared.startMonitoring()
        NetworkMonitor.shared.onNetworkAvailable = { [weak self] in
            Task { await self?.refresh() }
        }
    }

    deinit {
        refreshTimer?.invalidate()
    }

    // MARK: - Usage Refresh

    func refresh() async {
        guard let profile = activeProfile, profile.hasUsageCredentials else { return }
        guard !isLoading else { return }

        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            let result = try await ClaudeAPIService.shared.fetchUsageDataWithOrgId(for: profile)
            var updatedProfile = profile
            updatedProfile.claudeUsage = result.usage
            updatedProfile.lastUsedAt = Date()
            // Persist the org ID when it was auto-resolved on first use.
            if updatedProfile.organizationId == nil {
                updatedProfile.organizationId = result.orgId
            }
            profileManager.updateProfile(updatedProfile)
            syncFromManager()
            lastRefreshed = Date()
            AppGroupStore.shared.writeUsage(result.usage, profileName: updatedProfile.name)
        } catch let error as AppError {
            lastError = error
        } catch {
            lastError = AppError(code: .unknown, message: error.localizedDescription, isRecoverable: true)
        }
    }

    // MARK: - Profile Management

    func createProfile(name: String) {
        let p = profileManager.createProfile(name: name)
        syncFromManager()
        if profiles.count == 1 {
            activateProfile(id: p.id)
        }
    }

    func updateProfile(_ profile: Profile) {
        profileManager.updateProfile(profile)
        syncFromManager()
        if activeProfile?.id == profile.id {
            scheduleRefresh()
        }
    }

    func deleteProfile(_ profile: Profile) {
        profileManager.deleteProfile(profile)
        syncFromManager()
    }

    func activateProfile(id: UUID) {
        profileManager.activateProfile(id: id)
        syncFromManager()
        scheduleRefresh()
        Task { await refresh() }
    }

    // MARK: - Auto-refresh

    func scheduleRefresh() {
        refreshTimer?.invalidate()
        let interval = activeProfile?.refreshInterval ?? Constants.RefreshIntervals.defaultRefresh
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { await self?.refresh() }
        }
    }

    // MARK: - Private Helpers

    private func syncFromManager() {
        profiles = profileManager.profiles
        activeProfile = profileManager.activeProfile
    }

}
