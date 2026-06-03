import Foundation

@MainActor
final class ProfileManager: ObservableObject {
    static let shared = ProfileManager()

    @Published private(set) var profiles: [Profile] = []
    @Published private(set) var activeProfile: Profile?

    private let userDefaults = UserDefaults.standard
    private let profilesKey = "ios.profiles.v1"
    private let activeProfileIdKey = "ios.activeProfileId.v1"

    private init() {
        loadProfiles()
    }

    func loadProfiles() {
        if let data = userDefaults.data(forKey: profilesKey),
           let decoded = try? JSONDecoder().decode([Profile].self, from: data) {
            profiles = decoded
        }

        if profiles.isEmpty {
            let defaultProfile = Profile(name: "Personal")
            profiles = [defaultProfile]
            saveProfiles()
        }

        if let activeIdString = userDefaults.string(forKey: activeProfileIdKey),
           let activeId = UUID(uuidString: activeIdString),
           let profile = profiles.first(where: { $0.id == activeId }) {
            activeProfile = profile
        } else {
            activeProfile = profiles.first
        }
    }

    @discardableResult
    func createProfile(name: String) -> Profile {
        let profile = Profile(name: name.isEmpty ? "Profile \(profiles.count + 1)" : name)
        profiles.append(profile)
        saveProfiles()
        return profile
    }

    func updateProfile(_ profile: Profile) {
        if let idx = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[idx] = profile
        }
        if activeProfile?.id == profile.id {
            activeProfile = profile
        }
        saveProfiles()
    }

    func deleteProfile(_ profile: Profile) {
        guard profiles.count > 1 else { return }
        profiles.removeAll { $0.id == profile.id }
        if activeProfile?.id == profile.id {
            activeProfile = profiles.first
        }
        saveProfiles()
    }

    func activateProfile(id: UUID) {
        guard let profile = profiles.first(where: { $0.id == id }) else { return }
        activeProfile = profile
        userDefaults.set(id.uuidString, forKey: activeProfileIdKey)
    }

    private func saveProfiles() {
        if let data = try? JSONEncoder().encode(profiles) {
            userDefaults.set(data, forKey: profilesKey)
        }
        if let active = activeProfile {
            userDefaults.set(active.id.uuidString, forKey: activeProfileIdKey)
        }
    }
}
