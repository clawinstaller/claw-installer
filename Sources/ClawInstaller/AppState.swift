import Foundation
import SwiftUI

/// Load the bundled logo image (works with swift run and .app)
func appLogoImage() -> NSImage {
    // SPM executables: Bundle.module has processed resources
    if let url = Bundle.module.url(forResource: "logo", withExtension: "png"),
       let img = NSImage(contentsOf: url) {
        return img
    }
    // Fallback: Bundle.main (for .app bundles)
    if let url = Bundle.main.url(forResource: "logo", withExtension: "png"),
       let img = NSImage(contentsOf: url) {
        return img
    }
    return NSApp.applicationIconImage
}

/// Shared app state across all views
@MainActor
final class AppState: ObservableObject {
    enum Step: Int, CaseIterable {
        case welcome = 0
        case preflight
        case install
        case channels
        case monitor  // Post-install home (sidebar mode)
        case support
    }

    enum HomeTab: String {
        case status
        case channels
        case ai
    }

    @Published var currentStep: Step = .welcome
    @Published var homeTab: HomeTab = .status

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
