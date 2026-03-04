// InstallWizardView — Module 2: One-click OpenClaw Installation

import SwiftUI

struct InstallWizardView: View {
    @StateObject private var installer = OpenClawInstaller()
    
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
                case .installing:
                    installingView
                case .success:
                    successView
                case .failed:
                    failedView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Divider()
            
            // Footer
            footer
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Install OpenClaw")
                    .font(.title2.bold())
                
                Text(headerSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Package manager badge
            if let pm = installer.selectedPackageManager {
                HStack(spacing: 6) {
                    Image(systemName: "shippingbox.fill")
                    Text(pm)
                }
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.blue.opacity(0.1))
                .foregroundStyle(.blue)
                .clipShape(Capsule())
            }
        }
        .padding()
    }
    
    private var headerSubtitle: String {
        switch installer.state {
        case .ready:
            return "Ready to install OpenClaw CLI"
        case .installing:
            return installer.currentStage.description
        case .success:
            return "Installation completed successfully"
        case .failed:
            return "Installation failed"
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
                
                Text("The command-line interface for OpenClaw AI assistant")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // What will be installed
            VStack(alignment: .leading, spacing: 12) {
                Text("What will be installed:")
                    .font(.subheadline.bold())
                
                installItem(icon: "terminal.fill", title: "openclaw CLI", detail: "Command-line tools")
                installItem(icon: "server.rack", title: "Gateway Server", detail: "Local AI gateway service")
                installItem(icon: "folder.fill", title: "Config Directory", detail: "~/.openclaw/")
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Install command preview
            if let pm = installer.selectedPackageManager {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Command:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("\(pm) install -g openclaw@latest")
                        .font(.system(size: 12, design: .monospaced))
                        .padding(8)
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding()
    }
    
    private func installItem(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
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
    
    // MARK: - Installing View
    
    private var installingView: some View {
        VStack(spacing: 20) {
            // Progress stages
            HStack(spacing: 0) {
                ForEach(InstallStage.allCases, id: \.self) { stage in
                    stageIndicator(stage)
                    
                    if stage != InstallStage.allCases.last {
                        Rectangle()
                            .fill(stage.rawValue < installer.currentStage.rawValue ? Color.green : Color.secondary.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
            .padding(.horizontal)
            
            // Terminal output
            terminalView
            
            // Progress bar
            VStack(spacing: 8) {
                ProgressView(value: installer.progress)
                    .progressViewStyle(.linear)
                
                Text(installer.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        }
        .padding()
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
                        .font(.system(size: 14, weight: .semibold))
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
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(installer.terminalLines.enumerated()), id: \.offset) { index, line in
                        Text(line)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(line.hasPrefix("ERROR") ? .red : .primary)
                            .id(index)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
            }
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(height: 150)
            .onChange(of: installer.terminalLines.count) { _, _ in
                if let lastIndex = installer.terminalLines.indices.last {
                    withAnimation {
                        proxy.scrollTo(lastIndex, anchor: .bottom)
                    }
                }
            }
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
                Text("Installation Complete!")
                    .font(.title3.bold())
                
                if let version = installer.installedVersion {
                    Text("OpenClaw v\(version) is ready to use")
                        .foregroundStyle(.secondary)
                }
            }
            
            // Quick actions
            VStack(spacing: 12) {
                quickAction(icon: "terminal.fill", title: "Open Terminal", detail: "Run 'openclaw' to get started") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"))
                }
                
                quickAction(icon: "gearshape.fill", title: "Configure Channels", detail: "Set up Telegram, Discord, or WhatsApp") {
                    // Navigate to channels
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
    }
    
    private func quickAction(icon: String, title: String, detail: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.bold())
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Failed View
    
    private var failedView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(.red.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.red)
            }
            
            VStack(spacing: 8) {
                Text("Installation Failed")
                    .font(.title3.bold())
                
                Text(installer.errorMessage ?? "An unexpected error occurred")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Error details
            if !installer.terminalLines.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Error Details:")
                        .font(.subheadline.bold())
                    
                    ScrollView {
                        Text(installer.terminalLines.suffix(20).joined(separator: "\n"))
                            .font(.system(size: 10, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 100)
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Troubleshooting
            VStack(alignment: .leading, spacing: 8) {
                Text("Troubleshooting:")
                    .font(.subheadline.bold())
                
                Text("• Check your internet connection")
                Text("• Try running the install command manually")
                Text("• Check npm/pnpm permissions")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack {
            switch installer.state {
            case .ready:
                Spacer()
                Button("Install") {
                    Task { await installer.install() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(installer.selectedPackageManager == nil)
                
            case .installing:
                Button("Cancel") {
                    installer.cancel()
                }
                Spacer()
                
            case .success:
                Spacer()
                Button("Continue") {
                    // Navigate to next step
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
            case .failed:
                Button("View Logs") {
                    // Open log file
                }
                Spacer()
                Button("Retry") {
                    Task { await installer.install() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

// MARK: - Install Stage

enum InstallStage: Int, CaseIterable {
    case preparing = 0
    case downloading
    case installing
    case verifying
    
    var label: String {
        switch self {
        case .preparing: return "Prepare"
        case .downloading: return "Download"
        case .installing: return "Install"
        case .verifying: return "Verify"
        }
    }
    
    var icon: String {
        switch self {
        case .preparing: return "gearshape"
        case .downloading: return "arrow.down"
        case .installing: return "square.and.arrow.down"
        case .verifying: return "checkmark.shield"
        }
    }
    
    var description: String {
        switch self {
        case .preparing: return "Preparing installation..."
        case .downloading: return "Downloading OpenClaw..."
        case .installing: return "Installing OpenClaw..."
        case .verifying: return "Verifying installation..."
        }
    }
}

// MARK: - Installer

@MainActor
class OpenClawInstaller: ObservableObject {
    enum State {
        case ready
        case installing
        case success
        case failed
    }
    
    @Published var state: State = .ready
    @Published var currentStage: InstallStage = .preparing
    @Published var progress: Double = 0
    @Published var statusMessage: String = ""
    @Published var terminalLines: [String] = []
    @Published var errorMessage: String?
    @Published var installedVersion: String?
    @Published var selectedPackageManager: String?
    
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
    
    func install() async {
        guard let pm = selectedPackageManager else {
            errorMessage = "No package manager found"
            state = .failed
            return
        }
        
        state = .installing
        terminalLines = []
        errorMessage = nil
        progress = 0
        
        installTask = Task {
            do {
                // Stage 1: Preparing
                await setStage(.preparing, progress: 0.1)
                appendLine("$ Checking environment...")
                try await Task.sleep(nanoseconds: 500_000_000)
                appendLine("✓ Package manager: \(pm)")
                
                // Stage 2: Downloading
                await setStage(.downloading, progress: 0.2)
                appendLine("")
                appendLine("$ \(pm) install -g openclaw@latest")
                
                // Run install command with streaming
                let installCmd = "\(pm) install -g openclaw@latest 2>&1"
                let result = await ShellRunner.runWithStreaming(
                    installCmd,
                    onOutput: { [weak self] output in
                        self?.appendLine(output)
                        // Update progress based on output hints
                        if output.contains("Downloading") || output.contains("Resolving") {
                            self?.progress = 0.4
                        } else if output.contains("Installing") || output.contains("Building") {
                            self?.setStage(.installing, progress: 0.6)
                        }
                    },
                    onError: { [weak self] error in
                        self?.appendLine("ERROR: \(error)")
                    }
                )
                
                if !result.success {
                    throw InstallError.installFailed(result.stderr)
                }
                
                // Stage 3: Verifying
                await setStage(.verifying, progress: 0.9)
                appendLine("")
                appendLine("$ openclaw --version")
                
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
                await rollback()
                state = .ready
            } catch let error as InstallError {
                errorMessage = error.localizedDescription
                appendLine("")
                appendLine("✗ \(error.localizedDescription)")
                await rollback()
                state = .failed
            } catch {
                errorMessage = error.localizedDescription
                appendLine("")
                appendLine("✗ \(error.localizedDescription)")
                await rollback()
                state = .failed
            }
        }
        
        await installTask?.value
    }
    
    func cancel() {
        installTask?.cancel()
    }
    
    private func rollback() async {
        appendLine("")
        appendLine("$ Rolling back installation...")
        
        if let pm = selectedPackageManager {
            let _ = await ShellRunner.run("\(pm) uninstall -g openclaw 2>/dev/null")
        }
        
        appendLine("✓ Rollback complete")
    }
    
    private func setStage(_ stage: InstallStage, progress: Double) {
        currentStage = stage
        self.progress = progress
        statusMessage = stage.description
    }
    
    private func appendLine(_ line: String) {
        // Handle multi-line output
        let lines = line.split(separator: "\n", omittingEmptySubsequences: false)
        for l in lines {
            terminalLines.append(String(l))
        }
    }
    
    enum InstallError: LocalizedError {
        case installFailed(String)
        case verificationFailed
        
        var errorDescription: String? {
            switch self {
            case .installFailed(let stderr):
                return "Installation failed: \(stderr.prefix(200))"
            case .verificationFailed:
                return "Verification failed: openclaw command not found after install"
            }
        }
    }
}
