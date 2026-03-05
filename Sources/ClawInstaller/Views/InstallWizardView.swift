// InstallWizardView — Module 2: One-click OpenClaw Installation with Progress UI
// V2 Design: Single-page wizard with mascot, progress bar, terminal

import SwiftUI

struct InstallWizardView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var installer = OpenClawInstaller()
    var onComplete: ((String?) -> Void)?

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            switch installer.state {
            case .ready:
                readyView
            case .checking:
                checkingView
            case .installing:
                installingView
            case .success:
                DoneView(
                    installedVersion: installer.installedVersion,
                    installDuration: installer.installDuration
                )
            case .failed:
                failedView
            }
        }
        .padding(.horizontal, 40)
        .padding(.top, 32)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: installer.state) { _, newState in
            switch newState {
            case .success:
                appState.trackEvent("install_complete", module: "install", meta: [
                    "version": installer.installedVersion ?? "unknown",
                    "packageManager": installer.selectedPackageManager ?? "unknown"
                ])
            case .failed:
                appState.trackEvent("install_failed", module: "install", meta: [
                    "error": installer.errorMessage ?? "unknown",
                    "packageManager": installer.selectedPackageManager ?? "unknown"
                ])
            default:
                break
            }
        }
    }

    // MARK: - Ready View

    private var readyView: some View {
        VStack(spacing: 16) {
            Spacer()

            // Header
            VStack(spacing: 8) {
                Text("安裝 OpenClaw")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))

                Text("一鍵安裝 AI 命令列工具與 Gateway 服務")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            // What will be installed
            VStack(alignment: .leading, spacing: 8) {
                installItem(icon: "terminal.fill", color: .purple, title: "openclaw CLI", detail: "命令列工具")
                installItem(icon: "server.rack", color: .blue, title: "Gateway Server", detail: "本地 AI 閘道服務")
                installItem(icon: "folder.fill", color: .orange, title: "Config Directory", detail: "~/.openclaw/")
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
            )

            // Package manager info
            if let pm = installer.selectedPackageManager {
                HStack(spacing: 6) {
                    Text("使用")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: pmIcon(pm))
                            .font(.system(size: 11))
                        Text(pm)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(pmColor(pm))
                    Text("安裝")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            // Mascot
            mascotSection(message: "準備好了嗎？點擊下方按鈕，我幫你搞定一切！安裝過程大約一分鐘 ⚡️")

            Spacer()

            // CTA
            Button {
                appState.trackEvent("install_start", module: "install", meta: [
                    "packageManager": installer.selectedPackageManager ?? "unknown"
                ])
                Task { await installer.startInstall() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle.fill")
                    Text("開始安裝")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .clipShape(Capsule())
            .disabled(installer.selectedPackageManager == nil)
        }
    }

    // MARK: - Checking View

    private var checkingView: some View {
        VStack(spacing: 16) {
            Spacer()

            VStack(spacing: 8) {
                Text("正在檢查系統需求...")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                Text("這可能需要幾秒鐘")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                checkItem("Node.js", status: installer.checks.nodejs)
                checkItem("套件管理器", status: installer.checks.packageManager)
                checkItem("Xcode 命令列工具", status: installer.checks.xcodeTools)
                checkItem("網路連線", status: installer.checks.network)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
            )

            Spacer()

            ProgressView()
        }
    }

    // MARK: - Installing View

    private var installingView: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 8) {
                Text("正在安裝 OpenClaw ...")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                Text("這可能需要一分鐘")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            // Progress bar with percentage
            VStack(spacing: 6) {
                HStack {
                    Text(installer.statusMessage.isEmpty ? "正在安裝..." : installer.statusMessage)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(installer.progress * 100))%")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(.orange)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.15))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.orange)
                            .frame(width: geo.size.width * installer.progress)
                            .animation(.easeInOut(duration: 0.3), value: installer.progress)
                    }
                }
                .frame(height: 8)
            }

            // Terminal
            terminalView

            // Mascot
            mascotSection(message: "安裝快完成啦！你知道嗎？OpenClaw 的三位 Agent 可以同時幫你處理不同任務喔 💪")

            // Footer links
            HStack {
                Button("回報問題") {
                    reportIssue()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

                Spacer()

                Button("檢視完整紀錄") {
                    let logPath = FileManager.default.homeDirectoryForCurrentUser
                        .appendingPathComponent(".openclaw/logs")
                    NSWorkspace.shared.open(logPath)
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Failed View

    private var failedView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Error icon
                ZStack {
                    Circle()
                        .fill(.red.opacity(0.1))
                        .frame(width: 56, height: 56)
                    Image(systemName: "xmark")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.red)
                }

                VStack(spacing: 8) {
                    Text("安裝失敗")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))

                    if let error = installer.errorMessage {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }

                // Fix suggestion
                if let suggestion = installer.fixSuggestion {
                    fixSuggestionCard(suggestion)
                }

                // Error log
                if !installer.terminalLines.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("錯誤紀錄")
                                .font(.system(size: 13, weight: .semibold))
                            Spacer()
                            Button("複製") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(installer.terminalLines.joined(separator: "\n"), forType: .string)
                            }
                            .font(.caption)
                            .buttonStyle(.borderless)
                        }

                        ScrollView {
                            Text(installer.terminalLines.suffix(20).joined(separator: "\n"))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(Color(white: 0.8))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(height: 80)
                        .padding(10)
                        .background(Color(red: 0.1, green: 0.1, blue: 0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                // Action buttons
                HStack(spacing: 12) {
                    Button {
                        reportIssue()
                    } label: {
                        Text("回報問題")
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.bordered)

                    Button {
                        let errorMsg = installer.errorMessage ?? "未知錯誤"
                        let logTail = installer.terminalLines.suffix(20).joined(separator: "\n")
                        let pm = installer.selectedPackageManager ?? "unknown"
                        appState.pendingAIQuestion = """
                        安裝 OpenClaw 時遇到錯誤，請幫我解決。

                        錯誤訊息：\(errorMsg)
                        套件管理器：\(pm)

                        安裝 Log（最後 20 行）：
                        ```
                        \(logTail)
                        ```
                        """
                        appState.currentStep = .support
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "brain.head.profile")
                            Text("問 AI 助手")
                        }
                        .font(.system(size: 13))
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button {
                        Task { await installer.startInstall() }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                            Text("重試")
                                .fontWeight(.semibold)
                        }
                        .font(.system(size: 13))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
            }
        }
    }

    // MARK: - Shared Components

    private func mascotSection(message: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(nsImage: appLogoImage())
                .resizable()
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text("🦞 小龍蝦工頭說：")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.orange)
                Text(message)
                    .font(.system(size: 12))
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 1, green: 0.973, blue: 0.941)) // #FFF8F0
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 1, green: 0.878, blue: 0.698), lineWidth: 1) // #FFE0B2
        )
    }

    private var terminalView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(Array(installer.terminalLines.enumerated()), id: \.offset) { index, line in
                        terminalLine(line)
                            .id(index)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
            }
            .background(Color(red: 0.1, green: 0.1, blue: 0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .frame(maxHeight: .infinity)
            .onChange(of: installer.terminalLines.count) { _, _ in
                if let lastIndex = installer.terminalLines.indices.last {
                    withAnimation(.easeOut(duration: 0.1)) {
                        proxy.scrollTo(lastIndex, anchor: .bottom)
                    }
                }
            }
        }
    }

    private func terminalLine(_ line: String) -> some View {
        let (text, color) = parseTerminalLine(line)
        return Text(text)
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(color)
    }

    private func parseTerminalLine(_ line: String) -> (String, Color) {
        if line.hasPrefix("ERROR") || line.hasPrefix("✗") || line.contains("ERR!") {
            return (line, .red)
        } else if line.hasPrefix("WARNING") || line.hasPrefix("⚠") {
            return (line, .orange)
        } else if line.hasPrefix("✓") || line.contains("success") {
            return (line, .green)
        } else if line.hasPrefix("$") {
            return (line, .cyan)
        } else {
            return (line, Color(red: 0.72, green: 0.73, blue: 0.71)) // #B8B9B6
        }
    }

    private func installItem(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.1))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func checkItem(_ title: String, status: CheckStatus) -> some View {
        HStack(spacing: 12) {
            Group {
                switch status {
                case .checking:
                    ProgressView()
                        .controlSize(.small)
                case .passed:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                case .failed:
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                case .warning:
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                case .pending:
                    Image(systemName: "circle")
                        .foregroundStyle(.secondary.opacity(0.3))
                }
            }
            .frame(width: 20)

            Text(title)
                .font(.system(size: 13))

            Spacer()

            if case .passed = status {
                Text("OK")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.green)
            }
        }
    }

    private func pmIcon(_ pm: String) -> String {
        switch pm {
        case "pnpm": return "cube.fill"
        case "bun": return "hare.fill"
        case "npm": return "shippingbox.fill"
        default: return "shippingbox.fill"
        }
    }

    private func pmColor(_ pm: String) -> Color {
        switch pm {
        case "pnpm": return .orange
        case "bun": return .pink
        case "npm": return .red
        default: return .blue
        }
    }

    private func fixSuggestionCard(_ suggestion: FixSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("建議修復方式")
                    .font(.system(size: 13, weight: .semibold))
            }

            Text(suggestion.description)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            if suggestion.canAutoFix {
                Button {
                    Task { await installer.applyFix(suggestion) }
                } label: {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text("一鍵修復")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }

            DisclosureGroup("進階：手動執行指令") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        HStack(spacing: 0) {
                            Text("$ ").foregroundStyle(.green)
                            Text(suggestion.command)
                        }
                        .font(.system(size: 11, design: .monospaced))
                        Spacer()
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(suggestion.command, forType: .string)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .padding(.top, 4)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color.yellow.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @State private var reportSent = false

    private func reportIssue() {
        let logText = installer.terminalLines.suffix(30).joined(separator: "\n")
        let errorMsg = installer.errorMessage ?? "未知錯誤"
        let pm = installer.selectedPackageManager ?? "unknown"

        let title = "安裝失敗：\(errorMsg)"
        let body = """
        **錯誤訊息**：\(errorMsg)
        **套件管理器**：\(pm)
        **macOS**：\(ProcessInfo.processInfo.operatingSystemVersionString)

        <details>
        <summary>安裝 Log（最後 30 行）</summary>

        ```
        \(logText)
        ```
        </details>
        """

        var components = URLComponents(string: "https://github.com/clawinstaller/claw-installer/issues/new")!
        components.queryItems = [
            URLQueryItem(name: "title", value: title),
            URLQueryItem(name: "body", value: body),
        ]
        if let url = components.url {
            NSWorkspace.shared.open(url)
        }
        reportSent = true
    }
}

