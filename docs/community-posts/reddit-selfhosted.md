# Reddit Post: r/selfhosted

**Subreddit:** r/selfhosted  
**Title:** I built a macOS GUI installer for OpenClaw because the CLI setup was driving me crazy

---

## Post Content

**TL;DR:** After helping friends set up OpenClaw and watching them struggle with the same issues I did, I built a native macOS app to automate the painful parts. Looking for feedback before I polish it further.

---

### The Problem

I love OpenClaw (AI assistant that runs locally, connects to Telegram/Discord/WhatsApp). But the setup experience... less so.

**My personal pain points were:**
1. "Do I have the right Node version?" → `nvm install 22`, wait, which shell config do I edit again?
2. "Where does the config file go?" → `~/.openclaw/openclaw.json`, but the example config has outdated fields
3. "Why isn't it responding?" → Forgot to start the daemon. Or port 18789 is in use. Or the config has a typo.

When I helped 3 friends set it up, all 3 hit the same walls. Average time to working setup: **30-45 minutes**.

---

### The Solution: ClawInstaller

A native SwiftUI app that does the annoying parts for you:

```
┌────────────────────────────────────────────────────────┐
│                     CLI Setup                          │
├────────────────────────────────────────────────────────┤
│                                                        │
│  $ node --version                                      │
│  v18.17.0   ← wrong version, need 22+                 │
│                                                        │
│  $ nvm install 22                                      │
│  $ nvm use 22                                          │
│  $ npm install -g openclaw                             │
│  npm WARN deprecated...                                │
│  (wait 2 minutes)                                      │
│                                                        │
│  $ nano ~/.openclaw/openclaw.json                      │
│  (copy-paste from docs, fix JSON syntax errors)        │
│                                                        │
│  $ openclaw gateway start                              │
│  Error: EADDRINUSE :::18789                           │
│  (debug for 10 minutes)                               │
│                                                        │
│  Total time: 30-45 min                                │
│                                                        │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│                   ClawInstaller                        │
├────────────────────────────────────────────────────────┤
│                                                        │
│  [Preflight]                                          │
│  ✅ Node.js 22.3.0                                    │
│  ✅ npm detected                                       │
│  ✅ 15 GB free                                        │
│                                                        │
│        ┌──────────────────────┐                       │
│        │   Install OpenClaw   │                       │
│        └──────────────────────┘                       │
│                                                        │
│  [Channel Setup Wizard]                               │
│  → Telegram: Paste BotFather token                    │
│  → Discord: OAuth flow with permissions              │
│  → WhatsApp: QR code scanner built-in                │
│                                                        │
│  [Health Monitor]                                     │
│  ● Gateway running on :18789                          │
│  [Stop] [Restart] [View Logs]                         │
│                                                        │
│  Total time: ~3 min                                   │
│                                                        │
└────────────────────────────────────────────────────────┘
```

---

### What's working

- **Preflight checks:** Detects Node version, package managers (npm/pnpm/bun), disk space, architecture
- **Channel wizards:** Step-by-step setup for Telegram, Discord, WhatsApp with validation
- **Config generation:** Writes valid `openclaw.json` so you never touch JSON manually
- **Health monitor:** Shows daemon status, start/stop buttons, log viewer

### What's not done yet

- The actual "Install" button (ironic, I know) — currently just detects environment
- AI support panel (Claude integration for troubleshooting)
- Windows/Linux versions

---

### Why native macOS?

1. **Keychain integration** — API keys stored securely, not in plaintext
2. **LaunchAgent support** — Start on boot without cron hacks
3. **System notifications** — Get notified when your agent needs attention

---

### Questions for you

1. Is this useful, or is the CLI fine for the r/selfhosted crowd?
2. Would you trust a GUI app to manage daemon lifecycles?
3. Any features you'd want that I'm missing?
4. Should I prioritize Windows/Linux or go deep on macOS first?

Happy to open-source this if there's interest. Just want to validate before I sink more weekends into it.

---

**Screenshots:** [coming soon — need to polish the UI first]

**Stack:** SwiftUI, running on macOS 14+ (Sonoma). Apple Silicon native, Rosetta works for Intel.
