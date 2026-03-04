# Changelog

All notable changes to ClawInstaller will be documented in this file.

## [0.1.0-beta] - 2026-03-04

### 🎉 Initial Beta Release

First public beta of ClawInstaller — a community-driven macOS setup wizard for OpenClaw.

### ✨ Features

#### Module 1: Preflight Check
- Detects Node.js version (requires ≥22)
- Identifies available package managers (npm, pnpm, bun, yarn)
- Checks system architecture (Apple Silicon / Intel)
- Verifies existing OpenClaw installation
- Shows disk space availability
- One-click fix actions for common issues

#### Module 2: Install Wizard
- One-click OpenClaw installation
- Automatic package manager detection (prefers pnpm > bun > npm)
- Live terminal output streaming
- Progress tracking with visual stages
- Automatic rollback on failure
- Installation verification

#### Module 3: Channel Setup
- Guided Telegram bot setup with BotFather walkthrough
- Discord bot configuration with Developer Portal guide
- WhatsApp Web linking instructions
- Auto-writes configuration to `~/.openclaw/openclaw.json`
- Visual step-by-step instructions

#### Module 4: Health Monitor (Preview)
- Gateway status display
- Coming: Start/stop/restart controls
- Coming: Log viewer

#### Module 5: AI Support (Preview)
- Embedded chat interface
- Coming: Claude-powered troubleshooting
- Coming: Knowledge base from docs + GitHub issues

### 🔧 Technical

- Built with Swift 6.0 and SwiftUI
- Requires macOS 14.0 (Sonoma) or later
- Native Apple Silicon support
- Dark mode compatible

### 📦 Installation

```bash
# Via Homebrew (recommended)
brew install --cask openclaw/tap/claw-installer

# Or download directly from GitHub Releases
```

### 🐛 Known Issues

- DMG creation requires `create-dmg` (optional)
- AI Support module requires ANTHROPIC_API_KEY environment variable
- WhatsApp QR code scanning requires Gateway to be running

### 🙏 Contributors

- @howardpen9 + OpenClaw agents (Friday, Shuri, Muse)

---

[0.1.0-beta]: https://github.com/clawinstaller/claw-installer/releases/tag/v0.1.0-beta
