// ClawInstaller — macOS Setup Wizard for OpenClaw

import SwiftUI

@main
struct ClawInstallerApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appState)
                .frame(
                    minWidth: appState.currentStep == .monitor ? 960 : 760,
                    minHeight: appState.currentStep == .monitor ? 640 : 540
                )
                .frame(
                    width: appState.currentStep == .monitor ? 960 : 760,
                    height: appState.currentStep == .monitor ? 640 : 540
                )
                .preferredColorScheme(.light)
                .animation(.easeInOut(duration: 0.3), value: appState.currentStep)
        }
        .windowResizability(.contentSize)

        MenuBarExtra("OpenClaw", systemImage: "ant.fill") {
            MenuBarView()
                .environmentObject(appState)
        }
    }
}

struct MainView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.currentStep == .monitor {
                // Post-install: sidebar layout
                NavigationSplitView(columnVisibility: .constant(.all)) {
                    HomeSidebar()
                        .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 220)
                } detail: {
                    homeContent
                }
                .navigationSplitViewStyle(.balanced)
            } else {
                // Wizard flow: single-page, no sidebar
                wizardContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(nsColor: .windowBackgroundColor))
            }
        }
    }

    @ViewBuilder
    private var wizardContent: some View {
        switch appState.currentStep {
        case .welcome:
            WelcomeView()
        case .preflight:
            PreflightView()
        case .install:
            InstallWizardView()
        case .channels:
            ChannelSetupView()
        case .support:
            AISupportView()
        default:
            WelcomeView()
        }
    }

    @ViewBuilder
    private var homeContent: some View {
        switch appState.homeTab {
        case .status:
            HealthMonitorView()
        case .channels:
            ChannelSetupView()
        case .ai:
            AISupportView()
        }
    }
}

// MARK: - Home Sidebar (post-install)

struct HomeSidebar: View {
    @EnvironmentObject var appState: AppState

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Logo
            HStack(spacing: 8) {
                Image(nsImage: appLogoImage())
                    .resizable()
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                Text("ClawInstaller")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
            }
            .padding(.horizontal, 12)
            .padding(.top, 16)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Nav items
            VStack(spacing: 2) {
                sidebarItem(.status, icon: "heart.text.square", label: "系統狀態")
                sidebarItem(.channels, icon: "bubble.left.and.bubble.right", label: "頻道設定")
                sidebarItem(.ai, icon: "brain.head.profile", label: "AI 助手")
            }
            .padding(.horizontal, 12)

            Spacer()

            Text("v\(appVersion)")
                .font(.caption2)
                .foregroundStyle(.secondary.opacity(0.6))
                .padding(.bottom, 8)
        }
        .navigationTitle("")
    }

    private func sidebarItem(_ tab: AppState.HomeTab, icon: String, label: String) -> some View {
        Button {
            appState.homeTab = tab
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .frame(width: 20)
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background(appState.homeTab == tab ? Color.accentColor.opacity(0.12) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .foregroundStyle(appState.homeTab == tab ? .primary : .secondary)
    }
}
