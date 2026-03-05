import Foundation

/// Execute shell commands and capture output
enum ShellRunner {
    struct Result: Sendable {
        let exitCode: Int32
        let stdout: String
        let stderr: String
        var success: Bool { exitCode == 0 }
    }

    /// Build a comprehensive PATH that covers common Node.js install locations
    private static func buildEnhancedPATH() -> (env: [String: String], nodePaths: [String]) {
        var env = ProcessInfo.processInfo.environment
        let home = env["HOME"] ?? NSHomeDirectory()

        var extraPaths: [String] = [
            "\(home)/.local/share/pnpm", // pnpm global bin (PNPM_HOME)
            "/opt/homebrew/bin",          // Homebrew (Apple Silicon)
            "/usr/local/bin",             // Homebrew (Intel) / manual installs
        ]

        // nvm: find latest installed version dynamically
        let nvmDir = env["NVM_DIR"] ?? "\(home)/.nvm"
        let nvmVersionsDir = "\(nvmDir)/versions/node"
        if let versions = try? FileManager.default.contentsOfDirectory(atPath: nvmVersionsDir) {
            // Sort versions descending, prefer v22+
            let sorted = versions
                .filter { $0.hasPrefix("v") }
                .sorted { a, b in
                    let aMajor = Int(a.dropFirst().split(separator: ".").first ?? "0") ?? 0
                    let bMajor = Int(b.dropFirst().split(separator: ".").first ?? "0") ?? 0
                    return aMajor > bMajor
                }
            for v in sorted {
                extraPaths.append("\(nvmVersionsDir)/\(v)/bin")
            }
        }

        // fnm
        let fnmDir = "\(home)/Library/Application Support/fnm/node-versions"
        if let versions = try? FileManager.default.contentsOfDirectory(atPath: fnmDir) {
            for v in versions.filter({ $0.hasPrefix("v") }) {
                extraPaths.append("\(fnmDir)/\(v)/installation/bin")
            }
        }
        // fnm also uses ~/.local/share/fnm on some setups
        let fnmAlt = "\(home)/.local/share/fnm/node-versions"
        if let versions = try? FileManager.default.contentsOfDirectory(atPath: fnmAlt) {
            for v in versions.filter({ $0.hasPrefix("v") }) {
                extraPaths.append("\(fnmAlt)/\(v)/installation/bin")
            }
        }

        // volta
        extraPaths.append("\(home)/.volta/bin")

        // asdf
        let asdfNodeDir = "\(home)/.asdf/installs/nodejs"
        if let versions = try? FileManager.default.contentsOfDirectory(atPath: asdfNodeDir) {
            for v in versions {
                extraPaths.append("\(asdfNodeDir)/\(v)/bin")
            }
        }

        // n (tj/n version manager)
        extraPaths.append("/usr/local/n/versions/node/22.0.0/bin") // common default
        extraPaths.append("\(home)/n/bin")

        // Append existing PATH last
        extraPaths.append(env["PATH"] ?? "")

        env["PATH"] = extraPaths.joined(separator: ":")

        // Ensure PNPM_HOME is set so pnpm knows where to install global packages
        if env["PNPM_HOME"] == nil {
            env["PNPM_HOME"] = "\(home)/.local/share/pnpm"
        }

        return (env, extraPaths)
    }

    /// Run a shell command synchronously
    static func run(_ command: String, timeout: TimeInterval = 30) async -> Result {
        await withCheckedContinuation { continuation in
            let process = Process()
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()

            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-c", command]
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            let (env, _) = buildEnhancedPATH()
            process.environment = env

            do {
                try process.run()
                process.waitUntilExit()

                let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

                continuation.resume(returning: Result(
                    exitCode: process.terminationStatus,
                    stdout: stdout.trimmingCharacters(in: .whitespacesAndNewlines),
                    stderr: stderr.trimmingCharacters(in: .whitespacesAndNewlines)
                ))
            } catch {
                continuation.resume(returning: Result(
                    exitCode: -1,
                    stdout: "",
                    stderr: error.localizedDescription
                ))
            }
        }
    }
    
    /// Run a shell command with streaming output via callback
    /// Uses polling instead of handlers to avoid Swift 6 concurrency issues
    @MainActor
    static func runWithStreaming(
        _ command: String,
        onOutput: @escaping @MainActor (String) -> Void,
        onError: @escaping @MainActor (String) -> Void
    ) async -> Result {
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        
        let (env, _) = buildEnhancedPATH()
        process.environment = env

        do {
            try process.run()
        } catch {
            return Result(exitCode: -1, stdout: "", stderr: error.localizedDescription)
        }
        
        // Poll for output while process is running
        var stdoutData = Data()
        var stderrData = Data()
        
        while process.isRunning {
            // Read available stdout
            let outData = stdoutPipe.fileHandleForReading.availableData
            if !outData.isEmpty {
                stdoutData.append(outData)
                if let str = String(data: outData, encoding: .utf8) {
                    onOutput(str)
                }
            }
            
            // Read available stderr
            let errData = stderrPipe.fileHandleForReading.availableData
            if !errData.isEmpty {
                stderrData.append(errData)
                if let str = String(data: errData, encoding: .utf8) {
                    onError(str)
                }
            }
            
            // Small delay to avoid busy waiting
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }
        
        // Read any remaining output
        let finalOut = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        if !finalOut.isEmpty {
            stdoutData.append(finalOut)
            if let str = String(data: finalOut, encoding: .utf8) {
                onOutput(str)
            }
        }
        
        let finalErr = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        if !finalErr.isEmpty {
            stderrData.append(finalErr)
            if let str = String(data: finalErr, encoding: .utf8) {
                onError(str)
            }
        }
        
        let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderr = String(data: stderrData, encoding: .utf8) ?? ""
        
        return Result(
            exitCode: process.terminationStatus,
            stdout: stdout.trimmingCharacters(in: .whitespacesAndNewlines),
            stderr: stderr.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}