// MARK: - Install Stage

enum InstallStage: Int, CaseIterable {
    case checking = 0
    case downloading
    case installing
    case verifying

    var label: String {
        switch self {
        case .checking: return "檢查"
        case .downloading: return "下載"
        case .installing: return "安裝"
        case .verifying: return "驗證"
        }
    }

    var icon: String {
        switch self {
        case .checking: return "magnifyingglass"
        case .downloading: return "arrow.down"
        case .installing: return "square.and.arrow.down"
        case .verifying: return "checkmark.shield"
        }
    }

    var description: String {
        switch self {
        case .checking: return "正在檢查系統需求..."
        case .downloading: return "正在下載 OpenClaw..."
        case .installing: return "正在安裝 OpenClaw..."
        case .verifying: return "正在驗證安裝..."
        }
    }
}

// MARK: - Check Status

enum CheckStatus {
    case pending
    case checking
    case passed
    case failed
    case warning
}

struct SystemChecks {
    var nodejs: CheckStatus = .pending
    var packageManager: CheckStatus = .pending
    var xcodeTools: CheckStatus = .pending
    var network: CheckStatus = .pending
}

// MARK: - Fix Suggestion

struct FixSuggestion {
    let errorType: ErrorType
    let description: String
    let command: String
    let canAutoFix: Bool

