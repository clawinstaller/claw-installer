# ClawInstaller

> Community-driven macOS setup wizard for [OpenClaw](https://github.com/openclaw/openclaw) — from 30 min CLI setup to 3 min visual wizard.

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue.svg)](https://www.apple.com/macos)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Independent community project, built for the OpenClaw ecosystem.**

[繁體中文](README.zh-TW.md)

---

## Why

OpenClaw has 257K+ stars but a steep setup curve. Analyzing [GitHub issues](https://github.com/openclaw/openclaw/issues):

- ~35% of new user issues = wrong Node version, missing native deps (Sharp, CMake)
- ~25% = config file confusion (JSON syntax, channel setup)
- ~15% = "it installed but won't start" (daemon, port conflicts)

ClawInstaller automates the painful first 5 minutes — the part where most people give up.

## Features

| Module | Status | What it does |
|--------|--------|-------------|
| **Preflight Check** | Done | Detects Node.js >=22, package managers, arch, disk. One-click fix. |
| **Install Wizard** | WIP | One-click install via npm/pnpm/bun with live progress |
| **Channel Setup** | Done | Guided wizards for Telegram, Discord, WhatsApp |
| **Health Monitor** | Planned | Gateway status, daemon start/stop, log viewer |
| **AI Support** | Planned | Claude-powered setup Q&A (BYOK — bring your own key) |

## Quick Start

```bash
git clone https://github.com/clawinstaller/claw-installer.git
cd claw-installer
swift build
swift run ClawInstaller
```

**Requirements:** macOS 14+ (Sonoma), Xcode 15+ or Swift 6.0 toolchain

## How it works

```
1. Preflight ──> detect Node, npm/pnpm/bun, architecture, disk
                  found issues? one-click fix suggestions
                          |
2. Install ───> pick best package manager, run install, verify
                          |
3. Channels ──> step-by-step Telegram/Discord/WhatsApp setup
                          |
4. Monitor ───> gateway health check, daemon controls
                          |
5. AI Support ─> Claude Q&A with full install context (premium)
```

## Pricing

| Tier | What you get | Cost |
|------|-------------|------|
| **Free** | Preflight + Install + Channels + Monitor | $0 |
| **AI Support** | Claude-powered setup assistant | BYOK (your own API key) |

## MCP Integration

Includes a TypeScript MCP server for tracking OpenClaw GitHub issues:

```bash
cd mcp && npm install && npm run build
```

4 tools: `issues_search`, `issues_analyze`, `issues_read`, `issues_report`

Used for data-driven feature prioritization — analyzing which installation pain points to fix first.

## Project Structure

```
claw-installer/
├── Package.swift                     # Swift Package Manager
├── Sources/ClawInstaller/
│   ├── ClawInstaller.swift           # App entry + NavigationSplitView
│   ├── AppState.swift                # Shared state
│   ├── ShellRunner.swift             # Shell command execution
│   ├── PreflightChecker.swift        # Module 1: system checks
│   ├── PreflightView.swift           # Module 1: UI
│   ├── PlaceholderViews.swift        # Module 4/5 placeholders
│   ├── Views/
│   │   ├── InstallWizardView.swift   # Module 2
│   │   ├── ChannelSetupView.swift    # Module 3
│   │   ├── TelegramSetupView.swift
│   │   ├── DiscordSetupView.swift
│   │   └── WhatsAppSetupView.swift
│   ├── Models/
│   │   └── ConfigManager.swift       # ~/.openclaw/openclaw.json
│   └── Services/
│       ├── ClaudeService.swift       # AI support (Module 5)
│       └── KnowledgeBase.swift       # Docs + issue context
├── mcp/                              # GitHub Issues Tracker MCP
│   └── src/
│       ├── index.ts                  # MCP server + 4 tools
│       ├── gh-runner.ts              # gh CLI bridge
│       ├── categorizer.ts            # Issue classifier
│       └── cache.ts                  # JSONL complaint store
└── docs/community-posts/             # PMF validation drafts
```

## Roadmap

- [x] Module 1: Preflight Check
- [x] Module 3: Channel Setup (Telegram, Discord, WhatsApp)
- [x] MCP: GitHub Issues Tracker
- [ ] Module 2: Install Wizard (in progress)
- [ ] Module 4: Health Monitor
- [ ] Module 5: AI Support (BYOK)
- [ ] Homebrew Cask formula
- [ ] Demo GIF / video
- [ ] Pain Point Report from issue data

## Contributing

Early stage — all contributions welcome:

1. **Test it** on your Mac, report issues
2. **Share pain points** about OpenClaw setup
3. **PRs welcome** — see [open issues](https://github.com/clawinstaller/claw-installer/issues)

## License

[MIT](LICENSE)

---

Built by [@howardpen9](https://github.com/howardpen9) with help from OpenClaw agents (Friday, Shuri, Muse).
