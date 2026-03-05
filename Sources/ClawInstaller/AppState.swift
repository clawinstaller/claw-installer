import Foundation
import SwiftUI

/// Shared app state across all views
@MainActor
final class AppState: ObservableObject {
    enum Step: Int, CaseIterable {
        case welcome = 0
        case preflight
        case install
        case channels
        case monitor
        case support
    }

    @Published var currentStep: Step = .welcome

    // Auth state
    @AppStorage("userEmail") var userEmail: String = ""
    @AppStorage("userToken") var userToken: String = ""
    @AppStorage("userId") var userId: String = ""
    var isLoggedIn: Bool { !userToken.isEmpty }
    @Published var installProgress: Double = 0
    @Published var gatewayRunning: Bool = false
    @Published var isInstalling: Bool = false
    
    // Preflight results
    @Published var preflightChecker = PreflightChecker()

    // AI Support — auto-send context when navigating from error pages
    @Published var pendingAIQuestion: String?

    // Telemetry opt-out
    @AppStorage("telemetryEnabled") var telemetryEnabled: Bool = true

    /// Fire-and-forget telemetry event
    func trackEvent(_ event: String, module: String, meta: [String: String]? = nil) {
        guard telemetryEnabled else { return }
        Task.detached {
            await BackendService.shared.sendTelemetryEvent(
                event: event,
                module: module,
                meta: meta,
                arch: await MainActor.run { self.preflightChecker.detectedArch },
                nodeVersion: await MainActor.run { self.preflightChecker.detectedNodeVersion },
                packageManager: await MainActor.run { self.preflightChecker.detectedPackageManager }
            )
        }
    }
}
