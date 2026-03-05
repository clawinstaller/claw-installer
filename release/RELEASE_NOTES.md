# ClawInstaller v0.1.0-beta

> macOS-native setup wizard for OpenClaw — with built-in AI assistant

## What's New

First public beta of ClawInstaller. Install OpenClaw, configure channels, and get AI-powered troubleshooting — all in one native app.

### Modules

| Module | Status | Description |
|--------|--------|-------------|
| Preflight Check | Complete | Auto-detects Node.js, arch, package managers. Fix buttons for common issues. |
| Install Wizard | Complete | One-click install with real-time progress, error detection, auto-fix. |
| Channel Setup | Complete | Step-by-step guides for Telegram, Discord, WhatsApp. |
| LLM Setup | Complete | Choose AI provider (Anthropic, Google, Ollama) with key validation. |
| AI Support | Complete | Chat with pre-tuned AI assistant. Context-aware, Traditional Chinese. |
| Health Monitor | Preview | Gateway status display. Full controls coming soon. |

### Key Features

- **Smart Error Guidance** — When things fail, tap "Ask AI Assistant" to get help with full system context
- **Fresh Mac Support** — Guides users through Node.js installation even on brand new Macs
- **Zero Config AI** — Built-in AI assistant works immediately, no API key needed
- **Dynamic PATH Detection** — Supports nvm, fnm, volta, asdf, Homebrew (Apple Silicon + Intel)

## Installation

### Direct Download

1. Download `ClawInstaller-0.1.0-beta-macos.dmg` below
2. Open DMG, drag ClawInstaller to Applications
3. Right-click > Open (first time only, to bypass Gatekeeper)

### Homebrew

```bash
brew tap clawinstaller/tap
brew install --cask claw-installer
```

## System Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon or Intel Mac
- ~100MB disk space

## Quick Start

1. **Preflight Check** — Verify your system is ready
2. **Install OpenClaw** — One-click installation
3. **Configure Channels** — Set up Telegram, Discord, or WhatsApp
4. **Set Up LLM** — Choose your AI provider
5. **Ask AI** — Get help anytime via the AI Support tab

## Known Issues

- App is unsigned (Gatekeeper will prompt on first launch)
- Health Monitor is preview only (full controls in next release)
- WhatsApp QR scanning requires Gateway to be running

## Feedback

Found a bug? [Open an issue](https://github.com/clawinstaller/claw-installer/issues/new)

Telegram Group: [ClawInstaller Community](https://t.me/clawinstaller)
Threads: [@0xhoward_peng](https://www.threads.com/@0xhoward_peng)
