// PreflightView — Module 1 UI: System Requirements Check

import SwiftUI

struct PreflightView: View {
    @StateObject private var checker = PreflightChecker()
    @State private var showingFixSheet = false
    @State private var selectedCheck: PreflightCheck?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Checks list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(checker.checks) { check in
                        CheckRow(check: check) {
                            selectedCheck = check
                            showingFixSheet = true
                        }
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Footer
            footer
        }
        .frame(minWidth: 600, minHeight: 450)
        .task {
            await checker.runAll()
        }
        .sheet(isPresented: $showingFixSheet) {
            if let check = selectedCheck {
                FixSheet(check: check, checker: checker) {
                    showingFixSheet = false
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("System Check")
                    .font(.title2.bold())
                
                Text("Verifying your system meets OpenClaw requirements")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Status badge
            if !checker.isRunning {
                statusBadge
            } else {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: checker.allPassed ? "checkmark.circle.fill" : 
                             checker.hasBlockingIssues ? "xmark.circle.fill" : "exclamationmark.triangle.fill")
            Text(checker.allPassed ? "Ready" : 
                 checker.hasBlockingIssues ? "Issues Found" : "Warnings")
        }
        .font(.caption.bold())
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(checker.allPassed ? Color.green : 
                   checker.hasBlockingIssues ? Color.red : Color.orange)
        .clipShape(Capsule())
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack {
            Button {
                Task { await checker.runAll() }
            } label: {
                Label("Re-check", systemImage: "arrow.clockwise")
            }
            .disabled(checker.isRunning)
            
            Spacer()
            
            if checker.hasBlockingIssues {
                Text("Fix issues before continuing")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Button("Continue") {
                // Navigate to next module
            }
            .buttonStyle(.borderedProminent)
            .disabled(checker.hasBlockingIssues || checker.isRunning)
        }
        .padding()
    }
}

// MARK: - Check Row

struct CheckRow: View {
    let check: PreflightCheck
    let onFix: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Status icon
            statusIcon
                .frame(width: 32, height: 32)
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(check.name)
                        .font(.headline)
                    
                    if check.status == .checking {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                
                Text(check.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let detail = check.detail, check.status != .checking {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(detailColor)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
            
            // Fix button
            if check.fixAction != nil && (check.status == .fail || check.status == .warn) {
                Button("Fix") {
                    onFix()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(borderColor, lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        ZStack {
            Circle()
                .fill(iconBackground)
            
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconColor)
        }
    }
    
    private var iconName: String {
        switch check.status {
        case .pass: return "checkmark"
        case .fail: return "xmark"
        case .warn: return "exclamationmark"
        case .checking: return "ellipsis"
        }
    }
    
    private var iconColor: Color {
        switch check.status {
        case .pass: return .green
        case .fail: return .red
        case .warn: return .orange
        case .checking: return .gray
        }
    }
    
    private var iconBackground: Color {
        iconColor.opacity(0.15)
    }
    
    private var detailColor: Color {
        switch check.status {
        case .pass: return .green
        case .fail: return .red
        case .warn: return .orange
        case .checking: return .secondary
        }
    }
    
    private var backgroundColor: Color {
        switch check.status {
        case .fail: return Color.red.opacity(0.05)
        case .warn: return Color.orange.opacity(0.05)
        default: return Color(nsColor: .controlBackgroundColor)
        }
    }
    
    private var borderColor: Color {
        switch check.status {
        case .fail: return Color.red.opacity(0.2)
        case .warn: return Color.orange.opacity(0.2)
        default: return Color.clear
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
            HStack {
                Image(systemName: check.icon)
                    .font(.title)
                    .foregroundStyle(.orange)
                
                VStack(alignment: .leading) {
                    Text("Fix: \(check.name)")
                        .font(.headline)
                    
                    if let detail = check.detail {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            
            Divider()
            
            // Fix options
            if let fix = check.fixAction {
                VStack(alignment: .leading, spacing: 16) {
                    // Auto fix (if available)
                    if let command = fix.command {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Automatic Fix")
                                .font(.subheadline.bold())
                            
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
                                    Text("Run Fix")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isFixing)
                        }
                        
                        Divider()
                    }
                    
                    // Manual steps
                    if !fix.manualSteps.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Manual Steps")
                                .font(.subheadline.bold())
                            
                            ForEach(Array(fix.manualSteps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(index + 1).")
                                        .font(.caption.bold())
                                        .foregroundStyle(.secondary)
                                    
                                    Text(step)
                                        .font(.caption)
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
                Button("Close") {
                    onDismiss()
                }
            }
        }
        .padding()
        .frame(width: 450, height: 350)
    }
}
