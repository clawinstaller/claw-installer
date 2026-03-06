// ChannelSetupView — Channel Selection & Configuration (V3 Expanded Design)

import SwiftUI

// MARK: - Channel Category

enum ChannelCategory: String, CaseIterable {
    case im       // Instant Messaging
    case work     // Work Collaboration
    case builtIn  // Built-in (no config needed)

    var displayName: String {
        switch self {
        case .im: return "即時通訊"
        case .work: return "工作協作"
        case .builtIn: return "內建"
        }
    }
}

// MARK: - Channel Type

enum ChannelType: String, CaseIterable, Identifiable {
    // Instant Messaging (Telegram first — simpler onboarding)
    case telegram
    case line
    case discord
    case whatsapp
    // Work Collaboration
    case slack
    case teams
    // Built-in
    case webchat

    var id: String { rawValue }

    var category: ChannelCategory {
        switch self {
        case .line, .telegram, .discord, .whatsapp: return .im
        case .slack, .teams: return .work
        case .webchat: return .builtIn
        }
    }

    var displayName: String {
        switch self {
        case .line: return "LINE"
        case .telegram: return "Telegram"
        case .discord: return "Discord"
        case .whatsapp: return "WhatsApp"
        case .slack: return "Slack"
        case .teams: return "Teams"
        case .webchat: return "WebChat"
        }
    }

    var isSoon: Bool {
        self == .line
    }

    var subtitle: String {
        switch self {
        case .telegram: return "推薦 · 3 步完成 · 免費"
        case .line: return "台灣最普及 · 設定較複雜"
        case .discord: return "社群伺服器"
        case .whatsapp: return "個人帳號連結"
        case .slack: return "團隊協作"
        case .teams: return "企業通訊"
        case .webchat: return "瀏覽器內建聊天"
        }
    }

    var iconName: String {
        switch self {
        case .line: return "message.fill"
        case .telegram: return "paperplane.fill"
        case .discord: return "bubble.left.and.bubble.right.fill"
        case .whatsapp: return "phone.fill"
        case .slack: return "number.square.fill"
        case .teams: return "person.3.fill"
        case .webchat: return "globe"
        }
    }

    var color: Color {
        switch self {
        case .line: return Color(red: 0.024, green: 0.780, blue: 0.333)     // #06C755
        case .telegram: return Color(red: 0.0, green: 0.533, blue: 0.8)     // #0088CC
        case .discord: return Color(red: 0.345, green: 0.396, blue: 0.949)  // #5865F2
        case .whatsapp: return Color(red: 0.145, green: 0.827, blue: 0.4)   // #25D366
        case .slack: return Color(red: 0.878, green: 0.118, blue: 0.353)    // #E01E5A
        case .teams: return Color(red: 0.384, green: 0.392, blue: 0.655)    // #6264A7
        case .webchat: return .green
        }
    }

    var requiresConfig: Bool {
        self != .webchat
    }

    var configKeys: [String] {
        switch self {
        case .line: return ["channelAccessToken", "channelSecret"]
        case .telegram: return ["botToken"]
        case .discord: return ["botToken", "applicationId"]
        case .whatsapp: return ["enabled"]
        case .slack: return ["botToken", "appToken"]
        case .teams: return ["botToken", "tenantId"]
        case .webchat: return []
        }
    }

    /// Channels in each category
    static func channels(for category: ChannelCategory) -> [ChannelType] {
        allCases.filter { $0.category == category }
    }
}

// MARK: - DM Policy

enum DMPolicy: String, CaseIterable {
    case pairing    // Pairing code verification (recommended)
    case allowlist  // Allowlist

    var displayName: String {
        switch self {
        case .pairing: return "配對碼驗證"
        case .allowlist: return "白名單"
        }
    }

    var description: String {
        switch self {
        case .pairing: return "使用者必須先輸入配對碼才能與 Agent 對話。安全且簡單，推薦使用。"
        case .allowlist: return "只有白名單上的使用者 ID 才能傳訊給 Agent。需手動管理名單。"
        }
    }
}

// MARK: - Channel Setup View

