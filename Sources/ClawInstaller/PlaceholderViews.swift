import SwiftUI

// Note: InstallWizardView is now in Views/InstallWizardView.swift

// MARK: - Module 4: Health Monitor (placeholder)

struct HealthMonitorView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            Text("Health Monitor")
                .font(.title.bold())
            Text("Gateway status and daemon control")
                .foregroundStyle(.secondary)

            GroupBox("Gateway") {
                HStack {
                    Circle().fill(.orange).frame(width: 10, height: 10)
                    Text("Status: Unknown")
                    Spacer()
                    Button("Check") {}
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
                .padding(8)
            }

            Text("Coming soon — Module 4")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(40)
    }
}

// MARK: - Module 5: AI Support (placeholder)

struct AISupportView: View {
    @State private var userMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Support")
                .font(.title.bold())
            Text("Ask questions about OpenClaw installation and setup")
                .foregroundStyle(.secondary)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    AssistantBubble(text: "Hi! I'm your OpenClaw setup assistant. Ask me anything about installation, configuration, or troubleshooting.")
                }
            }
            .frame(maxHeight: .infinity)

            HStack {
                TextField("Ask a question...", text: $userMessage)
                    .textFieldStyle(.roundedBorder)
                Button("Send") {}
                    .buttonStyle(.borderedProminent)
                    .disabled(true)
            }

            Text("Coming soon — Module 5 (Claude API)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }
}

struct AssistantBubble: View {
    let text: String

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "brain.head.profile")
                .foregroundStyle(.purple)
            Text(text)
                .padding(10)
                .background(.purple.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - Menu Bar

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(appState.gatewayRunning ? "Gateway Running" : "Gateway Stopped",
                  systemImage: appState.gatewayRunning ? "circle.fill" : "circle")
                .foregroundStyle(appState.gatewayRunning ? .green : .red)

            Divider()

            Button("Check Status") {
                // TODO: run openclaw doctor
            }

            Button("Open ClawInstaller") {
                NSApplication.shared.activate(ignoringOtherApps: true)
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(8)
    }
}
