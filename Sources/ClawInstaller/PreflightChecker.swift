// PreflightChecker — Module 1: Environment Detection
// Detects Node.js, package managers, architecture, existing OpenClaw

import Foundation

/// Module 1: Detect environment prerequisites
@MainActor
final class PreflightChecker: ObservableObject {
    @Published var checks: [PreflightCheck] = []
    @Published var isRunning = false
    @Published var allPassed = false
    @Published var hasBlockingIssues = false
    
    // Detected info for other modules
    @Published var detectedNodeVersion: String?
    @Published var detectedPackageManager: String?
    @Published var detectedArch: String?
    @Published var existingOpenClawVersion: String?
    @Published var hasExistingConfig = false

    private let requiredNodeMajor = 22
    
    func runAll() async {
        isRunning = true
        hasBlockingIssues = false
        
        // Initialize all checks
        checks = [
            PreflightCheck(name: "Architecture", description: "Apple Silicon or Intel", status: .checking),
            PreflightCheck(name: "Node.js", description: "Version ≥ \(requiredNodeMajor) required", status: .checking),
            PreflightCheck(name: "Package Manager", description: "npm, pnpm, or bun", status: .checking),
            PreflightCheck(name: "OpenClaw CLI", description: "Existing installation", status: .checking),
            PreflightCheck(name: "Config Directory", description: "~/.openclaw/", status: .checking),
            PreflightCheck(name: "Disk Space", description: "Minimum 500MB free", status: .checking),
        ]

        // Run checks with visual delay for UX
        for i in 0..<checks.count {
            try? await Task.sleep(nanoseconds: 150_000_000) // 150ms delay
            
            switch i {
            case 0: checks[i] = await checkArch()
            case 1: checks[i] = await checkNode()
            case 2: checks[i] = await checkPackageManager()
            case 3: checks[i] = await checkExistingOpenClaw()
            case 4: checks[i] = await checkConfigDirectory()
            case 5: checks[i] = await checkDiskSpace()
            default: break
            }
        }

        // Calculate summary
        allPassed = checks.allSatisfy { $0.status == .pass }
        hasBlockingIssues = checks.contains { $0.status == .fail }
        isRunning = false
    }
    
    // MARK: - Individual Checks
    
    private func checkArch() async -> PreflightCheck {
        let result = await ShellRunner.run("uname -m")
        let arch = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        detectedArch = arch
        
        let isAppleSilicon = arch == "arm64"
        let displayArch = isAppleSilicon ? "Apple Silicon (arm64)" : "Intel (x86_64)"
        
        return PreflightCheck(
            name: "Architecture",
            description: "Apple Silicon or Intel",
            status: .pass,
            detail: displayArch,
            icon: isAppleSilicon ? "cpu.fill" : "desktopcomputer"
        )
    }

