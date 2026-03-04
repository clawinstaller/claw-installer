import Foundation

/// Shared app state across all views
@MainActor
final class AppState: ObservableObject {
    enum Step: Int, CaseIterable {
        case preflight = 0
        case install
        case channels
        case monitor
        case support
    }

    @Published var currentStep: Step = .preflight
    @Published var installProgress: Double = 0
    @Published var gatewayRunning: Bool = false
    @Published var isInstalling: Bool = false
    
    // Preflight results
    @Published var preflightChecker = PreflightChecker()
}
