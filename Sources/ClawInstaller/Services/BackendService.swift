// BackendService — HTTP client for claw-backend API
// Handles AI chat and telemetry event reporting

import Foundation
import CryptoKit
import AppKit

actor BackendService {
    static let shared = BackendService()

    private let baseURL: URL
    private let session = URLSession.shared
    private let deviceId: String

    init() {
        let urlString = ProcessInfo.processInfo.environment["CLAW_BACKEND_URL"]
            ?? "https://clawinstaller.up.railway.app"
        self.baseURL = URL(string: urlString)!
        self.deviceId = BackendService.generateDeviceId()
    }

    // MARK: - Auth (Email OTP)

    struct SendOTPRequest: Codable {
        let email: String
    }

    struct SendOTPResponse: Codable {
        let sent: Bool?
        let dev: Bool?
        let error: String?
    }

    struct VerifyRequest: Codable {
        let email: String
        let code: String
    }

    struct VerifyResponse: Codable {
        let verified: Bool?
        let user: AuthUser?
        let token: String?
        let error: String?
    }

    struct AuthUser: Codable {
        let id: String
        let email: String
        let name: String?
        let plan: String
    }

    func sendOTP(email: String) async throws {
        let url = baseURL.appendingPathComponent("api/auth/send-otp")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        let body = SendOTPRequest(email: email)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            let decoded = try? JSONDecoder().decode(SendOTPResponse.self, from: data)
            throw BackendError.serverError(decoded?.error ?? "HTTP \(httpResponse.statusCode)")
        }
    }

    func verifyOTP(email: String, code: String) async throws -> VerifyResponse {
        let url = baseURL.appendingPathComponent("api/auth/verify")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        let body = VerifyRequest(email: email, code: code)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(VerifyResponse.self, from: data)

        if httpResponse.statusCode != 200 {
            throw BackendError.serverError(decoded.error ?? "HTTP \(httpResponse.statusCode)")
        }

        return decoded
    }

    // MARK: - AI Chat

    struct ChatRequest: Codable {
        let message: String
        let context: InstallContext?
        let history: [HistoryMessage]?
    }

    struct InstallContext: Codable {
        let nodeVersion: String?
        let packageManager: String?
        let arch: String?
        let preflightResults: [PreflightResult]?
        let installedVersion: String?
        let channels: [String]?
        let gatewayStatus: String?
    }

    struct PreflightResult: Codable {
        let name: String
        let status: String  // pass, fail, warn
        let detail: String?
    }

    struct HistoryMessage: Codable {
        let role: String  // user, assistant
        let content: String
    }

    struct ChatResponse: Codable {
        let response: String
        let usage: Usage?
        let model: String?
        let error: String?
    }

    struct Usage: Codable {
        let inputTokens: Int?
        let outputTokens: Int?
    }

    func sendMessage(
        message: String,
        context: InstallContext? = nil,
        history: [HistoryMessage]? = nil
    ) async throws -> String {
        let url = baseURL.appendingPathComponent("api/ai/chat")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body = ChatRequest(message: message, context: context, history: history)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }

        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)

        if let error = chatResponse.error {
            throw BackendError.serverError(error)
        }

        guard httpResponse.statusCode == 200 else {
            throw BackendError.serverError(chatResponse.error ?? "HTTP \(httpResponse.statusCode)")
        }

        return chatResponse.response
    }

    // MARK: - Telemetry

    struct TelemetryEvent: Codable {
        let deviceId: String
        let event: String
        let module: String
        let meta: [String: String]?
        let durationMs: Int?
        // System info
        let arch: String?
        let macosVersion: String?
        let nodeVersion: String?
        let packageManager: String?
        let appVersion: String?
        // Device info
        let macModel: String?
        let memoryGB: Int?
        let locale: String?
        let timezone: String?
        let screenResolution: String?
    }

    func sendTelemetryEvent(
        event: String,
        module: String,
        meta: [String: String]? = nil,
        durationMs: Int? = nil,
        arch: String? = nil,
        nodeVersion: String? = nil,
        packageManager: String? = nil
    ) async {
        let url = baseURL.appendingPathComponent("api/telemetry/event")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 5

        let deviceInfo = DeviceInfo.collect()

        let body = TelemetryEvent(
            deviceId: deviceId,
            event: event,
            module: module,
            meta: meta,
            durationMs: durationMs,
            arch: arch ?? deviceInfo.arch,
            macosVersion: deviceInfo.macosVersion,
            nodeVersion: nodeVersion,
            packageManager: packageManager,
            appVersion: deviceInfo.appVersion,
            macModel: deviceInfo.macModel,
            memoryGB: deviceInfo.memoryGB,
            locale: deviceInfo.locale,
            timezone: deviceInfo.timezone,
            screenResolution: deviceInfo.screenResolution
        )

        do {
            request.httpBody = try JSONEncoder().encode(body)
            let _ = try await session.data(for: request)
        } catch {
            // Telemetry is fire-and-forget, never block the user
        }
    }

    // MARK: - Status

    struct StatusResponse: Codable {
        let available: Bool
        let model: String?
    }

    func checkAvailability() async -> Bool {
        let url = baseURL.appendingPathComponent("api/ai/status")
        do {
            let (data, _) = try await session.data(from: url)
            let status = try JSONDecoder().decode(StatusResponse.self, from: data)
            return status.available
        } catch {
            return false
        }
    }

    // MARK: - Device ID

    private static func generateDeviceId() -> String {
        // SHA-256 hash of hardware UUID for anonymous device tracking
        let platform = ProcessInfo.processInfo.environment["__CF_USER_TEXT_ENCODING"] ?? "unknown"
        let host = ProcessInfo.processInfo.hostName
        let raw = "\(host)-\(platform)-clawinstaller"
        let hash = SHA256.hash(data: Data(raw.utf8))
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Device Info

struct DeviceInfo {
    let arch: String
    let macosVersion: String
    let appVersion: String
    let macModel: String?
    let memoryGB: Int
    let locale: String
    let timezone: String
    let screenResolution: String?

    static func collect() -> DeviceInfo {
        let processInfo = ProcessInfo.processInfo

        // Architecture
        #if arch(arm64)
        let arch = "arm64"
        #else
        let arch = "x86_64"
        #endif

        // macOS version
        let osVersion = processInfo.operatingSystemVersion
        let macosVersion = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"

        // App version
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"

        // Mac model (e.g., "MacBookPro18,1")
        let macModel = sysctl("hw.model")

        // Memory in GB
        let memoryGB = Int(processInfo.physicalMemory / (1024 * 1024 * 1024))

        // Locale & timezone
        let locale = Locale.current.identifier // e.g., "zh_TW"
        let timezone = TimeZone.current.identifier // e.g., "Asia/Taipei"

        // Screen resolution (MainActor-safe)
        var screenResolution: String? = nil
        if Thread.isMainThread, let screen = NSScreen.main {
            let size = screen.frame.size
            let scale = screen.backingScaleFactor
            screenResolution = "\(Int(size.width * scale))x\(Int(size.height * scale))"
        }

        return DeviceInfo(
            arch: arch,
            macosVersion: macosVersion,
            appVersion: appVersion,
            macModel: macModel,
            memoryGB: memoryGB,
            locale: locale,
            timezone: timezone,
            screenResolution: screenResolution
        )
    }

    private static func sysctl(_ name: String) -> String? {
        var size = 0
        sysctlbyname(name, nil, &size, nil, 0)
        guard size > 0 else { return nil }
        var value = [CChar](repeating: 0, count: size)
        sysctlbyname(name, &value, &size, nil, 0)
        return String(cString: value)
    }
}

// MARK: - Errors

enum BackendError: LocalizedError {
    case invalidResponse
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "無法連接到伺服器"
        case .serverError(let message):
            return message
        }
    }
}