    enum ErrorType {
        case nodeNotInstalled
        case xcodeToolsMissing
        case networkError
        case permissionDenied
        case packageManagerMissing
        case unknown
    }
}

// MARK: - Installer

@MainActor
class OpenClawInstaller: ObservableObject {
    enum State {
        case ready
        case checking
        case installing
        case success
        case failed
    }

    @Published var state: State = .ready
    @Published var currentStage: InstallStage = .checking
    @Published var progress: Double = 0
    @Published var statusMessage: String = ""
    @Published var terminalLines: [String] = []
    @Published var errorMessage: String?
    @Published var installedVersion: String?
    @Published var selectedPackageManager: String?
    @Published var checks = SystemChecks()
    @Published var fixSuggestion: FixSuggestion?
    @Published var installDuration: TimeInterval = 0

    var pnpmHomePath: String?
    private var installTask: Task<Void, Never>?
    private var installStartTime: Date?

    init() {
        detectPackageManager()
    }

    private func detectPackageManager() {
        Task {
            for pm in ["pnpm", "bun", "npm"] {
                let result = await ShellRunner.run("which \(pm) 2>/dev/null")
                if result.success && !result.stdout.isEmpty {
                    selectedPackageManager = pm
                    return
                }
            }
        }
    }

    func startInstall() async {
        state = .checking
        checks = SystemChecks()
        fixSuggestion = nil
        errorMessage = nil
        terminalLines = []
        progress = 0
        installStartTime = Date()

        let checksPass = await runSystemChecks()

        if checksPass {
            await install()
        } else {
            state = .failed
        }
    }

