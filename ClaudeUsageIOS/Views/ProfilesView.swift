import SwiftUI

struct ProfilesView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddProfile = false
    @State private var newProfileName = ""
    @State private var profileToEdit: Profile?

    var body: some View {
        NavigationStack {
            List {
                ForEach(appState.profiles) { profile in
                    ProfileRow(
                        profile: profile,
                        isActive: appState.activeProfile?.id == profile.id
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if appState.activeProfile?.id != profile.id {
                            appState.activateProfile(id: profile.id)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            appState.deleteProfile(profile)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .disabled(appState.profiles.count <= 1)

                        Button {
                            profileToEdit = profile
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
            .navigationTitle("Profiles")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddProfile = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddProfile) {
                addProfileSheet
            }
            .sheet(item: $profileToEdit) { profile in
                editProfileSheet(profile)
            }
        }
    }

    @ViewBuilder
    private func editProfileSheet(_ profile: Profile) -> some View {
        NavigationStack {
            ProfileDetailView(profile: profile) { updated in
                appState.updateProfile(updated)
                profileToEdit = nil
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { profileToEdit = nil }
                }
            }
        }
    }

    private var addProfileSheet: some View {
        NavigationStack {
            Form {
                Section("Profile Name") {
                    TextField("e.g. Work, Personal", text: $newProfileName)
                        .autocorrectionDisabled()
                }
                Section {
                    Button("Create Profile") {
                        appState.createProfile(name: newProfileName)
                        newProfileName = ""
                        showAddProfile = false
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(newProfileName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle("New Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        newProfileName = ""
                        showAddProfile = false
                    }
                }
            }
        }
    }
}

private struct ProfileRow: View {
    let profile: Profile
    let isActive: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isActive ? Color.accentColor : Color(UIColor.systemGray5))
                    .frame(width: 36, height: 36)
                Text(profile.name.prefix(1).uppercased())
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isActive ? .white : .primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(profile.name)
                        .font(.body.bold())
                    if isActive {
                        Text("Active")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }

                if let usage = profile.claudeUsage {
                    Text("Session \(Int(usage.effectiveSessionPercentage.rounded()))% · Weekly \(Int(usage.weeklyPercentage.rounded()))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if profile.hasUsageCredentials {
                    Text("Credentials configured")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No credentials")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            if isActive {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.accentColor)
                    .font(.body.bold())
            }
        }
        .padding(.vertical, 4)
    }
}
