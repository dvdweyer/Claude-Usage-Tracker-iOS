import SwiftUI

struct ProfileDetailView: View {
    @State var profile: Profile
    var onSave: ((Profile) -> Void)?

    @State private var nameInput: String
    @State private var sessionKeyInput: String
    @State private var orgIdInput: String
    @State private var isTesting = false
    @State private var testStatus: TestStatus = .idle
    @State private var fetchedOrgs: [ClaudeAPIService.AccountInfo] = []

    enum TestStatus {
        case idle, testing, success, failure(String)
    }

    init(profile: Profile, onSave: ((Profile) -> Void)? = nil) {
        self._profile = State(initialValue: profile)
        self.onSave = onSave
        self._nameInput = State(initialValue: profile.name)
        self._sessionKeyInput = State(initialValue: profile.claudeSessionKey ?? "")
        self._orgIdInput = State(initialValue: profile.organizationId ?? "")
    }

    var body: some View {
        Form {
            nameSection
            credentialsSection
            saveSection
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        Section("Profile Name") {
            TextField("e.g. Work, Personal", text: $nameInput)
                .autocorrectionDisabled()
        }
    }

    private var credentialsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Session Key")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                SecureField("sk-ant-sid01-…", text: $sessionKeyInput)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .font(.system(.body, design: .monospaced))
                    .onChange(of: sessionKeyInput) { _, _ in
                        testStatus = .idle
                        fetchedOrgs = []
                    }
            }

            if !sessionKeyInput.isEmpty {
                Button {
                    Task { await testKey() }
                } label: {
                    HStack {
                        switch testStatus {
                        case .idle:
                            Label("Test & Fetch Orgs", systemImage: "network")
                        case .testing:
                            ProgressView().scaleEffect(0.8)
                            Text("Connecting…")
                        case .success:
                            Label("Connected", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        case .failure(let msg):
                            Label(msg, systemImage: "xmark.circle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                }
                .disabled(isTesting)
            }

            if !fetchedOrgs.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Organization")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("Organization", selection: $orgIdInput) {
                        ForEach(fetchedOrgs, id: \.uuid) { org in
                            Text(org.name.isEmpty ? org.uuid : org.name).tag(org.uuid)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
            } else if !orgIdInput.isEmpty {
                HStack {
                    Text("Organization ID")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(orgIdInput)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        } header: {
            Text("Credentials")
        } footer: {
            Text("Session keys are stored in the iOS Keychain. Org ID is fetched automatically when you test the key.")
        }
    }

    private var saveSection: some View {
        Section {
            Button("Save Profile") {
                saveProfile()
            }
            .frame(maxWidth: .infinity)
            .disabled(nameInput.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    // MARK: - Actions

    private func testKey() async {
        let key = sessionKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }
        isTesting = true
        testStatus = .testing
        do {
            let orgs = try await ClaudeAPIService.shared.testSessionKey(key)
            fetchedOrgs = orgs
            orgIdInput = orgs.first?.uuid ?? orgIdInput
            testStatus = .success
        } catch let error as AppError {
            testStatus = .failure(error.message)
        } catch {
            testStatus = .failure(error.localizedDescription)
        }
        isTesting = false
    }

    private func saveProfile() {
        let key = sessionKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)

        var updated = profile
        updated.name = nameInput.trimmingCharacters(in: .whitespaces)
        updated.claudeSessionKey = key.isEmpty ? nil : key
        updated.organizationId = orgIdInput.isEmpty ? nil : orgIdInput
        onSave?(updated)
    }
}