    private func runSystemChecks() async -> Bool {
        appendLine("$ Running system checks...")
        appendLine("")

        checks.nodejs = .checking
        let nodeResult = await ShellRunner.run("node --version 2>/dev/null")
        if nodeResult.success {
            checks.nodejs = .passed
            appendLine("✓ Node.js \(nodeResult.stdout)")
        } else {
            checks.nodejs = .failed
            appendLine("✗ Node.js not found")
            errorMessage = "尚未安裝 Node.js"
            fixSuggestion = FixSuggestion(
                errorType: .nodeNotInstalled,
                description: "OpenClaw 需要 Node.js 才能運行。點擊「一鍵修復」自動安裝。",
                command: "brew install node",
                canAutoFix: true
            )
            return false
        }

        checks.packageManager = .checking
        if let pm = selectedPackageManager {
            let pmResult = await ShellRunner.run("\(pm) --version 2>/dev/null")
            if pmResult.success {
                checks.packageManager = .passed
                appendLine("✓ \(pm) \(pmResult.stdout)")
            } else {
                checks.packageManager = .failed
                appendLine("✗ \(pm) not found")
                errorMessage = "找不到套件管理器"
                fixSuggestion = FixSuggestion(
                    errorType: .packageManagerMissing,
                    description: "建議使用 pnpm 作為套件管理器。點擊「一鍵修復」自動安裝。",
                    command: "npm install -g pnpm",
                    canAutoFix: true
                )
                return false
            }
        } else {
            checks.packageManager = .failed
            appendLine("✗ No package manager found")
            errorMessage = "找不到套件管理器（npm、pnpm 或 bun）"
            fixSuggestion = FixSuggestion(
                errorType: .packageManagerMissing,
                description: "安裝 Node.js 即會自帶 npm 套件管理器。",
                command: "brew install node",
                canAutoFix: true
            )
            return false
        }

        checks.xcodeTools = .checking
        let xcodeResult = await ShellRunner.run("xcode-select -p 2>/dev/null")
        if xcodeResult.success && !xcodeResult.stdout.isEmpty {
            checks.xcodeTools = .passed
            appendLine("✓ Xcode Command Line Tools")
        } else {
            checks.xcodeTools = .warning
            appendLine("⚠ Xcode CLI Tools not detected (may be optional)")
        }

        checks.network = .checking
        let networkResult = await ShellRunner.run("curl -sI https://registry.npmjs.org 2>/dev/null | head -1")
        if networkResult.success && networkResult.stdout.contains("200") {
            checks.network = .passed
            appendLine("✓ Network connection")
        } else {
            checks.network = .failed
            appendLine("✗ Cannot reach npm registry")
            errorMessage = "網路連線失敗"
            fixSuggestion = FixSuggestion(
                errorType: .networkError,
                description: "無法連線到 npm 套件庫，請確認你的網路連線。",
                command: "curl -I https://registry.npmjs.org",
                canAutoFix: false
            )
            return false
        }

        appendLine("")
        appendLine("✓ All checks passed!")
        appendLine("")

        return true
    }

