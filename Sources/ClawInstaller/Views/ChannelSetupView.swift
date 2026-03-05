// ChannelSetupView — Channel Selection & Configuration (V2 Design)

import SwiftUI

struct ChannelSetupView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var configManager = ConfigManager.shared
    @State private var selectedChannels: Set<ChannelType> = []
    @State private var currentStep: SetupStep = .selection
    @State private var currentChannelIndex: Int = 0
    @State private var channelToggles: [ChannelType: Bool] = [
        .telegram: false,
        .discord: false,
        .whatsapp: false
    ]

    enum SetupStep {
        case selection
        case configuring
        case complete
    }

    var channelsToSetup: [ChannelType] {
        Array(selectedChannels).sorted { $0.rawValue < $1.rawValue }
    }

    var body: some View {
        Group {
            switch currentStep {
            case .selection:
                channelSelectionView
            case .configuring:
                if currentChannelIndex < channelsToSetup.count {
                    channelConfigView(for: channelsToSetup[currentChannelIndex])
                }
            case .complete:
                setupCompleteView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Channel Selection (V2 Design)

    private var channelSelectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("連結你的頻道")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)

                Text("你的 Agent 要在哪些平台上回應？")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            // Channel list
            VStack(spacing: 8) {
                ForEach(ChannelType.allCases, id: \.self) { channel in
                    channelRow(channel)
                }
            }

            Spacer()

            // Button row
            HStack(spacing: 12) {
                // Skip button
                Button {
                    appState.trackEvent("channel_setup_skip", module: "channels", meta: [:])
                    appState.currentStep = .monitor
                } label: {
                    Text("先略過")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                // Continue button
                Button {
                    if !selectedChannels.isEmpty {
                        appState.trackEvent("channel_setup_start", module: "channels", meta: [
                            "channels": selectedChannels.map(\.rawValue).sorted().joined(separator: ","),
                            "count": String(selectedChannels.count)
                        ])
                        currentStep = .configuring
                        currentChannelIndex = 0
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("繼續")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(selectedChannels.isEmpty ? Color.orange.opacity(0.4) : Color.orange)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(selectedChannels.isEmpty)
            }
        }
        .padding(.top, 32)
        .padding(.bottom, 28)
        .padding(.horizontal, 40)
    }

    // MARK: - Channel Row

    private func channelRow(_ channel: ChannelType) -> some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: channel.iconName)
                .font(.system(size: 22))
                .foregroundStyle(channel.color)
                .frame(width: 28, alignment: .center)

            // Text group
            VStack(alignment: .leading, spacing: 2) {
                Text(channel.displayName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.primary)

                Text(channel.description)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Toggle switch
            Toggle("", isOn: Binding(
                get: { channelToggles[channel] ?? false },
                set: { newValue in
                    channelToggles[channel] = newValue
                    if newValue {
                        selectedChannels.insert(channel)
                    } else {
                        selectedChannels.remove(channel)
                    }
                }
            ))
            .toggleStyle(ChannelToggleStyle())
            .labelsHidden()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }

    // MARK: - Channel Config Views

    @ViewBuilder
    private func channelConfigView(for channel: ChannelType) -> some View {
        switch channel {
        case .telegram:
            TelegramSetupView(onComplete: advanceToNextChannel)
        case .discord:
            DiscordSetupView(onComplete: advanceToNextChannel)
        case .whatsapp:
            WhatsAppSetupView(onComplete: advanceToNextChannel)
        }
    }

    private func advanceToNextChannel() {
        if currentChannelIndex + 1 < channelsToSetup.count {
            currentChannelIndex += 1
        } else {
            appState.trackEvent("channel_setup_complete", module: "channels", meta: [
                "channels": channelsToSetup.map(\.rawValue).joined(separator: ","),
                "count": String(channelsToSetup.count)
            ])
            currentStep = .complete
        }
    }

    private func isChannelConfigured(_ channel: ChannelType) -> Bool {
        switch channel {
        case .telegram: return configManager.hasTelegramConfig
        case .discord: return configManager.hasDiscordConfig
        case .whatsapp: return configManager.hasWhatsAppConfig
        }
    }

    // MARK: - Complete

    private var setupCompleteView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            Text("頻道設定完成！")
                .font(.system(size: 20, weight: .bold, design: .monospaced))

            Text("已選擇的頻道已準備就緒")
                .foregroundStyle(.secondary)

            // Summary
            VStack(alignment: .leading, spacing: 8) {
                ForEach(channelsToSetup, id: \.self) { channel in
                    HStack {
                        Image(systemName: channel.iconName)
                            .foregroundStyle(channel.color)
                        Text(channel.displayName)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(maxWidth: 300)

            Spacer()

            Button {
                appState.currentStep = .monitor
            } label: {
                Text("完成")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.orange)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: 200)
        }
        .padding()
    }
}

// MARK: - Channel Toggle Style (44x24 pill)

struct ChannelToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label

            ZStack {
                Capsule()
                    .fill(configuration.isOn ? Color.green : Color(nsColor: .systemGray).opacity(0.4))
                    .frame(width: 44, height: 24)

                Circle()
                    .fill(.white)
                    .frame(width: 20, height: 20)
                    .shadow(color: .black.opacity(0.15), radius: 1, y: 1)
                    .offset(x: configuration.isOn ? 10 : -10)
            }
            .animation(.easeInOut(duration: 0.15), value: configuration.isOn)
            .onTapGesture {
                configuration.isOn.toggle()
            }
        }
    }
}

// MARK: - Channel Type

enum ChannelType: String, CaseIterable {
    case telegram
    case discord
    case whatsapp

    var displayName: String {
        switch self {
        case .telegram: return "Telegram"
        case .discord: return "Discord"
        case .whatsapp: return "WhatsApp"
        }
    }

    var iconName: String {
        switch self {
        case .telegram: return "paperplane.fill"
        case .discord: return "bubble.left.and.bubble.right.fill"
        case .whatsapp: return "phone.fill"
        }
    }

    var color: Color {
        switch self {
        case .telegram: return Color(red: 0.0, green: 0.533, blue: 0.8)   // #0088CC
        case .discord: return Color(red: 0.345, green: 0.396, blue: 0.949) // #5865F2
        case .whatsapp: return Color(red: 0.145, green: 0.827, blue: 0.4)  // #25D366
        }
    }

    var description: String {
        switch self {
        case .telegram: return "透過 Bot API 連結，功能豐富"
        case .discord: return "支援伺服器與私訊"
        case .whatsapp: return "連結個人帳號"
        }
    }
}
