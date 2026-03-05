// VerifyCodeView — 6-digit OTP input and verification

import SwiftUI

struct VerifyCodeView: View {
    @EnvironmentObject var appState: AppState
    let email: String
    let onBack: () -> Void

    @State private var digits: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusedIndex: Int?
    @State private var isVerifying = false
    @State private var error: String?
    @State private var resendCountdown = 60
    @State private var resendTimer: Timer?

    private var fullCode: String {
        digits.joined()
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Icon
            Image(systemName: "envelope.fill")
                .font(.system(size: 28))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(.orange)
                .clipShape(RoundedRectangle(cornerRadius: 14))

            // Title
            Text("輸入啟用碼")
                .font(.title2.weight(.bold).monospaced())

            // Subtitle
            VStack(spacing: 4) {
                Text("我們已將 6 位數驗證碼寄至")
                Text(email)
                    .fontWeight(.medium)
                Text("請檢查收件匣及垃圾郵件匣。")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 420)

            // Code input (hidden TextField + visual boxes)
            codeInputView
                .padding(.vertical, 4)

            // Error
            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            // Verify button
            Button {
                verify()
            } label: {
                HStack(spacing: 8) {
                    if isVerifying {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text("啟用")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .disabled(fullCode.count < 6 || isVerifying)
            .padding(.horizontal, 56)

            // Back link
            Button("← 使用其他信箱") {
                onBack()
            }
            .buttonStyle(.plain)
            .font(.subheadline)
            .foregroundStyle(.secondary)

            // Resend timer
            if resendCountdown > 0 {
                Text("\(resendCountdown) 秒後可重新發送驗證碼")
                    .font(.caption)
                    .foregroundStyle(.secondary.opacity(0.6))
            } else {
                Button("重新發送驗證碼") {
                    resendOTP()
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.orange)
            }

            Spacer()
        }
        .padding(.horizontal, 56)
        .padding(.vertical, 40)
        .onAppear { startResendTimer() }
        .onDisappear { resendTimer?.invalidate() }
    }

    // MARK: - Code Input

    private var codeInputView: some View {
        HStack(spacing: 10) {
            ForEach(0..<6, id: \.self) { index in
                digitBox(index: index)
            }
        }
        .background(
            // Hidden TextField to capture keyboard input
            TextField("", text: Binding(
                get: { fullCode },
                set: { newValue in
                    let filtered = String(newValue.filter(\.isNumber).prefix(6))
                    for i in 0..<6 {
                        if i < filtered.count {
                            let idx = filtered.index(filtered.startIndex, offsetBy: i)
                            digits[i] = String(filtered[idx])
                        } else {
                            digits[i] = ""
                        }
                    }
                    // Auto-verify when all 6 digits entered
                    if filtered.count == 6 {
                        verify()
                    }
                }
            ))
            .focused($focusedIndex, equals: 0)
            .textFieldStyle(.plain)
            .frame(width: 1, height: 1)
            .opacity(0.01)
        )
        .onTapGesture {
            focusedIndex = 0
        }
        .onAppear {
            focusedIndex = 0
        }
    }

    private func digitBox(index: Int) -> some View {
        Text(digits[index])
            .font(.system(size: 24, weight: .bold, design: .monospaced))
            .frame(width: 52, height: 56)
            .background(.background)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        !digits[index].isEmpty ? Color.orange : Color.secondary.opacity(0.3),
                        lineWidth: 1.5
                    )
            )
    }

    // MARK: - Actions

    private func verify() {
        let code = fullCode
        guard code.count == 6 else { return }

        isVerifying = true
        error = nil

        Task {
            do {
                let response = try await BackendService.shared.verifyOTP(email: email, code: code)
                await MainActor.run {
                    isVerifying = false
                    if let user = response.user, let token = response.token {
                        appState.userEmail = user.email
                        appState.userId = user.id
                        appState.userToken = token
                        appState.currentStep = .preflight
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isVerifying = false
                    digits = Array(repeating: "", count: 6)
                }
            }
        }
    }

    private func resendOTP() {
        resendCountdown = 60
        startResendTimer()

        Task {
            try? await BackendService.shared.sendOTP(email: email)
        }
    }

    private func startResendTimer() {
        resendTimer?.invalidate()
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if resendCountdown > 0 {
                resendCountdown -= 1
            } else {
                resendTimer?.invalidate()
            }
        }
    }
}
