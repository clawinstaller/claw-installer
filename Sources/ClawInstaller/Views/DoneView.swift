// DoneView — Installation Complete Screen with Health Check & Tips

import SwiftUI

struct DoneView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var configManager = ConfigManager.shared

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // --- Celebration header ---
                celebrationGroup

                // --- Health check card ---
                healthCheckCard

                // --- Action buttons row ---
                actionButtonsRow

                // --- GWS Skills nudge (post-install, non-blocking) ---
                if !appState.hasInstalledGWSSkills && !appState.gwsSkillsDismissed {
                    gwsSkillsNudge
                }

                // --- Tip card ---
                tipCard

                // --- Open console button ---
                openConsoleButton

                // --- Footer ---
                footerRow
            }
            .padding(.top, 28)
            .padding(.bottom, 24)
            .padding(.horizontal, 40)
        }
        .onAppear {
            configManager.loadConfig()
            appState.trackEvent("setup_complete", module: "app", meta: [
                "channels": configManager.enabledChannelNames.joined(separator: ","),
                "llm": configManager.llmProviderName ?? "none",
                "skills": Array(appState.selectedSkills).sorted().joined(separator: ",")
            ])
        }
    }

    // MARK: - Celebration Group

    private var celebrationGroup: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(.green)
                    .frame(width: 52, height: 52)

                Image(systemName: "checkmark")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 6) {
                Text("你的 AI 團隊已上線！")
                    .font(.custom("JetBrains Mono", size: 22).bold())
                    .multilineTextAlignment(.center)

                Text("OpenClaw 已成功安裝並運行中")
                    .font(.custom("Geist", size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Health Check Card

    private var healthCheckCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("系統狀態")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 8) {
                // AI Model
                statusRow(
                    icon: "checkmark.circle.fill",
                    iconColor: .green,
                    label: "AI 模型",
                    value: llmSummary
                )

                // Channels
                statusRow(
                    icon: "checkmark.circle.fill",
                    iconColor: .green,
                    label: "頻道",
                    value: channelsSummary
                )

                // Skills
                statusRow(
                    icon: "checkmark.circle.fill",
                    iconColor: .green,
                    label: "技能",
                    value: skillsSummary
                )

                // Gateway
                statusRow(
                    icon: "checkmark.circle.fill",
                    iconColor: .green,
                    label: "Gateway 運行中",
                    value: "ws://127.0.0.1:18789"
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }

    private func statusRow(icon: String, iconColor: Color, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(iconColor)

            Text(label)
                .font(.custom("Geist", size: 12))
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.custom("JetBrains Mono", size: 11))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
    }

    private var llmSummary: String {
        if let provider = configManager.llmProviderName,
           let model = configManager.llmModelDisplay {
            return "\(provider.capitalized) \(model)"
        }
        return "未設定"
    }

    private var channelsSummary: String {
        let names = configManager.enabledChannelNames
        return names.isEmpty ? "未設定" : names.joined(separator: ", ")
    }

    private var skillsSummary: String {
        let skills = Array(appState.selectedSkills).sorted()
        return skills.isEmpty ? "未安裝" : skills.joined(separator: ", ")
    }

    // MARK: - Action Buttons Row

    private var actionButtonsRow: some View {
        HStack(spacing: 8) {
            actionButton(
                icon: "rectangle.split.3x3",
                label: "開啟 Dashboard"
            ) {
                if let url = URL(string: "http://localhost:5173") {
                    NSWorkspace.shared.open(url)
                }
            }

            actionButton(
                icon: "message.circle",
                label: "傳訊給 Agent"
            ) {
                openTerminal()
            }

            actionButton(
                icon: "qrcode",
                label: "分享 QR Code"
            ) {
                shareQRCode()
            }
        }
    }

    private func actionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(.orange)

                Text(label)
                    .font(.custom("Geist", size: 11))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - GWS Skills Nudge

    private var gwsSkillsNudge: some View {
        HStack(spacing: 12) {
            // Google "G" icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.259, green: 0.522, blue: 0.957)) // #4285F4
                    .frame(width: 32, height: 32)

                Text("G")
                    .font(.custom("Geist", size: 18).bold())
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("擴充：Google Workspace Skills")
                    .font(.custom("Geist", size: 12).weight(.semibold))
                    .foregroundStyle(.primary)

                Text("讓 Agent 幫你管理 Gmail、Drive、Calendar")
                    .font(.custom("Geist", size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                appState.currentStep = .monitor
                // TODO: navigate to Skills management tab when implemented
            } label: {
                Text("設定 \u{2192}")
                    .font(.custom("Geist", size: 11).weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }

    // MARK: - Tip Card

    private var tipCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.orange)
                Text("小提示")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.primary)
            }

            VStack(alignment: .leading, spacing: 6) {
                tipRow("如遇問題，在終端機執行 `openclaw doctor` 自動診斷")
                tipRow("隨時在 Menu Bar 監控 Gateway 狀態")
                tipRow("使用 `openclaw configure` 隨時修改設定")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 1.0, green: 0.973, blue: 0.941)) // #FFF8F0
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 1.0, green: 0.878, blue: 0.698), lineWidth: 1) // #FFE0B2
        )
    }

    private func tipRow(_ text: String) -> some View {
        // Parse inline code blocks marked with backticks
        let parts = text.components(separatedBy: "`")
        return HStack(spacing: 0) {
            ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                if index % 2 == 1 {
                    // Code block
                    Text(part)
                        .font(.custom("JetBrains Mono", size: 11))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                } else {
                    Text(part)
                        .font(.custom("Geist", size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Open Console Button

    private var openConsoleButton: some View {
        Button {
            appState.currentStep = .monitor
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 14))
                Text("開啟控制台")
                    .font(.custom("Geist", size: 14).bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(.orange)
            .foregroundStyle(.white)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Footer

    private var footerRow: some View {
        HStack {
            Button {
                if let url = URL(string: "https://clawinstaller.github.io/website/guide/getting-started") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Text("查看新手教學 \u{2192}")
                    .font(.custom("Geist", size: 11))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("ClawInstaller v\(appVersion)")
                .font(.custom("JetBrains Mono", size: 9))
                .foregroundStyle(.primary.opacity(0.4))
        }
    }

    // MARK: - Actions

    private func openTerminal() {
        let script = """
        tell application "Terminal"
            activate
            do script "export PATH=\\"$HOME/.npm-global/bin:/opt/homebrew/bin:/usr/local/bin:$PATH\\" && openclaw"
        end tell
        """
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }

    private func shareQRCode() {
        // Generate share URL for Threads
        if let url = QRCodeGenerator.threadsShareURL(
            text: QRCodeGenerator.defaultShareText,
            url: QRCodeGenerator.defaultShareURL
        ) {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Preview

struct DoneView_Previews: PreviewProvider {
    static var previews: some View {
        DoneView()
            .environmentObject(AppState())
            .frame(width: 760, height: 540)
    }
}