    func install() async {
        guard let pm = selectedPackageManager else {
            errorMessage = "找不到套件管理器"
            state = .failed
            return
        }

        state = .installing

        installTask = Task {
            do {
                await setStage(.downloading, progress: 0.2)
                appendLine("$ \(pm) install -g openclaw@latest")
                appendLine("")

                let envPrefix: String
                if let pnpmHome = pnpmHomePath, pm == "pnpm" {
                    envPrefix = "export PNPM_HOME=\"\(pnpmHome)\" && export PATH=\"$PNPM_HOME:$PATH\" && "
                } else {
                    envPrefix = ""
                }
                let installCmd = "\(envPrefix)\(pm) install -g openclaw@latest 2>&1"
                var hasError = false
                var errorOutput = ""

                let result = await ShellRunner.runWithStreaming(
                    installCmd,
                    onOutput: { [weak self] output in
                        guard let self = self else { return }
                        self.appendLine(output)
                        let lower = output.lowercased()
                        if lower.contains("resolving") || lower.contains("resolved") {
                            self.progress = min(self.progress + 0.05, 0.35)
                            self.statusMessage = "正在解析套件依賴..."
                        } else if lower.contains("downloading") || lower.contains("downloaded") {
                            self.progress = min(self.progress + 0.05, 0.5)
                            self.statusMessage = "正在下載套件..."
                        } else if lower.contains("progress:") {
                            self.progress = min(self.progress + 0.02, 0.6)
                        } else if lower.contains("building") || lower.contains("linking") {
                            self.setStage(.installing, progress: min(self.progress + 0.05, 0.75))
                            self.statusMessage = "正在安裝套件..."
                        } else if lower.contains("added") || lower.contains("packages") {
                            self.progress = min(self.progress + 0.1, 0.85)
                            self.statusMessage = "套件安裝中，即將完成..."
                        }
                    },
                    onError: { [weak self] error in
                        self?.appendLine(error)
                        hasError = true
                        errorOutput += error
                    }
                )

                if !result.success || hasError {
                    throw InstallError.installFailed(result.stderr.isEmpty ? errorOutput : result.stderr)
                }

                await setStage(.verifying, progress: 0.9)
                appendLine("")
                appendLine("$ openclaw --version")

                try await Task.sleep(nanoseconds: 500_000_000)

                let verifyResult = await ShellRunner.run("openclaw --version 2>/dev/null")
                if verifyResult.success && !verifyResult.stdout.isEmpty {
                    let version = verifyResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                    appendLine(version)
                    installedVersion = version
                    progress = 1.0
                    if let start = installStartTime {
                        installDuration = Date().timeIntervalSince(start)
                    }
                    appendLine("")
                    appendLine("✓ OpenClaw installed successfully!")
                    state = .success
                } else {
                    throw InstallError.verificationFailed
                }

            } catch is CancellationError {
                appendLine("")
                appendLine("✗ Installation cancelled")
                state = .ready
            } catch let error as InstallError {
                handleInstallError(error)
            } catch {
                errorMessage = error.localizedDescription
                appendLine("")
                appendLine("✗ \(error.localizedDescription)")
                state = .failed
            }
        }

        await installTask?.value
    }

