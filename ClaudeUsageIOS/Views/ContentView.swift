import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var showOnboarding = false

    var body: some View {
        Group {
            if appState.activeProfile?.hasUsageCredentials == true {
                mainTabView
            } else {
                onboardingView
            }
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showOnboarding) {
            onboardingSheet
        }
    }

    // MARK: - Main Tab View

    private var mainTabView: some View {
        TabView {
            UsageView()
                .tabItem {
                    Label("Usage", systemImage: "chart.bar.fill")
                }

            ProfilesView()
                .tabItem {
                    Label("Profiles", systemImage: "person.2.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }

    // MARK: - Onboarding

    private var onboardingView: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 72))
                    .foregroundStyle(Color.accentColor)

                Text("Claude Usage Tracker")
                    .font(.largeTitle.bold())

                Text("Monitor your Claude AI session and weekly usage from your iPhone.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button {
                showOnboarding = true
            } label: {
                Label("Get Started", systemImage: "arrow.right")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    private var onboardingSheet: some View {
        NavigationStack {
            if let profile = appState.activeProfile {
                CredentialsView(profile: profile) { updated in
                    appState.updateProfile(updated)
                    showOnboarding = false
                    Task { await appState.refresh() }
                }
                .navigationTitle("Add Credentials")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showOnboarding = false }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView().environmentObject(AppState())
}
