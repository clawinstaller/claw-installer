// KnowledgeBase — OpenClaw docs + GitHub Issues for AI context

import Foundation

actor KnowledgeBase {
    static let shared = KnowledgeBase()
    
    private let githubRepo = "anthropics/anthropic-tools"  // Replace with actual OpenClaw repo
    private let openclawRepo = "openclaw/openclaw"
    
    private var cachedIssues: [GitHubIssue] = []
    private var lastFetch: Date?
    private let fetchInterval: TimeInterval = 3600  // 1 hour
    
    // MARK: - GitHub Issues
    
    struct GitHubIssue: Codable, Identifiable, Sendable {
        let id: Int
        let number: Int
        let title: String
        let body: String?
        let state: String
        let labels: [Label]
        let created_at: String
        let html_url: String
        
        struct Label: Codable, Sendable {
            let name: String
            let color: String
        }
        
        var isRecent: Bool {
            guard let date = ISO8601DateFormatter().date(from: created_at) else { return false }
            return Date().timeIntervalSince(date) < 30 * 24 * 3600  // 30 days
        }
        
        var summary: String {
            "#\(number): \(title)"
        }
    }
    
    func fetchIssues(forceRefresh: Bool = false) async throws -> [GitHubIssue] {
        // Check cache
        if !forceRefresh, let lastFetch = lastFetch,
           Date().timeIntervalSince(lastFetch) < fetchInterval,
           !cachedIssues.isEmpty {
            return cachedIssues
        }
        
        let url = URL(string: "https://api.github.com/repos/\(openclawRepo)/issues?state=all&per_page=50&labels=bug,help%20wanted")!
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("ClawInstaller/1.0", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw KnowledgeBaseError.fetchFailed
        }
        
        let issues = try JSONDecoder().decode([GitHubIssue].self, from: data)
        cachedIssues = issues
        lastFetch = Date()
        
        return issues
    }
    
    func searchIssues(query: String) -> [GitHubIssue] {
        let lowercased = query.lowercased()
        return cachedIssues.filter { issue in
            issue.title.lowercased().contains(lowercased) ||
            (issue.body?.lowercased().contains(lowercased) ?? false) ||
            issue.labels.contains { $0.name.lowercased().contains(lowercased) }
        }
    }
    
    // MARK: - Documentation
    
    static let commonTroubleshooting: [String: String] = [
        "gateway won't start": """
            Common fixes for Gateway startup issues:
            1. Check if port 3000 is already in use: `lsof -i :3000`
            2. Ensure Node.js is installed: `node --version`
            3. Check logs: `~/.openclaw/logs/gateway.log`
            4. Try restarting: `openclaw gateway restart`
            """,
        
        "telegram bot not responding": """
            Telegram bot troubleshooting:
            1. Verify bot token in ~/.openclaw/openclaw.json
            2. Ensure bot was added to your chat
            3. Check if you messaged /start to the bot
            4. Verify internet connectivity
            5. Check gateway logs for errors
            """,
        
        "discord bot offline": """
            Discord bot troubleshooting:
            1. Verify bot token and application ID
            2. Check if bot was invited to server with correct permissions
            3. Ensure "Message Content Intent" is enabled in Discord Developer Portal
            4. Check gateway is running: `openclaw gateway status`
            """,
        
        "whatsapp qr code": """
            WhatsApp linking issues:
            1. QR code expires after ~60 seconds - refresh if needed
            2. Ensure phone has internet connection
            3. Try: Settings → Linked Devices → Link a Device
            4. If session exists, try unlinking first
            """,
        
        "high memory usage": """
            Memory optimization:
            1. Check conversation history size
            2. Consider enabling message pruning
            3. Review number of active channels
            4. Check for memory leaks: `openclaw status`
            """,
        
        "api key issues": """
            API key troubleshooting:
            1. Verify ANTHROPIC_API_KEY is set: `echo $ANTHROPIC_API_KEY`
            2. Check key starts with 'sk-ant-'
            3. Ensure key hasn't expired
            4. Try regenerating key at console.anthropic.com
            """
    ]
    
    func findRelevantDocs(for query: String) -> String {
        let lowercased = query.lowercased()
        
        var relevantSections: [String] = []
        
        for (topic, content) in Self.commonTroubleshooting {
            if lowercased.contains(topic) || topic.split(separator: " ").contains(where: { lowercased.contains($0.lowercased()) }) {
                relevantSections.append("## \(topic.capitalized)\n\(content)")
            }
        }
        
        return relevantSections.isEmpty ? "" : relevantSections.joined(separator: "\n\n")
    }
    
    // MARK: - Context Builder
    
    func buildContext(
        query: String,
        installState: InstallState
    ) async -> String {
        var context = """
        You are a helpful support assistant for OpenClaw, an AI assistant framework.
        You help users troubleshoot installation and configuration issues.
        
        ## Current Installation State
        \(installState.description)
        
        ## Guidelines
        - Be concise but thorough
        - Provide specific commands when helpful
        - If unsure, suggest checking logs at ~/.openclaw/logs/
        - For complex issues, suggest opening a GitHub issue
        
        """
        
        // Add relevant docs
        let relevantDocs = findRelevantDocs(for: query)
        if !relevantDocs.isEmpty {
            context += "\n## Relevant Documentation\n\(relevantDocs)\n"
        }
        
        // Add recent related issues
        let relatedIssues = searchIssues(query: query).prefix(3)
        if !relatedIssues.isEmpty {
            context += "\n## Related GitHub Issues\n"
            for issue in relatedIssues {
                context += "- \(issue.summary) (\(issue.state))\n"
            }
        }
        
        return context
    }
    
    struct InstallState: Sendable {
        let nodeInstalled: Bool
        let openclawInstalled: Bool
        let gatewayRunning: Bool
        let configuredChannels: [String]
        let lastError: String?
        
        var description: String {
            """
            - Node.js: \(nodeInstalled ? "✓ Installed" : "✗ Not installed")
            - OpenClaw: \(openclawInstalled ? "✓ Installed" : "✗ Not installed")
            - Gateway: \(gatewayRunning ? "✓ Running" : "✗ Not running")
            - Channels: \(configuredChannels.isEmpty ? "None configured" : configuredChannels.joined(separator: ", "))
            \(lastError.map { "- Last Error: \($0)" } ?? "")
            """
        }
    }
    
    enum KnowledgeBaseError: LocalizedError {
        case fetchFailed
        
        var errorDescription: String? {
            switch self {
            case .fetchFailed:
                return "Failed to fetch GitHub issues"
            }
        }
    }
}
