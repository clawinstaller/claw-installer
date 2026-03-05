// HealthMonitorView — Module 4: Gateway Health Monitor
// Status check, daemon control, log viewer, uptime tracking

import SwiftUI
import Foundation

struct HealthMonitorView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var monitor = GatewayMonitor()
    @State private var selectedTab: MonitorTab = .status
    
    enum MonitorTab: String, CaseIterable {
        case status = "Status"
        case logs = "Logs"
        case stats = "Stats"
        
        var icon: String {
            switch self {
            case .status: return "heart.text.square"
            case .logs: return "doc.text"
            case .stats: return "chart.bar"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Tab bar
            tabBar
            
            // Content
            Group {
                switch selectedTab {
                case .status:
                    statusView
                case .logs:
                    logsView
                case .stats:
                    statsView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Divider()
            
            // Footer
            footer
        }
        .onAppear {
            monitor.startMonitoring()
            appState.gatewayRunning = monitor.isConnected
        }
        .onDisappear {
            monitor.stopMonitoring()
        }
        .onChange(of: monitor.isConnected) { _, newValue in
            appState.gatewayRunning = newValue
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Health Monitor")
                    .font(.title2.bold())
                
                Text("Gateway status and daemon control")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Connection status badge
            connectionBadge
        }
        .padding()
    }
    
    private var connectionBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(monitor.statusColor)
                .frame(width: 8, height: 8)
            Text(monitor.statusText)
        }
        .font(.caption.bold())
        .foregroundStyle(monitor.statusColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(monitor.statusColor.opacity(0.1))
        .clipShape(Capsule())
    }
    
    // MARK: - Tab Bar
    
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(MonitorTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                        Text(tab.rawValue)
                    }
                    .font(.subheadline)
                    .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(selectedTab == tab ? Color.accentColor.opacity(0.1) : .clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }
    
    // MARK: - Status View
    
    private var statusView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Main status card
                statusCard
                
                // Control buttons
                controlButtons
                
                // Quick info cards
                HStack(spacing: 12) {
                    infoCard(
                        icon: "clock",
                        title: "Uptime",
                        value: monitor.formattedUptime,
                        color: .blue
                    )
                    
                    infoCard(
                        icon: "message",
                        title: "Messages Today",
                        value: "\(monitor.messagesToday)",
                        color: .purple
                    )
                    
                    infoCard(
                        icon: "bolt",
                        title: "Connections",
                        value: "\(monitor.activeConnections)",
                        color: .orange
                    )
                }
                
                // Gateway info
                gatewayInfoCard
            }
            .padding()
        }
    }
    
    private var statusCard: some View {
        VStack(spacing: 16) {
            // Status icon
            ZStack {
                Circle()
                    .fill(monitor.statusColor.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                if monitor.showCheckingIndicator {
                    ProgressView()
                        .scaleEffect(1.5)
                } else {
                    Image(systemName: monitor.isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(monitor.statusColor)
                }
            }
            
            VStack(spacing: 4) {
                Text(monitor.isConnected ? "Gateway Running" : "Gateway Stopped")
                    .font(.title3.bold())
                
                Text(monitor.isConnected ? "Connected to ws://localhost:18789" : "Not connected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Last checked
            if let lastCheck = monitor.lastCheckTime {
                Text("Last checked: \(lastCheck, formatter: timeFormatter)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var controlButtons: some View {
        HStack(spacing: 12) {
            if monitor.isConnected {
                ControlButton(
                    title: "Stop",
                    icon: "stop.fill",
                    color: .red,
                    isLoading: monitor.isOperating
                ) {
                    Task { await monitor.stopGateway() }
                }
                
                ControlButton(
                    title: "Restart",
                    icon: "arrow.clockwise",
                    color: .orange,
                    isLoading: monitor.isOperating
                ) {
                    Task { await monitor.restartGateway() }
                }
            } else {
                ControlButton(
                    title: "Start Gateway",
                    icon: "play.fill",
                    color: .green,
                    isLoading: monitor.isOperating
                ) {
                    Task { await monitor.startGateway() }
                }
            }
            
            ControlButton(
                title: "Check",
                icon: "arrow.clockwise",
                color: .blue,
                isLoading: monitor.isChecking
            ) {
                Task { await monitor.checkStatus() }
            }
        }
    }
    
    private func infoCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title3.bold())
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var gatewayInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(.blue)
                Text("Gateway Info")
                    .font(.headline)
            }
            
            Divider()
            
            infoRow("WebSocket", "ws://localhost:18789")
            infoRow("Config", "~/.openclaw/openclaw.json")
            infoRow("Logs", "~/.openclaw/logs/")
            
            if let version = monitor.gatewayVersion {
                infoRow("Version", version)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.primary)
        }
        .font(.subheadline)
    }
    
    // MARK: - Logs View
    
    private var logsView: some View {
        VStack(spacing: 0) {
            // Log controls
            HStack {
                Picker("Log Level", selection: $monitor.logFilter) {
                    Text("All").tag(LogFilter.all)
                    Text("Info").tag(LogFilter.info)
                    Text("Warn").tag(LogFilter.warn)
                    Text("Error").tag(LogFilter.error)
                }
                .pickerStyle(.segmented)
                .frame(width: 250)
                
                Spacer()
                
                Button {
                    monitor.clearLogs()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help("Clear logs")
                
                Button {
                    Task { await monitor.refreshLogs() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Refresh")
                
                Toggle("Auto-scroll", isOn: $monitor.autoScroll)
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }
            .padding()
            
            Divider()
            
            // Log content
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(monitor.filteredLogs.enumerated()), id: \.offset) { index, line in
                            LogLine(line: line)
                                .id(index)
                        }
                    }
                    .padding(12)
                }
                .background(Color(red: 0.1, green: 0.1, blue: 0.12))
                .onChange(of: monitor.filteredLogs.count) { _, _ in
                    if monitor.autoScroll, let lastIndex = monitor.filteredLogs.indices.last {
                        withAnimation(.easeOut(duration: 0.1)) {
                            proxy.scrollTo(lastIndex, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Log path
            HStack {
                Text("~/.openclaw/logs/")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button("Open in Finder") {
                    let logPath = FileManager.default.homeDirectoryForCurrentUser
                        .appendingPathComponent(".openclaw/logs")
                    NSWorkspace.shared.open(logPath)
                }
                .font(.caption)
                .buttonStyle(.borderless)
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
        }
    }
    
    // MARK: - Stats View
    
    private var statsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Usage stats
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundStyle(.blue)
                        Text("Usage Statistics")
                            .font(.headline)
                    }
                    
                    Divider()
                    
                    HStack(spacing: 24) {
                        statItem("Total Sessions", "\(monitor.totalSessions)")
                        statItem("Messages Processed", "\(monitor.totalMessages)")
                        statItem("Avg Response Time", "\(monitor.avgResponseTime)ms")
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Channel stats
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .foregroundStyle(.purple)
                        Text("Channel Activity")
                            .font(.headline)
                    }
                    
                    Divider()
                    
                    channelStatRow("Telegram", monitor.telegramMessages, .blue)
                    channelStatRow("Discord", monitor.discordMessages, .purple)
                    channelStatRow("WhatsApp", monitor.whatsappMessages, .green)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // System resources
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "memorychip")
                            .foregroundStyle(.orange)
                        Text("System Resources")
                            .font(.headline)
                    }
                    
                    Divider()
                    
                    HStack(spacing: 24) {
                        statItem("Memory", monitor.memoryUsage)
                        statItem("CPU", monitor.cpuUsage)
                        statItem("Node.js", monitor.nodeVersion ?? "—")
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
    }
    
    private func statItem(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func channelStatRow(_ name: String, _ count: Int, _ color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(name)
            Spacer()
            Text("\(count) messages")
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack {
            // Auto-refresh toggle
            HStack(spacing: 8) {
                Toggle("Auto-refresh", isOn: $monitor.autoRefresh)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                
                if monitor.autoRefresh {
                    Text("every 5s")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Open config
            Button {
                let configPath = FileManager.default.homeDirectoryForCurrentUser
                    .appendingPathComponent(".openclaw/openclaw.json")
                NSWorkspace.shared.open(configPath)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "gearshape")
                    Text("Edit Config")
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }
}

// MARK: - Control Button

struct ControlButton: View {
    let title: String
    let icon: String
    let color: Color
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .frame(minWidth: 100)
        }
        .buttonStyle(.borderedProminent)
        .tint(color)
        .disabled(isLoading)
    }
}

// MARK: - Log Line

struct LogLine: View {
    let line: LogEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(line.timestamp)
                .foregroundStyle(.secondary)
            
            Text(line.level.rawValue.uppercased())
                .foregroundStyle(line.level.color)
                .frame(width: 50, alignment: .leading)
            
            Text(line.message)
                .foregroundStyle(.primary)
        }
        .font(.system(size: 11, design: .monospaced))
        .textSelection(.enabled)
    }
}

// MARK: - Log Types

enum LogFilter: String, CaseIterable {
    case all, info, warn, error
}

enum LogLevel: String {
    case info, warn, error, debug
    
    var color: Color {
        switch self {
        case .info: return .cyan
        case .warn: return .yellow
        case .error: return .red
        case .debug: return .gray
        }
    }
}

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: String
    let level: LogLevel
    let message: String
}

// MARK: - Gateway Monitor

@MainActor
class GatewayMonitor: ObservableObject {
    // Connection state
    @Published var isConnected: Bool = false
    @Published var isChecking: Bool = false
    @Published var isOperating: Bool = false
    @Published var lastCheckTime: Date?
    
    // Gateway info
    @Published var gatewayVersion: String?
    @Published var uptimeSeconds: Int = 0
    @Published var messagesToday: Int = 0
    @Published var activeConnections: Int = 0
    
    // Stats
    @Published var totalSessions: Int = 0
    @Published var totalMessages: Int = 0
    @Published var avgResponseTime: Int = 0
    @Published var telegramMessages: Int = 0
    @Published var discordMessages: Int = 0
    @Published var whatsappMessages: Int = 0
    @Published var memoryUsage: String = "—"
    @Published var cpuUsage: String = "—"
    @Published var nodeVersion: String?
    
    // Logs
    @Published var logs: [LogEntry] = []
    @Published var logFilter: LogFilter = .all
    @Published var autoScroll: Bool = true
    @Published var autoRefresh: Bool = true
    
    private var refreshTimer: Timer?
    private var uptimeTimer: Timer?
    
    var statusColor: Color {
        isConnected ? .green : .red
    }
    
    /// Only show "Checking..." on manual checks, not auto-refresh
    @Published var showCheckingIndicator: Bool = false

    var statusText: String {
        if showCheckingIndicator { return "Checking..." }
        return isConnected ? "Connected" : "Disconnected"
    }
    
    var formattedUptime: String {
        if uptimeSeconds == 0 { return "—" }
        let hours = uptimeSeconds / 3600
        let minutes = (uptimeSeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    var filteredLogs: [LogEntry] {
        switch logFilter {
        case .all: return logs
        case .info: return logs.filter { $0.level == .info }
        case .warn: return logs.filter { $0.level == .warn }
        case .error: return logs.filter { $0.level == .error }
        }
    }
    
    func startMonitoring() {
        Task { await checkStatus() }
        Task { await refreshLogs() }
        
        // Auto-refresh timer (silent — no "Checking..." badge flicker)
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self, self.autoRefresh else { return }
            Task { @MainActor in
                await self.checkStatus(silent: true)
            }
        }
        
        // Uptime counter
        uptimeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                if self?.isConnected == true {
                    self?.uptimeSeconds += 1
                }
            }
        }
    }
    
    func stopMonitoring() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        uptimeTimer?.invalidate()
        uptimeTimer = nil
    }
    
    func checkStatus(silent: Bool = false) async {
        // Avoid overlapping checks
        guard !isChecking else { return }
        isChecking = true
        if !silent { showCheckingIndicator = true }
        defer {
            isChecking = false
            showCheckingIndicator = false
        }

        // Check WebSocket endpoint
        let result = await ShellRunner.run("curl -s -o /dev/null -w '%{http_code}' --connect-timeout 2 http://localhost:18789/health 2>/dev/null || echo '000'")
        let statusCode = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)

        let wasConnected = isConnected
        isConnected = statusCode == "200"
        lastCheckTime = Date()

        if isConnected {
            // Only fetch full info on first connect or manual check
            if !wasConnected || !silent {
                await fetchGatewayInfo()
            }
        } else {
            uptimeSeconds = 0
            messagesToday = 0
            activeConnections = 0
        }
    }
    
    private func fetchGatewayInfo() async {
        // Get gateway status
        let statusResult = await ShellRunner.run("openclaw status --json 2>/dev/null")
        if statusResult.success, let data = statusResult.stdout.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let uptime = json["uptime"] as? Int {
                uptimeSeconds = uptime
            }
            if let messages = json["messagesToday"] as? Int {
                messagesToday = messages
            }
            if let connections = json["connections"] as? Int {
                activeConnections = connections
            }
            if let version = json["version"] as? String {
                gatewayVersion = version
            }
        }
        
        // Get node version
        let nodeResult = await ShellRunner.run("node --version 2>/dev/null")
        if nodeResult.success {
            nodeVersion = nodeResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    func startGateway() async {
        isOperating = true
        defer { isOperating = false }
        
        appendLog(.info, "Starting gateway...")
        
        let result = await ShellRunner.run("openclaw gateway start 2>&1")
        
        if result.success {
            appendLog(.info, "Gateway started successfully")
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await checkStatus()
        } else {
            appendLog(.error, "Failed to start: \(result.stderr)")
        }
    }
    
    func stopGateway() async {
        isOperating = true
        defer { isOperating = false }
        
        appendLog(.info, "Stopping gateway...")
        
        let result = await ShellRunner.run("openclaw gateway stop 2>&1")
        
        if result.success {
            appendLog(.info, "Gateway stopped")
            isConnected = false
            uptimeSeconds = 0
        } else {
            appendLog(.error, "Failed to stop: \(result.stderr)")
        }
    }
    
    func restartGateway() async {
        isOperating = true
        defer { isOperating = false }
        
        appendLog(.info, "Restarting gateway...")
        
        let result = await ShellRunner.run("openclaw gateway restart 2>&1")
        
        if result.success {
            appendLog(.info, "Gateway restarted")
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await checkStatus()
        } else {
            appendLog(.error, "Failed to restart: \(result.stderr)")
        }
    }
    
    func refreshLogs() async {
        let logPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".openclaw/logs/gateway.log")
        
        // Read last 100 lines
        let result = await ShellRunner.run("tail -100 '\(logPath.path)' 2>/dev/null")
        
        if result.success {
            let lines = result.stdout.components(separatedBy: "\n")
            logs = lines.compactMap { parseLogLine($0) }
        }
    }
    
    func clearLogs() {
        logs = []
    }
    
    private func parseLogLine(_ line: String) -> LogEntry? {
        guard !line.isEmpty else { return nil }
        
        // Parse format: [timestamp] [level] message
        // Example: [2026-03-05 10:30:45] [INFO] Gateway started
        
        var timestamp = ""
        var level: LogLevel = .info
        var message = line
        
        if line.hasPrefix("[") {
            if let endBracket = line.firstIndex(of: "]") {
                timestamp = String(line[line.index(after: line.startIndex)..<endBracket])
                let remaining = String(line[line.index(after: endBracket)...]).trimmingCharacters(in: .whitespaces)
                
                if remaining.hasPrefix("[") {
                    if let levelEnd = remaining.dropFirst().firstIndex(of: "]") {
                        let levelStr = String(remaining[remaining.index(after: remaining.startIndex)..<levelEnd]).lowercased()
                        level = LogLevel(rawValue: levelStr) ?? .info
                        message = String(remaining[remaining.index(after: levelEnd)...]).trimmingCharacters(in: .whitespaces)
                    }
                } else {
                    message = remaining
                }
            }
        }
        
        // Fallback timestamp
        if timestamp.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            timestamp = formatter.string(from: Date())
        }
        
        return LogEntry(timestamp: timestamp, level: level, message: message)
    }
    
    private func appendLog(_ level: LogLevel, _ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let entry = LogEntry(
            timestamp: formatter.string(from: Date()),
            level: level,
            message: message
        )
        logs.append(entry)
    }
}