struct ChannelSetupView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var configManager = ConfigManager.shared
    @State private var selectedChannels: Set<ChannelType> = [.telegram]
    @State private var currentStep: SetupStep = .selection
    @State private var currentChannelIndex: Int = 0
    @State private var channelToggles: [ChannelType: Bool] = [
        .telegram: true,    // Default — simplest onboarding (3 steps, free)
        .line: false,       // Popular in TW but complex (5 steps, 2 sites)
        .discord: false,
        .whatsapp: false,
        .slack: false,
        .teams: false,
    ]
    @State private var selectedDMPolicy: DMPolicy = .pairing

    enum SetupStep {
        case selection
        case configuring
        case complete
    }

    var channelsToSetup: [ChannelType] {
        let order: [ChannelType] = [.telegram, .line, .discord, .whatsapp, .slack, .teams]
        return order.filter { selectedChannels.contains($0) && $0.requiresConfig }
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

    // MARK: - Channel Selection (V3 Design)

    private var channelSelectionView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Step indicator + progress bar
            VStack(alignment: .leading, spacing: 8) {
                Text("6 / 7")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 4)

                        Capsule()
                            .fill(Color.orange)
                            .frame(width: geo.size.width * (6.0 / 7.0), height: 4)
                    }
                }
                .frame(height: 4)
            }
            .padding(.horizontal, 40)
            .padding(.top, 24)

            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("連結你的溝通頻道")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)

                Text("你的 Agent 要在哪些平台上回應？")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 40)
            .padding(.top, 16)

            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Quick start tip
                    quickStartTip

                    // IM Category
                    channelCategorySection(.im)

                    // Work Category
                    channelCategorySection(.work)

                    // Built-in Category
                    builtInSection

                    // DM Policy Card
                    dmPolicyCard
                }
                .padding(.horizontal, 40)
                .padding(.top, 16)
                .padding(.bottom, 16)
            }

            Spacer(minLength: 0)

            // Bottom buttons
            HStack(spacing: 12) {
                // Skip button
                Button {
                    appState.trackEvent("channel_setup_skip", module: "channels", meta: [:])
                    saveDMPolicy()
                    appState.currentStep = .skills
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
                    let enabledChannels = channelToggles.filter { $0.value }.map(\.key)
                    let configurable = enabledChannels.filter { $0.requiresConfig }

                    if configurable.isEmpty {
                        // Only webchat or nothing toggled — skip config
                        appState.trackEvent("channel_setup_complete", module: "channels", meta: [
                            "channels": "webchat",
                            "count": "0"
                        ])
                        saveDMPolicy()
                        currentStep = .complete
                    } else {
                        selectedChannels = Set(enabledChannels)
                        appState.trackEvent("channel_setup_start", module: "channels", meta: [
                            "channels": configurable.map(\.rawValue).sorted().joined(separator: ","),
                            "count": String(configurable.count)
                        ])
                        saveDMPolicy()
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
                    .background(Color.orange)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 28)
        }
    }

    // MARK: - Category Section (2-column grid)

    private func channelCategorySection(_ category: ChannelCategory) -> some View {
        let channels = ChannelType.channels(for: category)
        return VStack(alignment: .leading, spacing: 8) {
            Text(category.displayName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                ForEach(channels) { channel in
                    channelCard(channel)
                }
            }
        }
    }

    // MARK: - Built-in Section

    private var builtInSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(ChannelCategory.builtIn.displayName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 12) {
                // Icon
                Image(systemName: ChannelType.webchat.iconName)
                    .font(.system(size: 20))
                    .foregroundStyle(ChannelType.webchat.color)
                    .frame(width: 28, alignment: .center)

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(ChannelType.webchat.displayName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.primary)

                    Text(ChannelType.webchat.subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Always-on badge
                Text("已啟用")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .clipShape(Capsule())
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Channel Card

    private func channelCard(_ channel: ChannelType) -> some View {
        let isOn = channelToggles[channel] ?? false

        return HStack(spacing: 10) {
            // Icon
            Image(systemName: channel.iconName)
                .font(.system(size: 18))
                .foregroundStyle(isOn ? channel.color : .secondary)
                .frame(width: 24, alignment: .center)

            // Text
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(channel.displayName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.primary)

                    if channel == .telegram {
                        Text("推薦")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(channel.color)
                            .clipShape(Capsule())
                    }

                    if channel.isSoon {
                        Text("Soon")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                Text(channel.subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Toggle
            if channel.isSoon {
                Text("Soon")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            } else {
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
                .toggleStyle(ChannelToggleStyle(brandColor: channel.color))
                .labelsHidden()
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isOn ? channel.color.opacity(0.4) : Color(nsColor: .separatorColor),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Quick Start Tip

    private var quickStartTip: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 16))
                .foregroundStyle(.orange)
                .frame(width: 28, height: 28)
                .background(Color.orange.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text("建議先設定 **Telegram**，2 分鐘即可完成")
                    .font(.system(size: 12))
                    .foregroundStyle(.primary)
                Text("之後隨時可在設定中加入 LINE 或其他頻道")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color(red: 1.0, green: 0.973, blue: 0.941))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(red: 1.0, green: 0.878, blue: 0.698), lineWidth: 1)
        )
    }

    // MARK: - DM Policy Card

    private var dmPolicyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(.orange)
                Text("DM 安全策略")
                    .font(.system(size: 14, weight: .bold))
            }

            // Segmented picker
            HStack(spacing: 0) {
                ForEach(DMPolicy.allCases, id: \.self) { policy in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedDMPolicy = policy
                        }
                    } label: {
                        Text(policy.displayName)
                            .font(.system(size: 12, weight: selectedDMPolicy == policy ? .semibold : .regular))
                            .foregroundStyle(selectedDMPolicy == policy ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(selectedDMPolicy == policy ? Color.orange : Color.clear)
                    }
                    .buttonStyle(.plain)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            )

            // Description
            Text(selectedDMPolicy.description)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if selectedDMPolicy == .pairing {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 9))
                    Text("推薦")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(.orange)
            }

        }
        .padding(16)
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
        VStack(spacing: 0) {
            // Back / skip row
            HStack {
                Button {
                    goBackFromConfig()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("返回")
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    advanceToNextChannel()
                } label: {
                    Text("略過此頻道")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            // Actual channel config
            Group {
                switch channel {
                case .line:
                    LineSetupView(onComplete: advanceToNextChannel)
                case .telegram:
                    TelegramSetupView(onComplete: advanceToNextChannel)
                case .discord:
                    DiscordSetupView(onComplete: advanceToNextChannel)
                case .whatsapp:
                    WhatsAppSetupView(onComplete: advanceToNextChannel)
                case .slack:
                    SlackSetupView(onComplete: advanceToNextChannel)
                case .teams:
                    TeamsSetupView(onComplete: advanceToNextChannel)
                case .webchat:
                    EmptyView()
                }
            }
        }
    }

    private func goBackFromConfig() {
        if currentChannelIndex > 0 {
            currentChannelIndex -= 1
        } else {
            currentStep = .selection
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
        case .line: return configManager.hasLineConfig
        case .slack: return configManager.hasSlackConfig
        case .teams: return configManager.hasTeamsConfig
        case .webchat: return true
        }
    }

    private func saveDMPolicy() {
        try? configManager.setDMPolicy(selectedDMPolicy)
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
                // Always show WebChat
                HStack {
                    Image(systemName: ChannelType.webchat.iconName)
                        .foregroundStyle(ChannelType.webchat.color)
                    Text(ChannelType.webchat.displayName)
                    Spacer()
                    Text("內建")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

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

                Divider()

                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(.orange)
                    Text("DM 策略：\(selectedDMPolicy.displayName)")
                        .font(.system(size: 12))
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(maxWidth: 300)

            Spacer()

            Button {
                appState.currentStep = .skills
            } label: {
                Text("繼續")
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

// MARK: - Channel Toggle Style (44x24 pill with brand color)

struct ChannelToggleStyle: ToggleStyle {
    var brandColor: Color = .green

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label

            ZStack {
                Capsule()
                    .fill(configuration.isOn ? brandColor : Color(nsColor: .systemGray).opacity(0.4))
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
