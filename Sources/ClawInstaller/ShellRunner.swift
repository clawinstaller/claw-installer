import Foundation

/// Execute shell commands and capture output
enum ShellRunner {
    struct Result: Sendable {
        let exitCode: Int32
        let stdout: String
        let stderr: String
        var success: Bool { exitCode == 0 }
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
            
            // Merge PATH for homebrew, nvm, etc.
            var env = ProcessInfo.processInfo.environment
            let home = env["HOME"] ?? NSHomeDirectory()
            let paths = [
                "/opt/homebrew/bin",
                "/usr/local/bin",
                "\(home)/.nvm/versions/node/v22/bin",
                env["PATH"] ?? ""
            ]
            env["PATH"] = paths.joined(separator: ":")
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
        
        // Merge PATH for homebrew, nvm, etc.
        var env = ProcessInfo.processInfo.environment
        let home = env["HOME"] ?? NSHomeDirectory()
        let paths = [
            "/opt/homebrew/bin",
            "/usr/local/bin",
            "\(home)/.nvm/versions/node/v22/bin",
            env["PATH"] ?? ""
        ]
        env["PATH"] = paths.joined(separator: ":")
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