    private func handleInstallError(_ error: InstallError) {
        appendLine("")
        appendLine("✗ \(error.localizedDescription)")

        let errorText = terminalLines.joined(separator: "\n").lowercased()

        if errorText.contains("err_pnpm_no_global_bin_dir") || errorText.contains("pnpm setup") {
            errorMessage = "pnpm 全域目錄未設定"
            fixSuggestion = FixSuggestion(
                errorType: .packageManagerMissing,
                description: "pnpm 需要先初始化全域目錄。點擊「一鍵修復」即可解決。",
                command: "pnpm setup",
                canAutoFix: true
            )
        } else if errorText.contains("eacces") || errorText.contains("permission denied") {
            errorMessage = "安裝權限不足"
            fixSuggestion = FixSuggestion(
                errorType: .permissionDenied,
                description: "npm 全域套件需要正確的權限設定。點擊「自動修復」即可解決。",
                command: "mkdir -p ~/.npm-global && npm config set prefix ~/.npm-global",
                canAutoFix: true
            )
        } else if errorText.contains("enotfound") || (errorText.contains("network") && !errorText.contains("pnpm")) {
            errorMessage = "網路連線失敗"
            fixSuggestion = FixSuggestion(
                errorType: .networkError,
                description: "無法下載套件，請檢查你的網路連線後重試。",
                command: "ping -c 3 registry.npmjs.org",
                canAutoFix: false
            )
        } else if errorText.contains("gyp") || errorText.contains("node-pre-gyp") {
            errorMessage = "原生模組編譯失敗"
            fixSuggestion = FixSuggestion(
                errorType: .xcodeToolsMissing,
                description: "部分套件需要 Xcode Command Line Tools 才能編譯。",
                command: "xcode-select --install",
                canAutoFix: true
            )
        } else {
            errorMessage = error.localizedDescription
        }

        state = .failed
    }

    func applyFix(_ suggestion: FixSuggestion) async {
        state = .installing
        appendLine("")
        appendLine("$ 正在修復：\(suggestion.command)")

        let result = await ShellRunner.runWithStreaming(
            suggestion.command,
            onOutput: { [weak self] output in
                self?.appendLine(output)
            },
            onError: { [weak self] error in
                self?.appendLine(error)
            }
        )

        if suggestion.errorType == .packageManagerMissing && selectedPackageManager == "pnpm" {
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            let pnpmHome = "\(home)/.local/share/pnpm"
            try? FileManager.default.createDirectory(atPath: pnpmHome, withIntermediateDirectories: true)
            pnpmHomePath = pnpmHome
            appendLine("✓ 已設定 PNPM_HOME: \(pnpmHome)")
            appendLine("")
            detectPackageManager()
            try? await Task.sleep(nanoseconds: 500_000_000)
            await startInstall()
        } else if result.success {
            appendLine("✓ 修復完成")
            appendLine("")
            detectPackageManager()
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await startInstall()
        } else {
            appendLine("✗ 修復失敗：\(result.stderr)")
            state = .failed
        }
    }

    func cancel() {
        installTask?.cancel()
        state = .ready
    }

    private func setStage(_ stage: InstallStage, progress: Double) {
        currentStage = stage
        self.progress = progress
        statusMessage = stage.description
    }

    private func appendLine(_ line: String) {
        let lines = line.split(separator: "\n", omittingEmptySubsequences: false)
        for l in lines {
            let trimmed = String(l).trimmingCharacters(in: .init(charactersIn: "\r"))
            if !trimmed.isEmpty || terminalLines.last != "" {
                terminalLines.append(trimmed)
            }
        }
        if terminalLines.count > 500 {
            terminalLines.removeFirst(100)
        }
    }

    enum InstallError: LocalizedError {
        case installFailed(String)
        case verificationFailed

        var errorDescription: String? {
            switch self {
            case .installFailed(let stderr):
                let truncated = stderr.prefix(150)
                return "Installation failed: \(truncated)"
            case .verificationFailed:
                return "Verification failed: openclaw command not found"
            }
        }
    }
}
