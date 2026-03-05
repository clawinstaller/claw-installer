// PreflightView — Module 1 UI: System Requirements Check (V2 Design)

import SwiftUI

struct PreflightView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var checker = PreflightChecker()
    @State private var showingFixSheet = false
    @State private var selectedCheck: PreflightCheck?
    @State private var fixingCheckId: UUID?

    private var passCount: Int {
        checker.checks.filter { $0.status == .pass }.count
    }

    private var totalCount: Int {
        checker.checks.count
    }

    private var progressFraction: Double {
        guard totalCount > 0 else { return 0 }
        return Double(passCount) / Double(totalCount)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Progress header
            progressHeader

            // Check list
            VStack(spacing: 6) {
                ForEach(checker.checks) { check in
                    CheckRowV2(
                        check: check,
                        isFixing: fixingCheckId == check.id,
                        onFix: {
                            Task {
                                fixingCheckId = check.id
                                await checker.executeFix(for: check)
                                fixingCheckId = nil
                            }
                        },
                        onManualFix: {
                            selectedCheck = check
                            showingFixSheet = true
                        }
                    )
                }
            }

            Spacer()

            // Bottom row
            bottomRow
        }
        .padding(.top, 36)
        .padding(.leading, 40)
        .padding(.bottom, 32)
        .padding(.trailing, 40)
        .frame(minWidth: 600, minHeight: 450)
        .task {
            appState.trackEvent("preflight_start", module: "preflight")
            await checker.runAll()
            let failCount = checker.checks.filter { $0.status == .fail }.count
            appState.trackEvent("preflight_complete", module: "preflight", meta: [
                "failures": String(failCount),
                "total": String(checker.checks.count)
            ])
        }
        .sheet(isPresented: $showingFixSheet) {
            if let check = selectedCheck {
                FixSheet(check: check, checker: checker) {
                    showingFixSheet = false
                }
            }
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if !checker.isRunning && passCount == totalCount {
                    Text("\u{1F389}")
                        .font(.system(size: 20))
                }

                Text("\(passCount) / \(totalCount) 準備就緒")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)
            }

            if checker.isRunning {
                Text("正在檢查你的系統環境...")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            } else if passCount == totalCount {
                Text("一切就緒，可以開始安裝了！")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            } else {
                Text("只差一步，讓我們自動幫你搞定")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.orange)
                        .frame(width: geo.size.width * progressFraction, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: progressFraction)
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: - Bottom Row

    private var bottomRow: some View {
        HStack {
            Button {
                // Open GitHub issues or support
                if let url = URL(string: "https://github.com/clawinstaller/claw-installer/issues") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                HStack(spacing: 4) {
                    Text("遇到問題？")
                        .foregroundStyle(.secondary)
                    Text("回報問題")
                        .foregroundStyle(.orange)
                }
                .font(.system(size: 12))
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                appState.currentStep = .install
            } label: {
                HStack(spacing: 4) {
                    Text("安裝 OpenClaw")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(canContinue ? Color.orange : Color.orange.opacity(0.4))
                )
            }
            .buttonStyle(.plain)
            .disabled(!canContinue)
        }
    }

    private var canContinue: Bool {
        !checker.hasBlockingIssues && !checker.isRunning
    }
}

// MARK: - Check Row V2

struct CheckRowV2: View {
    let check: PreflightCheck
    let isFixing: Bool
    let onFix: () -> Void
    let onManualFix: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // Circle status icon (24x24)
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 24, height: 24)

                if check.status == .checking {
                    ProgressView()
                        .controlSize(.mini)
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: iconName)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(iconForegroundColor)
                }
            }

            // Check text: name + detail inline
            HStack(spacing: 0) {
                Text(check.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)

                if let detail = check.detail, check.status != .checking {
                    Text(" ")
                    Text(detail)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .lineLimit(1)

            Spacer()

            // Fix button (inline green pill) for warn/fail with auto-fix
            if (check.status == .fail || check.status == .warn), check.fixAction != nil {
                if check.fixAction?.command != nil {
                    // Auto-fixable: green pill button
                    Button {
                        onFix()
                    } label: {
                        if isFixing {
                            ProgressView()
                                .controlSize(.mini)
                                .scaleEffect(0.7)
                                .frame(width: 12, height: 12)
                        } else {
                            Text("一鍵修復")
                                .font(.system(size: 11, weight: .semibold))
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.green))
                    .buttonStyle(.plain)
                    .disabled(isFixing)
                } else {
                    // Manual fix only: show sheet
                    Button {
                        onManualFix()
                    } label: {
                        Text("手動修復")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().stroke(Color.orange, lineWidth: 1))
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(rowBorderColor, lineWidth: rowBorderWidth)
        )
    }

    // MARK: - Styling

    private var iconName: String {
        switch check.status {
        case .pass: return "checkmark"
        case .fail: return "xmark"
        case .warn: return "exclamationmark"
        case .checking: return "ellipsis"
        }
    }

    private var iconBackgroundColor: Color {
        switch check.status {
        case .pass: return .green
        case .fail, .warn: return .orange
        case .checking: return .gray.opacity(0.3)
        }
    }

    private var iconForegroundColor: Color {
        switch check.status {
        case .pass, .fail, .warn: return .white
        case .checking: return .gray
        }
    }

    private var rowBackground: Color {
        switch check.status {
        case .fail, .warn: return Color(red: 1.0, green: 0.973, blue: 0.941) // #FFF8F0
        default: return Color(nsColor: .controlBackgroundColor)
        }
    }

    private var rowBorderColor: Color {
        switch check.status {
        case .fail, .warn: return .orange
        default: return Color(nsColor: .separatorColor).opacity(0.5)
        }
    }

    private var rowBorderWidth: CGFloat {
        switch check.status {
        case .fail, .warn: return 1.5
        default: return 1.0
        }
    }
}

// MARK: - Fix Sheet

struct FixSheet: View {
    let check: PreflightCheck
    let checker: PreflightChecker
    let onDismiss: () -> Void

    @State private var isFixing = false

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 32, height: 32)

                    Image(systemName: "exclamationmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(check.name)
                        .font(.system(size: 15, weight: .semibold))

                    if let detail = check.detail {
                        Text(detail)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }

            // Fix content
            if let fix = check.fixAction {
                VStack(alignment: .leading, spacing: 16) {
                    // Auto fix
                    if let command = fix.command {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("自動修復")
                                .font(.system(size: 13, weight: .semibold))

                            Text(command)
                                .font(.system(size: 11, design: .monospaced))
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(nsColor: .textBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 6))

                            Button {
                                Task {
                                    isFixing = true
                                    await checker.executeFix(for: check)
                                    isFixing = false
                                    onDismiss()
                                }
                            } label: {
                                if isFixing {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Text("執行修復")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                            .disabled(isFixing)
                        }
                    }

                    // Manual steps
                    if !fix.manualSteps.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("手動步驟")
                                .font(.system(size: 13, weight: .semibold))

                            ForEach(Array(fix.manualSteps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(index + 1).")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.secondary)

                                    Text(step)
                                        .font(.system(size: 12))
                                }
                            }
                        }
                    }
                }
            }

            Spacer()

            // Dismiss
            HStack {
                Spacer()
                Button("關閉") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .frame(width: 420, height: 320)
    }
}
