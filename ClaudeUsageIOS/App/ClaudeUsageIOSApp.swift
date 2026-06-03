import SwiftUI

@main
struct ClaudeUsageIOSApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .onChange(of: scenePhase) { _, phase in
            // Refresh immediately when moving to background so the widget
            // gets fresh data the moment the user switches to the home screen.
            if phase == .background {
                Task { await appState.refresh() }
            }
        }
    }
}
