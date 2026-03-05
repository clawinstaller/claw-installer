// DoneView — V2 Installation Complete Screen with QR Code Sharing

import SwiftUI

struct DoneView: View {
    let installedVersion: String?
    let installDuration: TimeInterval // seconds elapsed during install

    @EnvironmentObject var appState: AppState

    @State private var qrCodeImage: NSImage?
    @State private var selectedPlatform: SharePlatform = .threads
    @State private var installerNumber: Int = 2_847

    enum SharePlatform: String, CaseIterable {
        case threads = "Threads"
        case twitter = "X (Twitter)"
    }

    // MARK: - Helpers

    private var formattedDuration: String {
        let minutes = Int(installDuration) / 60
        let seconds = Int(installDuration) % 60
        return "\(minutes) \u{5206} \(String(format: "%02d", seconds)) \u{79D2}"
    }

    private var versionString: String {
        if let v = installedVersion { return "v\(v)" }
        return "v--"
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // --- Celebration group ---
            celebrationGroup

            // --- Stats row ---
            statsRow

            // --- Try section ---
            trySection

            // --- QR share card ---
            qrShareCard

            // --- Open console button ---
            openConsoleButton

            Spacer(minLength: 0)

            // --- Footer ---
            footerRow
        }
        .padding(.top, 32)
        .padding(.bottom, 28)
        .padding(.horizontal, 40)
        .onAppear {
            generateQRCode()
        }
    }

    // MARK: - Celebration Group

    private var celebrationGroup: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.green)
                    .frame(width: 64, height: 64)

                Image(systemName: "checkmark")
                    .font(.system(size: 32, weight: .bold))
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

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 8) {
            statCard(value: formattedDuration, label: "安裝耗時")
            statCard(value: versionString, label: "OpenClaw 版本")
            statCard(value: "# \(installerNumber)", label: "你是第 N 位安裝者", valueColor: .orange)
        }
    }

    private func statCard(value: String, label: String, valueColor: Color = .primary) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.custom("JetBrains Mono", size: 15).bold())
                .foregroundStyle(valueColor)

            Text(label)
                .font(.custom("Geist", size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }

    // MARK: - Try Section

    private var trySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("立即體驗你的 Agent")
                .font(.custom("Geist", size: 13).bold())

            VStack(spacing: 8) {
                tryActionCard(
                    icon: "terminal.fill",
                    iconColor: .purple,
                    title: "開啟終端機",
                    subtitle: "執行 openclaw 開始對話"
                ) {
                    openTerminal()
                }

                tryActionCard(
                    icon: "book.fill",
                    iconColor: .blue,
                    title: "閱讀文件",
                    subtitle: "了解 OpenClaw 能做什麼"
                ) {
                    if let url = URL(string: "https://clawinstaller.github.io/website/guide/getting-started") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }

    private func tryActionCard(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(iconColor)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.custom("Geist", size: 13).bold())
                    Text(subtitle)
                        .font(.custom("Geist", size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    // MARK: - QR Share Card

    private var qrShareCard: some View {
        HStack(spacing: 16) {
            // QR code
            Group {
                if let image = qrCodeImage {
                    Image(nsImage: image)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.1))
                        .frame(width: 80, height: 80)
                        .overlay { ProgressView() }
                }
            }

            // Text group
            VStack(alignment: .leading, spacing: 8) {
                Text("分享給朋友")
                    .font(.custom("Geist", size: 13).bold())

                Text("掃描 QR Code 在社群分享你的安裝成就")
                    .font(.custom("Geist", size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                // Platform selector
                HStack(spacing: 8) {
                    ForEach(SharePlatform.allCases, id: \.rawValue) { platform in
                        Button {
                            selectedPlatform = platform
                            generateQRCode()
                        } label: {
                            Text(platform.rawValue)
                                .font(.custom("Geist", size: 10).bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    selectedPlatform == platform
                                        ? Color.accentColor
                                        : Color.secondary.opacity(0.12)
                                )
                                .foregroundStyle(
                                    selectedPlatform == platform ? .white : .primary
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
                if let url = URL(string: "https://clawinstaller.github.io/website/guide/getting-started/getting-started") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Text("查看新手教學 \u{2192}")
                    .font(.custom("Geist", size: 11))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("ClawInstaller \(versionString)")
                .font(.custom("JetBrains Mono", size: 9))
                .foregroundStyle(.primary.opacity(0.4))
        }
    }

    // MARK: - Actions

    private func generateQRCode() {
        let shareURL: URL?

        switch selectedPlatform {
        case .threads:
            shareURL = QRCodeGenerator.threadsShareURL(
                text: QRCodeGenerator.defaultShareText,
                url: QRCodeGenerator.defaultShareURL
            )
        case .twitter:
            shareURL = QRCodeGenerator.twitterShareURL(
                text: QRCodeGenerator.defaultShareText,
                url: QRCodeGenerator.defaultShareURL
            )
        }

        if let url = shareURL {
            qrCodeImage = QRCodeGenerator.generate(from: url.absoluteString, size: 300)
        }
    }

    private func openTerminal() {
        let script = """
        tell application "Terminal"
            activate
            do script "openclaw"
        end tell
        """
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }
}

// MARK: - Preview

struct DoneView_Previews: PreviewProvider {
    static var previews: some View {
        DoneView(installedVersion: "2.4.1", installDuration: 154)
            .environmentObject(AppState())
            .frame(width: 480, height: 640)
    }
}
