// ClawInstaller — macOS Setup Wizard for OpenClaw

import SwiftUI

@main
struct ClawInstallerApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appState)
                .frame(minWidth: 800, minHeight: 700)
                .frame(width: 860, height: 720)
        }
        .windowResizability(.contentMinSize)

        MenuBarExtra("OpenClaw", systemImage: "ant.fill") {
            MenuBarView()
                .environmentObject(appState)
        }
    }
}

struct MainView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationSplitView {
            Sidebar()
        } detail: {
            switch appState.currentStep {
            case .welcome:
                WelcomeView()
            case .preflight:
                PreflightView()
            case .install:
                InstallWizardView()
            case .channels:
                ChannelSetupView()
            case .monitor:
                HealthMonitorView()
            case .support:
                AISupportView()
            }
        }
    }
}

struct Sidebar: View {
    @EnvironmentObject var appState: AppState

    private let steps: [(AppState.Step, String, String)] = [
        (.welcome, "hand.wave", "Welcome"),
        (.preflight, "checkmark.shield", "Preflight Check"),
        (.install, "arrow.down.circle", "Install"),
        (.channels, "bubble.left.and.bubble.right", "Channels"),
        (.monitor, "heart.text.square", "Monitor"),
        (.support, "questionmark.bubble", "AI Support"),
    ]

    var body: some View {
        List(steps, id: \.0) { step, icon, label in
            Button {
                appState.currentStep = step
            } label: {
                Label(label, systemImage: icon)
            }
            .buttonStyle(.plain)
            .padding(.vertical, 4)
            .foregroundColor(appState.currentStep == step ? .accentColor : .primary)
        }
        .listStyle(.sidebar)
        .navigationTitle("ClawInstaller")
    }
}
