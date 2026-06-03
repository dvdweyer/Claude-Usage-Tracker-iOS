import SwiftUI

struct CredentialsView: View {
    @EnvironmentObject var appState: AppState
    let profile: Profile
    var onSave: ((Profile) -> Void)?

    @State private var sessionKeyInput = ""
    @State private var isTesting = false
    @State private var testError: String?
    @State private var testSuccess = false
    @State private var fetchedOrgs: [ClaudeAPIService.AccountInfo] = []
    @State private var selectedOrgId: String?

    private let validator = SessionKeyValidator()

    private var validationStatus: (isValid: Bool, errorMessage: String?) {
        validator.validationStatus(sessionKeyInput.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    var body: some View {
        Form {
            instructionsSection
            keyInputSection
            if !fetchedOrgs.isEmpty { orgPickerSection }
            saveSection
        }
        .navigationTitle("Add Session Key")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            sessionKeyInput = profile.claudeSessionKey ?? ""
            selectedOrgId = profile.organizationId
        }
    }

    // MARK: - Sections

    private var instructionsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Label("Where to find your session key", systemImage: "questionmark.circle")
                    .font(.subheadline.bold())
                Text("""
                    1. Open claude.ai in Safari on your Mac
                    2. Open DevTools → Application → Cookies → claude.ai
                    3. Copy the value of the "sessionKey" cookie
                    """)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    private var keyInputSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                SecureField("sk-ant-sid01-…", text: $sessionKeyInput)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .font(.system(.body, design: .monospaced))
                    .onChange(of: sessionKeyInput) { _, _ in
                        testError = nil
                        testSuccess = false
                        fetchedOrgs = []
                        selectedOrgId = nil
                    }

                if !sessionKeyInput.isEmpty {
                    Group {
                        if validationStatus.isValid {
                            Label("Format looks good", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else if let msg = validationStatus.errorMessage {
                            Label(msg, systemImage: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }

            Button {
                Task { await testAndFetchOrgs() }
            } label: {
                HStack {
                    if isTesting {
                        ProgressView().scaleEffect(0.8)
                        Text("Connecting…")
                    } else if testSuccess {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        Text("Connected")
                    } else {
                        Image(systemName: "network")
                        Text("Test & Fetch Organizations")
                    }
                }
            }
            .disabled(isTesting || !validationStatus.isValid)

            if let error = testError {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        } header: {
            Text("Session Key")
        } footer: {
            Text("The key is stored securely in the iOS Keychain and never leaves your device unencrypted.")
        }
    }

    private var orgPickerSection: some View {
        Section("Organization") {
            Picker("Select Organization", selection: $selectedOrgId) {
                ForEach(fetchedOrgs, id: \.uuid) { org in
                    Text(org.name.isEmpty ? org.uuid : org.name).tag(Optional(org.uuid))
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        }
    }

    private var saveSection: some View {
        Section {
            Button("Save Credentials") {
                saveCredentials()
            }
            .frame(maxWidth: .infinity)
            .disabled(isTesting || sessionKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    // MARK: - Actions

    private func testAndFetchOrgs() async {
        let key = sessionKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }
        isTesting = true
        testError = nil
        testSuccess = false
        do {
            let orgs = try await ClaudeAPIService.shared.testSessionKey(key)
            fetchedOrgs = orgs
            selectedOrgId = orgs.first?.uuid
            testSuccess = true
        } catch let error as AppError {
            testError = error.message
        } catch {
            testError = error.localizedDescription
        }
        isTesting = false
    }

    private func saveCredentials() {
        let key = sessionKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }

        var updated = profile
        updated.claudeSessionKey = key
        updated.organizationId = selectedOrgId
        onSave?(updated)
    }
}
