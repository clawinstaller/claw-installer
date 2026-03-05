// InstallWizardView — Module 2: One-click OpenClaw Installation with Progress UI
// Screen 4: Real-time progress bar, terminal output, error detection + auto-fix

import SwiftUI

struct InstallWizardView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var installer = OpenClawInstaller()
    var onComplete: ((String?) -> Void)?  // Called with version on success
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Content based on state
            Group {
                switch installer.state {
                case .ready:
                    readyView
                case .checking:
                    checkingView
                case .installing:
                    installingView
                case .success:
                    successView
                case .failed:
                    failedView
                }
            }
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

            Divider()

            // Footer
            footer
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("安裝 OpenClaw")
                    .font(.title2.bold())
                
                Text(headerSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Package manager badge
            if let pm = installer.selectedPackageManager {
                HStack(spacing: 6) {
                    Image(systemName: pmIcon(pm))
                    Text(pm)
                }
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(pmColor(pm).opacity(0.1))
                .foregroundStyle(pmColor(pm))
                .clipShape(Capsule())
            }
        }
        .padding()
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
    
    private var headerSubtitle: String {
        switch installer.state {
        case .ready:
            return "準備安裝 OpenClaw CLI"
        case .checking:
            return "正在檢查系統需求..."
        case .installing:
            return installer.currentStage.description
        case .success:
            return "安裝完成"
        case .failed:
            return "安裝過程遇到問題"
        }
    }
    
    // MARK: - Ready View
    
    private var readyView: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue)
            }
            
            // Info
            VStack(spacing: 8) {
                Text("OpenClaw CLI")
                    .font(.title3.bold())
                
                Text("AI 驅動的命令列助手")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // What will be installed
            VStack(alignment: .leading, spacing: 12) {
                Text("將會安裝：")
                    .font(.subheadline.bold())

                installItem(icon: "terminal.fill", color: .purple, title: "openclaw CLI", detail: "命令列工具")
                installItem(icon: "server.rack", color: .blue, title: "Gateway Server", detail: "本地 AI 閘道服務")
                installItem(icon: "folder.fill", color: .orange, title: "Config Directory", detail: "~/.openclaw/")
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Install command preview
            if let pm = installer.selectedPackageManager {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("安裝指令：")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString("\(pm) install -g openclaw@latest", forType: .string)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    HStack(spacing: 0) {
                        Text("$ ")
                            .foregroundStyle(.green)
                        Text("\(pm) install -g openclaw@latest")
                    }
                    .font(.system(size: 12, design: .monospaced))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding()
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
                    .font(.subheadline.bold())
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Checking View
    
    private var checkingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("正在檢查系統需求")
                .font(.headline)
            
            // Check items
            VStack(alignment: .leading, spacing: 12) {
                checkItem("Node.js", status: installer.checks.nodejs)
                checkItem("套件管理器", status: installer.checks.packageManager)
                checkItem("Xcode 命令列工具", status: installer.checks.xcodeTools)
                checkItem("網路連線", status: installer.checks.network)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
    }
    
    private func checkItem(_ title: String, status: CheckStatus) -> some View {
        HStack(spacing: 12) {
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
                    .foregroundStyle(.secondary)
            }
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            if case .passed = status {
                Text("OK")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
    }
    
    // MARK: - Installing View
    
    private var installingView: some View {
        VStack(spacing: 16) {
            // Progress stages (compact)
            stageProgressBar

            // Progress bar + percentage
            HStack(spacing: 12) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.2))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * installer.progress)
                            .animation(.easeInOut(duration: 0.3), value: installer.progress)
                    }
                }
                .frame(height: 6)

                Text("\(Int(installer.progress * 100))%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.blue)
                    .frame(width: 40, alignment: .trailing)
            }
            .padding(.horizontal)

            // Status message
            if !installer.statusMessage.isEmpty {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text(installer.statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Terminal output — larger and prominent
            terminalView
        }
        .padding()
    }
    
    private var stageProgressBar: some View {
        HStack(spacing: 0) {
            ForEach(InstallStage.allCases, id: \.self) { stage in
                stageIndicator(stage)
                
                if stage != InstallStage.allCases.last {
                    Rectangle()
                        .fill(stage.rawValue < installer.currentStage.rawValue ? Color.green : Color.secondary.opacity(0.2))
                        .frame(height: 2)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func stageIndicator(_ stage: InstallStage) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(stageColor(stage))
                    .frame(width: 32, height: 32)
                
                if stage == installer.currentStage && installer.state == .installing {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                } else {
                    Image(systemName: stageIcon(stage))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            
            Text(stage.label)
                .font(.caption2)
                .foregroundStyle(stage == installer.currentStage ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func stageColor(_ stage: InstallStage) -> Color {
        if stage.rawValue < installer.currentStage.rawValue {
            return .green
        } else if stage == installer.currentStage {
            return .blue
        } else {
            return .secondary.opacity(0.3)
        }
    }
    
    private func stageIcon(_ stage: InstallStage) -> String {
        if stage.rawValue < installer.currentStage.rawValue {
            return "checkmark"
        }
        return stage.icon
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
                .padding(10)
            }
            .background(Color(red: 0.1, green: 0.1, blue: 0.12))
            .clipShape(RoundedRectangle(cornerRadius: 8))
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
            .font(.system(size: 13, design: .monospaced))
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
            return (line, Color(white: 0.8))
        }
    }
    
    // MARK: - Success View
    
    private var successView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(.green.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.green)
            }
            
            VStack(spacing: 8) {
                Text("安裝完成！")
                    .font(.title3.bold())

                if let version = installer.installedVersion {
                    Text("OpenClaw \(version) 已就緒")
                        .foregroundStyle(.secondary)
                }
            }
            
            // Quick start command
            VStack(alignment: .leading, spacing: 8) {
                Text("快速開始：")
                    .font(.subheadline.bold())
                
                HStack {
                    HStack(spacing: 0) {
                        Text("$ ")
                            .foregroundStyle(.green)
                        Text("openclaw")
                    }
                    .font(.system(size: 13, design: .monospaced))
                    
                    Spacer()
                    
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString("openclaw", forType: .string)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
                .padding(10)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Quick actions
            HStack(spacing: 12) {
                quickActionButton(icon: "terminal.fill", title: "開啟終端機") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"))
                }

                quickActionButton(icon: "book.fill", title: "使用說明") {
                    NSWorkspace.shared.open(URL(string: "https://docs.openclaw.ai")!)
                }
            }
        }
        .padding()
    }
    
    private func quickActionButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Failed View
    
    private var failedView: some View {
        ScrollView {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(.red.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.red)
                }
                
                VStack(spacing: 8) {
                    Text("安裝失敗")
                        .font(.title3.bold())
                    
                    if let error = installer.errorMessage {
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Auto-fix suggestions
                if let suggestion = installer.fixSuggestion {
                    fixSuggestionCard(suggestion)
                }
                
                // Error log
                if !installer.terminalLines.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("錯誤紀錄")
                                .font(.subheadline.bold())
                            Spacer()
                            Button("複製") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(installer.terminalLines.joined(separator: "\n"), forType: .string)
                            }
                            .font(.caption)
                            .buttonStyle(.borderless)
                        }
                        
                        ScrollView {
                            Text(installer.terminalLines.suffix(30).joined(separator: "\n"))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(Color(white: 0.8))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(height: 120)
                        .padding(8)
                        .background(Color(red: 0.1, green: 0.1, blue: 0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
    }
    
    private func fixSuggestionCard(_ suggestion: FixSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("建議修復方式")
                    .font(.subheadline.bold())
            }

            Text(suggestion.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Auto-fix button (primary action for beginners)
            if suggestion.canAutoFix {
                Button {
                    Task { await installer.applyFix(suggestion) }
                } label: {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text("一鍵修復")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }

            // Fix command (collapsed, for advanced users)
            DisclosureGroup("進階：手動執行指令") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("在終端機中執行以下指令：")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        HStack(spacing: 0) {
                            Text("$ ")
                                .foregroundStyle(.green)
                            Text(suggestion.command)
                        }
                        .font(.system(size: 12, design: .monospaced))

                        Spacer()

                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(suggestion.command, forType: .string)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc")
                                Text("複製")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(10)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                    Text("複製後打開「終端機」App 貼上並按 Enter 執行")
                        .font(.caption2)
                        .foregroundStyle(.secondary.opacity(0.7))
                }
                .padding(.top, 4)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.yellow.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack {
            switch installer.state {
            case .ready:
                Spacer()
                Button("開始安裝") {
                    appState.trackEvent("install_start", module: "install", meta: [
                        "packageManager": installer.selectedPackageManager ?? "unknown"
                    ])
                    Task { await installer.startInstall() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(installer.selectedPackageManager == nil)
                
            case .checking:
                Spacer()
                ProgressView()
                    .controlSize(.small)
                
            case .installing:
                Button("取消") {
                    installer.cancel()
                }
                Spacer()
                
            case .success:
                Spacer()
                Button("繼續") {
                    onComplete?(installer.installedVersion)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
            case .failed:
                Button {
                    reportIssue()
                } label: {
                    Label("回報問題", systemImage: "envelope.fill")
                }

                Button {
                    // Auto-populate AI question with error context
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
                    Label("問 AI 助手", systemImage: "questionmark.bubble")
                }
                .buttonStyle(.bordered)

                Spacer()
                Button("重試") {
                    Task { await installer.startInstall() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
    
    @State private var reportSent = false

    private func reportIssue() {
        let logText = installer.terminalLines.suffix(30).joined(separator: "\n")
        let errorMsg = installer.errorMessage ?? "未知錯誤"
        let pm = installer.selectedPackageManager ?? "unknown"

        appState.trackEvent("install_failed", module: "install", meta: [
            "error": errorMsg,
            "packageManager": pm,
            "log": String(logText.prefix(2000)),
        ])

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

        // Use URLComponents to properly encode Chinese characters
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

    /// Set after pnpm fix to inject PNPM_HOME into install command
    var pnpmHomePath: String?

    private var installTask: Task<Void, Never>?
    
    init() {
        detectPackageManager()
    }
    
    private func detectPackageManager() {
        Task {
            // Prefer pnpm > bun > npm
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
        
        // Run system checks
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
        
        // Check Node.js
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
        
        // Check package manager
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
        
        // Check Xcode CLI tools
        checks.xcodeTools = .checking
        let xcodeResult = await ShellRunner.run("xcode-select -p 2>/dev/null")
        if xcodeResult.success && !xcodeResult.stdout.isEmpty {
            checks.xcodeTools = .passed
            appendLine("✓ Xcode Command Line Tools")
        } else {
            checks.xcodeTools = .warning
            appendLine("⚠ Xcode CLI Tools not detected (may be optional)")
        }
        
        // Check network
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
                // Stage 1: Download
                await setStage(.downloading, progress: 0.2)
                appendLine("$ \(pm) install -g openclaw@latest")
                appendLine("")
                
                // Run install command with streaming
                // If pnpm was just fixed, inject PNPM_HOME so the new env takes effect
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

                        // Update progress + status based on output
                        let lower = output.lowercased()
                        if lower.contains("resolving") || lower.contains("resolved") {
                            self.progress = min(self.progress + 0.05, 0.35)
                            self.statusMessage = "正在解析套件依賴..."
                        } else if lower.contains("downloading") || lower.contains("downloaded") {
                            self.progress = min(self.progress + 0.05, 0.5)
                            self.statusMessage = "正在下載套件..."
                        } else if lower.contains("progress:") {
                            self.progress = min(self.progress + 0.02, 0.6)
                            // Parse pnpm progress line for friendly message
                            if let match = output.range(of: "downloaded (\\d+)", options: .regularExpression) {
                                let num = output[match].filter(\.isNumber)
                                self.statusMessage = "已下載 \(num) 個套件..."
                            }
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
                
                // Stage 2: Verify
                await setStage(.verifying, progress: 0.9)
                appendLine("")
                appendLine("$ openclaw --version")
                
                try await Task.sleep(nanoseconds: 500_000_000)
                
                let verifyResult = await ShellRunner.run("openclaw --version 2>/dev/null")
                if verifyResult.success && !verifyResult.stdout.isEmpty {
                    let version = verifyResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                    appendLine(version)
                    installedVersion = version
                    
                    // Success!
                    progress = 1.0
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
        
        // Detect specific errors and provide fix suggestions
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

        // For pnpm setup: even if exit code is 0, we need to ensure PNPM_HOME is set
        // because the new shell env won't be available in subprocess
        if suggestion.errorType == .packageManagerMissing && selectedPackageManager == "pnpm" {
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            let pnpmHome = "\(home)/.local/share/pnpm"

            // Ensure pnpm home directory exists
            try? FileManager.default.createDirectory(
                atPath: pnpmHome,
                withIntermediateDirectories: true
            )

            // Store for use in install command
            pnpmHomePath = pnpmHome

            appendLine("✓ 已設定 PNPM_HOME: \(pnpmHome)")
            appendLine("")

            // Re-detect and retry
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
        
        // Keep reasonable buffer size
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
