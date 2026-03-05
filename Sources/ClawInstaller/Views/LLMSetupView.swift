// LLMSetupView — AI Provider Selection (Screen 5, V2 Design)
// Three options: Anthropic (recommended), Google AI (free), Ollama (local)

import SwiftUI

struct LLMSetupView: View {
    @StateObject private var viewModel = LLMSetupViewModel()
    var onComplete: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            // Content based on current step
            Group {
                switch viewModel.currentStep {
                case .selectProvider:
                    providerSelectionView
                case .setupGuide:
                    setupGuideView
                case .enterKey:
                    enterKeyView
                case .ollamaDetection:
                    ollamaDetectionView
                case .validating:
                    validatingView
                case .complete:
                    completeView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Footer navigation (only for non-selection steps)
            if viewModel.currentStep != .selectProvider {
                Divider()
                footerView
            }
        }
    }

    // MARK: - Provider Selection (V2 Design)

    private var providerSelectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("選擇你的 AI 供應商")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)

                Text("OpenClaw 需要大型語言模型來驅動你的 Agent")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            // Provider cards
            VStack(spacing: 8) {
                ForEach(LLMProvider.allCases) { provider in
                    providerCardV2(provider)
                }
            }

            // Mascot tip section
            HStack(alignment: .top, spacing: 10) {
                // Logo placeholder (use app icon or SF Symbol)
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.orange)
                    .frame(width: 36, height: 36)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text("不確定選哪個？推薦 Anthropic，Agent 表現最好！")
                    .font(.system(size: 12))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(Color(red: 1.0, green: 0.973, blue: 0.941)) // #FFF8F0
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(red: 1.0, green: 0.878, blue: 0.698), lineWidth: 1) // #FFE0B2
            )

            Spacer()

            // Skip text
            Button {
                onComplete?()
            } label: {
                Text("略過 — 稍後再設定")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 32)
        .padding(.bottom, 28)
        .padding(.horizontal, 40)
        .onAppear {
            viewModel.checkOllamaInstalled()
        }
    }

    // MARK: - Provider Card V2

    private func providerCardV2(_ provider: LLMProvider) -> some View {
        let isSelected = viewModel.selectedProvider == provider

        return Button {
            viewModel.selectedProvider = provider
            viewModel.proceedFromSelection()
        } label: {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: provider.iconName)
                    .font(.system(size: 20))
                    .foregroundStyle(provider.color)
                    .frame(width: 40, height: 40)
                    .background(provider.color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                // Text group
                VStack(alignment: .leading, spacing: 2) {
                    Text(provider.displayName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.primary)

                    Text(provider == .anthropic ? provider.modelName : provider.tagline)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Right side: badge or arrow
                if provider == .anthropic {
                    Text("推薦")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .clipShape(Capsule())
                } else {
                    Text("設定 \u{2192}")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        provider == .anthropic ? Color.orange : Color(nsColor: .separatorColor),
                        lineWidth: provider == .anthropic ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Setup Guide (Step-by-step)

    private var setupGuideView: some View {
        VStack(spacing: 0) {
            if let provider = viewModel.selectedProvider {
                // Progress indicator
                HStack(spacing: 4) {
                    ForEach(0..<provider.setupSteps.count, id: \.self) { index in
                        Capsule()
                            .fill(index <= viewModel.currentGuideStep ? provider.color : Color.secondary.opacity(0.2))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Step content
                if viewModel.currentGuideStep < provider.setupSteps.count {
                    let step = provider.setupSteps[viewModel.currentGuideStep]

                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Step badge
                            Text("步驟 \(viewModel.currentGuideStep + 1) / \(provider.setupSteps.count)")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Capsule())

                            // Title
                            Text(step.title)
                                .font(.system(size: 20, weight: .bold, design: .monospaced))

                            // Description
                            Text(step.description)
                                .foregroundStyle(.secondary)

                            // Action button
                            if let action = step.action, let url = step.url {
                                Link(destination: url) {
                                    HStack {
                                        Text(action)
                                        Image(systemName: "arrow.up.right")
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(provider.color)
                            }

                            // Visual hints
                            setupHintView(for: provider, step: viewModel.currentGuideStep)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(24)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func setupHintView(for provider: LLMProvider, step: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            switch (provider, step) {
            case (.anthropic, 3), (.google, 2):
                // Key format hint
                Text("你的金鑰格式如下：")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Text(provider.keyPrefix)
                        .foregroundStyle(provider.color)
                    + Text("xxxx...xxxx")
                        .foregroundStyle(.secondary)
                }
                .font(.system(size: 14, design: .monospaced))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            case (.ollama, 2):
                // Terminal command
                Text("在終端機執行：")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Text("ollama pull llama3.2")
                        .font(.system(size: 14, design: .monospaced))

                    Spacer()

                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString("ollama pull llama3.2", forType: .string)
                        viewModel.showCopiedFeedback = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            viewModel.showCopiedFeedback = false
                        }
                    } label: {
                        Image(systemName: viewModel.showCopiedFeedback ? "checkmark" : "doc.on.doc")
                            .foregroundStyle(viewModel.showCopiedFeedback ? .green : .secondary)
                    }
                    .buttonStyle(.borderless)
                }
                .padding(12)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            default:
                EmptyView()
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Enter Key View

    private var enterKeyView: some View {
        VStack(spacing: 24) {
            if let provider = viewModel.selectedProvider {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(provider.color)

                    Text("輸入你的 API 金鑰")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))

                    Text("請貼上你的 \(provider.displayName) API 金鑰")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                // Key input
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        if viewModel.showKey {
                            TextField("在此貼上你的 API 金鑰...", text: $viewModel.apiKey)
                                .textFieldStyle(.plain)
                                .font(.system(.body, design: .monospaced))
                        } else {
                            SecureField("在此貼上你的 API 金鑰...", text: $viewModel.apiKey)
                                .textFieldStyle(.plain)
                                .font(.system(.body, design: .monospaced))
                        }

                        Button {
                            viewModel.showKey.toggle()
                        } label: {
                            Image(systemName: viewModel.showKey ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(12)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Validation feedback
                    HStack(spacing: 6) {
                        if viewModel.apiKey.isEmpty {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                            Text("開頭為 \(provider.keyPrefix)...")
                                .foregroundStyle(.secondary)
                        } else if provider.validateKeyFormat(viewModel.apiKey) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("金鑰格式正確")
                                .foregroundStyle(.green)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("金鑰應以 \(provider.keyPrefix) 開頭")
                                .foregroundStyle(.orange)
                        }
                    }
                    .font(.caption)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Error message
                if let error = viewModel.validationError {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                    }
                    .font(.caption)
                    .padding(12)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Help link
                if let url = provider.apiKeyURL {
                    Link(destination: url) {
                        HStack(spacing: 4) {
                            Image(systemName: "questionmark.circle")
                            Text("哪裡取得 API 金鑰？")
                        }
                        .font(.caption)
                    }
                }
            }

            Spacer()
        }
        .padding(24)
    }

    // MARK: - Ollama Detection View

    private var ollamaDetectionView: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "desktopcomputer")
                    .font(.system(size: 48))
                    .foregroundStyle(.purple)

                Text("檢查 Ollama 安裝狀態")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
            }

            // Detection status
            VStack(spacing: 16) {
                if viewModel.isCheckingOllama {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("偵測 Ollama 中...")
                        .foregroundStyle(.secondary)
                } else if viewModel.ollamaInstalled {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.green)
                    Text("Ollama 已安裝且正在執行！")
                        .font(.headline)

                    if !viewModel.ollamaModels.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("可用模型：")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            ForEach(viewModel.ollamaModels, id: \.self) { model in
                                HStack {
                                    Image(systemName: "cube.fill")
                                        .foregroundStyle(.purple)
                                    Text(model)
                                        .font(.system(.body, design: .monospaced))
                                }
                            }
                        }
                        .padding()
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.red)
                    Text("未偵測到 Ollama")
                        .font(.headline)

                    Text("請先安裝 Ollama 並執行模型。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Link(destination: URL(string: "https://ollama.com/download")!) {
                        HStack {
                            Text("下載 Ollama")
                            Image(systemName: "arrow.up.right")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)

                    Button("重新檢查") {
                        viewModel.checkOllamaInstalled()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()

            Spacer()
        }
        .padding(24)
        .onAppear {
            viewModel.detectOllamaWithModels()
        }
    }

    // MARK: - Validating View

    private var validatingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)

            Text("驗證中...")
                .font(.headline)

            if let provider = viewModel.selectedProvider {
                Text("正在測試與 \(provider.displayName) 的連線")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Complete View

    private var completeView: some View {
        VStack(spacing: 24) {
            // Success animation
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.green)
            }

            VStack(spacing: 8) {
                Text("AI 供應商設定完成！")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))

                if let provider = viewModel.selectedProvider {
                    Text("\(provider.modelName) 已準備就緒")
                        .foregroundStyle(.secondary)
                }
            }

            // Config summary
            if let provider = viewModel.selectedProvider {
                VStack(spacing: 12) {
                    configRow("供應商", provider.displayName)
                    Divider()
                    configRow("模型", provider.modelName)
                    Divider()
                    configRow("設定檔", "~/.openclaw/openclaw.json")
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer()
        }
        .padding(24)
    }

    private func configRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }

    // MARK: - Footer Navigation

    private var footerView: some View {
        HStack {
            // Back button
            if viewModel.currentStep != .selectProvider && viewModel.currentStep != .complete {
                Button("返回") {
                    viewModel.goBack()
                }
            }

            Spacer()

            // Primary action
            switch viewModel.currentStep {
            case .selectProvider:
                EmptyView()

            case .setupGuide:
                if let provider = viewModel.selectedProvider {
                    if viewModel.currentGuideStep < provider.setupSteps.count - 1 {
                        Button("下一步") {
                            viewModel.currentGuideStep += 1
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button(provider.requiresAPIKey ? "輸入 API 金鑰" : "完成設定") {
                            if provider.requiresAPIKey {
                                viewModel.currentStep = .enterKey
                            } else {
                                Task { await viewModel.validateAndSave() }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

            case .enterKey:
                Button("驗證並儲存") {
                    Task { await viewModel.validateAndSave() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.apiKey.isEmpty)

            case .ollamaDetection:
                Button("繼續") {
                    Task { await viewModel.validateAndSave() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.ollamaInstalled)

            case .validating:
                EmptyView()

            case .complete:
                Button("繼續") {
                    onComplete?()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

// MARK: - ViewModel

@MainActor
class LLMSetupViewModel: ObservableObject {
    enum Step {
        case selectProvider
        case setupGuide
        case enterKey
        case ollamaDetection
        case validating
        case complete
    }

    @Published var currentStep: Step = .selectProvider
    @Published var selectedProvider: LLMProvider?
    @Published var apiKey: String = ""
    @Published var showKey: Bool = false
    @Published var currentGuideStep: Int = 0
    @Published var validationError: String?
    @Published var showCopiedFeedback: Bool = false

    // Ollama detection
    @Published var ollamaInstalled: Bool = false
    @Published var isCheckingOllama: Bool = false
    @Published var ollamaModels: [String] = []

    func proceedFromSelection() {
        guard let provider = selectedProvider else { return }

        switch provider {
        case .ollama:
            currentStep = .ollamaDetection
        case .anthropic, .google:
            currentStep = .setupGuide
            currentGuideStep = 0
        }
    }

    func goBack() {
        switch currentStep {
        case .setupGuide:
            if currentGuideStep > 0 {
                currentGuideStep -= 1
            } else {
                currentStep = .selectProvider
            }
        case .enterKey:
            if let provider = selectedProvider {
                currentStep = .setupGuide
                currentGuideStep = provider.setupSteps.count - 1
            }
        case .ollamaDetection:
            currentStep = .selectProvider
        default:
            currentStep = .selectProvider
        }
    }

    func checkOllamaInstalled() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        task.arguments = ["ollama"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        do {
            try task.run()
            task.waitUntilExit()
            ollamaInstalled = task.terminationStatus == 0
        } catch {
            ollamaInstalled = false
        }
    }

    func detectOllamaWithModels() {
        isCheckingOllama = true
        ollamaModels = []

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // Check if ollama is running by querying the API
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
            task.arguments = ["-s", "http://localhost:11434/api/tags"]

            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = FileHandle.nullDevice

            do {
                try task.run()
                task.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()

                DispatchQueue.main.async {
                    self?.isCheckingOllama = false

                    if task.terminationStatus == 0,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let models = json["models"] as? [[String: Any]] {
                        self?.ollamaInstalled = true
                        self?.ollamaModels = models.compactMap { $0["name"] as? String }
                    } else {
                        self?.ollamaInstalled = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.isCheckingOllama = false
                    self?.ollamaInstalled = false
                }
            }
        }
    }

    func validateAndSave() async {
        guard let provider = selectedProvider else { return }

        validationError = nil
        currentStep = .validating

        // Format validation for API key providers
        if provider.requiresAPIKey {
            guard provider.validateKeyFormat(apiKey) else {
                validationError = "金鑰格式無效，應以 \(provider.keyPrefix) 開頭"
                currentStep = .enterKey
                return
            }
        }

        // Simulate API validation
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            try saveToConfig(provider: provider)
            currentStep = .complete
        } catch {
            validationError = error.localizedDescription
            currentStep = provider.requiresAPIKey ? .enterKey : .ollamaDetection
        }
    }

    private func saveToConfig(provider: LLMProvider) throws {
        let configDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".openclaw")
        let configFile = configDir.appendingPathComponent("openclaw.json")

        // Ensure directory exists
        try FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)

        // Read existing config or create new
        var config: [String: Any] = [:]
        if let data = try? Data(contentsOf: configFile),
           let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            config = existing
        }

        // Update LLM config
        var llm = config["llm"] as? [String: Any] ?? [:]
        llm["provider"] = provider.rawValue
        llm["model"] = provider.backendModel  // Use backend model identifier
        llm["displayModel"] = provider.modelName  // For UI display

        if provider.requiresAPIKey {
            llm[provider.configKey] = apiKey
        }

        config["llm"] = llm

        // Write back
        let data = try JSONSerialization.data(withJSONObject: config, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: configFile)
    }
}