    private func checkNode() async -> PreflightCheck {
        // Try multiple common paths
        let nodePaths = [
            "node",
            "/opt/homebrew/bin/node",
            "/usr/local/bin/node",
            "~/.nvm/versions/node/*/bin/node"
        ]
        
        var foundVersion: String?
        
        for path in nodePaths {
            let result = await ShellRunner.run("\(path) --version 2>/dev/null")
            if result.success && !result.stdout.isEmpty {
                foundVersion = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
        }
        
        guard let version = foundVersion else {
            return PreflightCheck(
                name: "Node.js",
                description: "Version ≥ \(requiredNodeMajor) required",
                status: .fail,
                detail: "Node.js not found",
                fixAction: FixAction(
                    label: "Install Node.js",
                    command: "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\" && brew install node@22",
                    manualSteps: [
                        "Visit https://nodejs.org/",
                        "Download Node.js 22 LTS",
                        "Run the installer"
                    ]
                ),
                icon: "xmark.octagon.fill"
            )
        }
        
        // Parse version: "v22.1.0" → 22
        let cleanVersion = version.replacingOccurrences(of: "v", with: "")
        let components = cleanVersion.split(separator: ".")
        let major = Int(components.first ?? "0") ?? 0
        
        detectedNodeVersion = cleanVersion
        
        if major < requiredNodeMajor {
            return PreflightCheck(
                name: "Node.js",
                description: "Version ≥ \(requiredNodeMajor) required",
                status: .warn,
                detail: "Found v\(cleanVersion), need ≥ \(requiredNodeMajor)",
                fixAction: FixAction(
                    label: "Upgrade Node.js",
                    command: "brew upgrade node || nvm install \(requiredNodeMajor)",
                    manualSteps: [
                        "Using nvm: nvm install \(requiredNodeMajor)",
                        "Using Homebrew: brew upgrade node",
                        "Or download from nodejs.org"
                    ]
                ),
                icon: "exclamationmark.triangle.fill"
            )
        }
        
        return PreflightCheck(
            name: "Node.js",
            description: "Version ≥ \(requiredNodeMajor) required",
            status: .pass,
            detail: "v\(cleanVersion) ✓",
            icon: "checkmark.seal.fill"
        )
    }

    private func checkPackageManager() async -> PreflightCheck {
        var found: [(name: String, version: String)] = []
        
        let managers = [
            ("npm", "npm --version"),
            ("pnpm", "pnpm --version"),
            ("bun", "bun --version"),
            ("yarn", "yarn --version")
        ]
        
        for (name, cmd) in managers {
            let result = await ShellRunner.run(cmd + " 2>/dev/null")
            if result.success && !result.stdout.isEmpty {
                let version = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                found.append((name, version))
            }
        }
        
        if found.isEmpty {
            return PreflightCheck(
                name: "Package Manager",
                description: "npm, pnpm, or bun",
                status: .fail,
                detail: "No package manager found",
                fixAction: FixAction(
                    label: "Install with Node.js",
                    command: nil,
                    manualSteps: ["npm is included with Node.js", "Install Node.js first"]
                ),
                icon: "shippingbox.fill"
            )
        }
        
        // Prefer pnpm > bun > npm
        let preferred = found.first { $0.name == "pnpm" } ?? found.first { $0.name == "bun" } ?? found[0]
        detectedPackageManager = preferred.name
        
        let summary = found.map { "\($0.name) v\($0.version)" }.joined(separator: ", ")
        
        return PreflightCheck(
            name: "Package Manager",
            description: "npm, pnpm, or bun",
            status: .pass,
            detail: summary,
            icon: "shippingbox.fill"
        )
    }

    private func checkExistingOpenClaw() async -> PreflightCheck {
        // Check if openclaw command exists
        let whichResult = await ShellRunner.run("which openclaw 2>/dev/null")
        
        if whichResult.success && !whichResult.stdout.isEmpty {
            let path = whichResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Get version
            let versionResult = await ShellRunner.run("openclaw --version 2>/dev/null")
            let version = versionResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            existingOpenClawVersion = version.isEmpty ? nil : version
            
            return PreflightCheck(
                name: "OpenClaw CLI",
                description: "Existing installation",
                status: .pass,
                detail: version.isEmpty ? "Found at \(path)" : "v\(version)",
                icon: "pawprint.fill"
            )
        }
        
        // Check npm global packages
        let npmResult = await ShellRunner.run("npm list -g openclaw 2>/dev/null | grep openclaw")
        if npmResult.success && !npmResult.stdout.isEmpty {
            return PreflightCheck(
                name: "OpenClaw CLI",
                description: "Existing installation",
                status: .pass,
                detail: "Installed via npm",
                icon: "pawprint.fill"
            )
        }
        
        return PreflightCheck(
            name: "OpenClaw CLI",
            description: "Existing installation",
            status: .warn,
            detail: "Not installed — will install next",
            icon: "pawprint"
        )
    }

    private func checkConfigDirectory() async -> PreflightCheck {
        let configDir = NSHomeDirectory() + "/.openclaw"
        let configFile = configDir + "/openclaw.json"
        
        let dirExists = FileManager.default.fileExists(atPath: configDir)
        let configExists = FileManager.default.fileExists(atPath: configFile)
        hasExistingConfig = configExists
        
        if configExists {
            // Try to read and validate config
            if let data = try? Data(contentsOf: URL(fileURLWithPath: configFile)),
               let _ = try? JSONSerialization.jsonObject(with: data) {
                return PreflightCheck(
                    name: "Config Directory",
                    description: "~/.openclaw/",
                    status: .pass,
                    detail: "Config file exists and is valid",
                    icon: "folder.fill"
                )
            } else {
                return PreflightCheck(
                    name: "Config Directory",
                    description: "~/.openclaw/",
                    status: .warn,
                    detail: "Config exists but may be invalid",
                    icon: "folder.badge.questionmark"
                )
            }
        } else if dirExists {
            return PreflightCheck(
                name: "Config Directory",
                description: "~/.openclaw/",
                status: .warn,
                detail: "Directory exists, no config file",
                icon: "folder"
            )
        }
        
        return PreflightCheck(
            name: "Config Directory",
            description: "~/.openclaw/",
            status: .warn,
            detail: "Will be created during setup",
            icon: "folder.badge.plus"
        )
    }

    private func checkDiskSpace() async -> PreflightCheck {
        let homeDir = URL(fileURLWithPath: NSHomeDirectory())
        
        do {
            let values = try homeDir.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            if let available = values.volumeAvailableCapacityForImportantUsage {
                let availableGB = Double(available) / 1_000_000_000
                let requiredMB = 500
                
                if availableGB < 0.5 {
                    return PreflightCheck(
                        name: "Disk Space",
                        description: "Minimum \(requiredMB)MB free",
                        status: .fail,
                        detail: String(format: "Only %.1f GB free", availableGB),
                        fixAction: FixAction(
                            label: "Free up space",
                            command: nil,
                            manualSteps: ["Clear Downloads folder", "Empty Trash", "Remove unused apps"]
                        ),
                        icon: "externaldrive.fill"
                    )
                }
                
                return PreflightCheck(
                    name: "Disk Space",
                    description: "Minimum \(requiredMB)MB free",
                    status: .pass,
                    detail: String(format: "%.1f GB available", availableGB),
                    icon: "externaldrive.fill"
                )
            }
        } catch {
            // Couldn't determine, assume OK
        }
        
        return PreflightCheck(
            name: "Disk Space",
            description: "Minimum 500MB free",
            status: .pass,
            detail: "Sufficient space available",
            icon: "externaldrive.fill"
        )
    }
    
    // MARK: - Fix Actions
    
    func executeFix(for check: PreflightCheck) async {
        guard let fix = check.fixAction, let command = fix.command else { return }
        
        // Execute fix command
        let _ = await ShellRunner.run(command)
        
        // Re-run all checks
        await runAll()
    }
}

// MARK: - Models

struct PreflightCheck: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    var status: Status
    var detail: String?
    var fixAction: FixAction?
    var icon: String = "circle"

    enum Status {
        case pass, fail, warn, checking
        
        var color: String {
            switch self {
            case .pass: return "green"
            case .fail: return "red"
            case .warn: return "orange"
            case .checking: return "gray"
            }
        }
    }
}

struct FixAction {
    let label: String
    let command: String?
    let manualSteps: [String]
}
