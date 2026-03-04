// ClaudeService — Claude API Integration for AI Support

import Foundation

actor ClaudeService {
    static let shared = ClaudeService()
    
    private let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model = "claude-sonnet-4-20250514"
    
    private var apiKey: String? {
        // Try environment variable first, then keychain
        ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]
    }
    
    struct Message: Codable, Identifiable, Sendable {
        let id: UUID
        let role: Role
        let content: String
        let timestamp: Date
        
        enum Role: String, Codable, Sendable {
            case user
            case assistant
        }
        
        init(role: Role, content: String) {
            self.id = UUID()
            self.role = role
            self.content = content
            self.timestamp = Date()
        }
    }
    
    struct APIRequest: Codable {
        let model: String
        let max_tokens: Int
        let system: String
        let messages: [APIMessage]
        
        struct APIMessage: Codable {
            let role: String
            let content: String
        }
    }
    
    struct APIResponse: Codable {
        let content: [ContentBlock]
        
        struct ContentBlock: Codable {
            let type: String
            let text: String?
        }
        
        var text: String? {
            content.first(where: { $0.type == "text" })?.text
        }
    }
    
    struct APIError: Codable {
        let error: ErrorDetail
        
        struct ErrorDetail: Codable {
            let type: String
            let message: String
        }
    }
    
    func sendMessage(
        userMessage: String,
        conversationHistory: [Message],
        systemContext: String
    ) async throws -> String {
        guard let apiKey = apiKey else {
            throw ClaudeError.missingAPIKey
        }
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        // Build messages array
        var apiMessages: [APIRequest.APIMessage] = conversationHistory.map { msg in
            APIRequest.APIMessage(role: msg.role.rawValue, content: msg.content)
        }
        apiMessages.append(APIRequest.APIMessage(role: "user", content: userMessage))
        
        let apiRequest = APIRequest(
            model: model,
            max_tokens: 1024,
            system: systemContext,
            messages: apiMessages
        )
        
        request.httpBody = try JSONEncoder().encode(apiRequest)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(APIError.self, from: data) {
                throw ClaudeError.apiError(errorResponse.error.message)
            }
            throw ClaudeError.httpError(httpResponse.statusCode)
        }
        
        let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
        
        guard let text = apiResponse.text else {
            throw ClaudeError.emptyResponse
        }
        
        return text
    }
    
    enum ClaudeError: LocalizedError {
        case missingAPIKey
        case invalidResponse
        case httpError(Int)
        case apiError(String)
        case emptyResponse
        
        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "ANTHROPIC_API_KEY not found. Set it in environment or enter below."
            case .invalidResponse:
                return "Invalid response from API"
            case .httpError(let code):
                return "HTTP error: \(code)"
            case .apiError(let message):
                return "API error: \(message)"
            case .emptyResponse:
                return "Empty response from Claude"
            }
        }
    }
}
