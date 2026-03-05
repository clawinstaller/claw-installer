import SwiftUI

// Note: Main views are now in Views/ directory:
// - InstallWizardView.swift
// - HealthMonitorView.swift
// - LLMSetupView.swift
// - DoneView.swift

// MARK: - Module 5: AI Support

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String  // "user" or "assistant"
    let content: String
}

struct AISupportView: View {
    @EnvironmentObject var appState: AppState
    @State private var userMessage = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(role: "assistant", content: "嗨！我是 ClawInstaller 安裝助手。\n安裝 OpenClaw 遇到問題？直接問我！")
    ]
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "bubble.left.and.text.bubble.right")
                    .font(.title2)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading) {
                    Text("安裝助手")
                        .font(.title2.bold())
                    Text("AI 驅動 · 免費使用")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()

            Divider()

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(messages) { msg in
                            if msg.role == "assistant" {
                                AssistantBubble(text: msg.content)
                            } else {
                                UserBubble(text: msg.content)
                            }
                        }

                        if isLoading {
                            HStack(spacing: 8) {
                                Image(systemName: "brain.head.profile")
                                    .foregroundStyle(.orange)
                                ProgressView()
                                    .controlSize(.small)
                                Text("思考中...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .id("loading")
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) {
                    withAnimation {
                        proxy.scrollTo(messages.last?.id, anchor: .bottom)
                    }
                }
                .onChange(of: isLoading) {
                    if isLoading {
                        withAnimation {
                            proxy.scrollTo("loading", anchor: .bottom)
                        }
                    }
                }
            }

            // Error banner
            if let error {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                    Text(error)
                        .font(.caption)
                    Spacer()
                    Button("關閉") { self.error = nil }
                        .buttonStyle(.plain)
                        .font(.caption)
                }
                .padding(8)
                .background(.red.opacity(0.1))
                .foregroundStyle(.red)
            }

            Divider()

            // Input
            HStack(spacing: 8) {
                TextField("輸入你的問題...", text: $userMessage)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { sendMessage() }
                    .disabled(isLoading)

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(userMessage.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
            }
            .padding()
        }
        .onAppear {
            if let pending = appState.pendingAIQuestion {
                appState.pendingAIQuestion = nil
                userMessage = pending
                // Auto-send after a brief delay so UI renders first
                Task {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    await MainActor.run { sendMessage() }
                }
            }
        }
    }

    private func sendMessage() {
        let text = userMessage.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        messages.append(ChatMessage(role: "user", content: text))
        userMessage = ""
        isLoading = true
        error = nil

        Task {
            do {
                let context = buildContext()
                let history = messages.dropLast().map {
                    BackendService.HistoryMessage(role: $0.role, content: $0.content)
                }

                let response = try await BackendService.shared.sendMessage(
                    message: text,
                    context: context,
                    history: Array(history.suffix(10)) // Keep last 10 for context
                )

                await MainActor.run {
                    messages.append(ChatMessage(role: "assistant", content: response))
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func buildContext() -> BackendService.InstallContext {
        let checker = appState.preflightChecker
        let config = ConfigManager.shared

        var channels: [String] = []
        if config.hasTelegramConfig { channels.append("telegram") }
        if config.hasDiscordConfig { channels.append("discord") }
        if config.hasWhatsAppConfig { channels.append("whatsapp") }

        let preflightResults = checker.checks.map { check in
            BackendService.PreflightResult(
                name: check.name,
                status: check.status == .pass ? "pass" : check.status == .fail ? "fail" : "warn",
                detail: check.detail
            )
        }

        return BackendService.InstallContext(
            nodeVersion: checker.detectedNodeVersion,
            packageManager: checker.detectedPackageManager,
            arch: checker.detectedArch,
            preflightResults: preflightResults.isEmpty ? nil : preflightResults,
            installedVersion: nil,
            channels: channels.isEmpty ? nil : channels,
            gatewayStatus: appState.gatewayRunning ? "running" : "stopped"
        )
    }
}

struct AssistantBubble: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "brain.head.profile")
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 24)
            Text(text)
                .textSelection(.enabled)
                .padding(10)
                .background(.orange.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            Spacer(minLength: 40)
        }
    }
}

struct UserBubble: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Spacer(minLength: 40)
            Text(text)
                .padding(10)
                .background(.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            Image(systemName: "person.circle")
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)
        }
    }
}

// MARK: - Menu Bar Extra

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @State private var isCheckingStatus = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Status header
            HStack(spacing: 8) {
                Circle()
                    .fill(appState.gatewayRunning ? .green : .red)
                    .frame(width: 8, height: 8)
                Text(appState.gatewayRunning ? "Gateway Running" : "Gateway Stopped")
                    .font(.headline)
            }
            .padding(.bottom, 4)

            Divider()

            // Quick actions
            Button {
                checkStatus()
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Check Status")
                    if isCheckingStatus {
                        Spacer()
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            }
            .disabled(isCheckingStatus)

            if appState.gatewayRunning {
                Button {
                    Task { await stopGateway() }
                } label: {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("Stop Gateway")
                    }
                }
                
                Button {
                    Task { await restartGateway() }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Restart Gateway")
                    }
                }
            } else {
                Button {
                    Task { await startGateway() }
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Gateway")
                    }
                }
            }

            Divider()

            Button {
                NSApplication.shared.activate(ignoringOtherApps: true)
                if let window = NSApplication.shared.windows.first {
                    window.makeKeyAndOrderFront(nil)
                }
            } label: {
                HStack {
                    Image(systemName: "macwindow")
                    Text("Open ClawInstaller")
                }
            }

            Button {
                let logPath = FileManager.default.homeDirectoryForCurrentUser
                    .appendingPathComponent(".openclaw/logs")
                NSWorkspace.shared.open(logPath)
            } label: {
                HStack {
                    Image(systemName: "doc.text")
                    Text("View Logs")
                }
            }

            Divider()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack {
                    Image(systemName: "power")
                    Text("Quit")
                }
            }
        }
        .padding(8)
        .frame(width: 200)
        .onAppear {
            checkStatus()
        }
    }
    
    private func checkStatus() {
        isCheckingStatus = true
        Task {
            let result = await ShellRunner.run("curl -s -o /dev/null -w '%{http_code}' http://localhost:18789/health 2>/dev/null || echo '000'")
            let statusCode = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            await MainActor.run {
                appState.gatewayRunning = statusCode == "200"
                isCheckingStatus = false
            }
        }
    }
    
    private func startGateway() async {
        _ = await ShellRunner.run("openclaw gateway start 2>&1")
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        checkStatus()
    }
    
    private func stopGateway() async {
        _ = await ShellRunner.run("openclaw gateway stop 2>&1")
        await MainActor.run {
            appState.gatewayRunning = false
        }
    }
    
    private func restartGateway() async {
        _ = await ShellRunner.run("openclaw gateway restart 2>&1")
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        checkStatus()
    }
}
