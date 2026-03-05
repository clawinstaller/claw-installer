// WelcomeView — Email registration with OTP flow (V2 Design)

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var isSending = false
    @State private var error: String?
    @State private var showVerify = false

    var body: some View {
        if showVerify {
            VerifyCodeView(email: email, onBack: { showVerify = false })
        } else {
            welcomeContent
        }
    }

    private var welcomeContent: some View {
        VStack(spacing: 16) {
            // Badge
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                Text("257K+ Stars on GitHub")
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(.green.opacity(0.12))
            .foregroundStyle(.green)
            .clipShape(Capsule())

            // Hero
            VStack(spacing: 12) {
                Image(nsImage: appLogoImage())
                    .resizable()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                Text("你的 AI 團隊，3 分鐘就緒")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))

                Text("不再手動設定 CLI — 一鍵啟動 3 位 AI Agent 為你工作")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }

            // Agent cards
            HStack(spacing: 12) {
                AgentCard(icon: "brain.head.profile", bgColor: Color(red: 1, green: 0.94, blue: 0.86),
                          name: "阿貓 · 總管", desc: "管理日程、自動回覆、任務調度")
                AgentCard(icon: "magnifyingglass", bgColor: Color(red: 0.91, green: 0.94, blue: 0.99),
                          name: "土豆 · 研究", desc: "深度分析、QA 測試、資料整理")
                AgentCard(icon: "chevron.left.forwardslash.chevron.right", bgColor: Color(red: 0.91, green: 0.96, blue: 0.91),
                          name: "小可愛 · 開發", desc: "寫程式、Debug、部署自動化")
            }

            // Email input
            HStack(spacing: 10) {
                Image(systemName: "envelope")
                    .foregroundStyle(.secondary)
                    .frame(width: 18)
                TextField("your@email.com", text: $email)
                    .textFieldStyle(.plain)
                    .textContentType(.emailAddress)
                    .onSubmit { sendOTP() }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(nsColor: .controlBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondary.opacity(0.25), lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Error
            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            // CTA
            Button {
                sendOTP()
            } label: {
                HStack(spacing: 8) {
                    if isSending {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "envelope.fill")
                    }
                    Text("寄送驗證碼 →")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .clipShape(Capsule())
            .disabled(email.isEmpty || isSending)

            // Skip
            Button("略過 — 不註冊直接使用") {
                appState.currentStep = .preflight
            }
            .buttonStyle(.plain)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)

            Text("繼續即表示同意我們的隱私政策與服務條款。")
                .font(.system(size: 11))
                .foregroundStyle(.secondary.opacity(0.6))
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 32)
    }

    private func sendOTP() {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard trimmed.contains("@") && trimmed.contains(".") else {
            error = "請輸入有效的 Email 地址"
            return
        }

        isSending = true
        error = nil

        Task {
            do {
                try await BackendService.shared.sendOTP(email: trimmed)
                await MainActor.run {
                    isSending = false
                    showVerify = true
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isSending = false
                }
            }
        }
    }
}

// MARK: - Agent Card

private struct AgentCard: View {
    let icon: String
    let bgColor: Color
    let name: String
    let desc: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.primary.opacity(0.7))
                .frame(width: 32, height: 32)
                .background(bgColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(name)
                .font(.system(size: 13, weight: .semibold))

            Text(desc)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
        )
    }
}
