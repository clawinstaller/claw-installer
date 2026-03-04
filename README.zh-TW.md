# ClawInstaller

> 社群驅動的 macOS 安裝精靈 — 讓 [OpenClaw](https://github.com/openclaw/openclaw) 設定從 30 分鐘縮短到 3 分鐘。

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue.svg)](https://www.apple.com/macos)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**非官方專案，與 OpenClaw 團隊無關。**

[English](README.md)

---

## 為什麼需要這個

OpenClaw 有 257K+ stars，但安裝門檻高。分析 [GitHub Issues](https://github.com/openclaw/openclaw/issues) 發現：

- ~35% 新用戶問題 = Node 版本錯誤、原生模組缺失 (Sharp, CMake)
- ~25% = 設定檔困惑 (JSON 語法、channel 設定)
- ~15% = 「裝好了但跑不起來」(daemon、port 衝突)

ClawInstaller 自動化最痛苦的前 5 分鐘 — 大多數人放棄的那個階段。

## 功能

| 模組 | 狀態 | 說明 |
|------|------|------|
| **環境檢查** | 完成 | 偵測 Node.js >=22、套件管理器、架構、磁碟空間。一鍵修復。 |
| **安裝精靈** | 開發中 | 透過 npm/pnpm/bun 一鍵安裝，即時進度顯示 |
| **頻道設定** | 完成 | Telegram、Discord、WhatsApp 逐步引導設定 |
| **健康監控** | 規劃中 | Gateway 狀態、daemon 啟停、日誌檢視 |
| **AI 助手** | 規劃中 | Claude 驅動的設定問答（BYOK — 自帶 API key） |

## 快速開始

```bash
git clone https://github.com/clawinstaller/claw-installer.git
cd claw-installer
swift build
swift run ClawInstaller
```

**需求：** macOS 14+ (Sonoma)、Xcode 15+ 或 Swift 6.0 工具鏈

## 運作流程

```
1. 環境檢查 ──> 偵測 Node、npm/pnpm/bun、架構、磁碟
                  發現問題？一鍵修復建議
                          |
2. 安裝 ──────> 選擇最佳套件管理器，執行安裝，驗證
                          |
3. 頻道設定 ──> Telegram/Discord/WhatsApp 逐步引導
                          |
4. 健康監控 ──> Gateway 狀態檢查、daemon 控制
                          |
5. AI 助手 ───> 帶入完整安裝上下文的 Claude 問答（付費）
```

## 定價

| 層級 | 功能 | 費用 |
|------|------|------|
| **免費** | 環境檢查 + 安裝 + 頻道設定 + 健康監控 | $0 |
| **AI 助手** | Claude 驅動的設定助理 | BYOK（自帶 API key） |

## MCP 整合

內建 TypeScript MCP server，追蹤 OpenClaw GitHub issues：

```bash
cd mcp && npm install && npm run build
```

4 個工具：`issues_search`、`issues_analyze`、`issues_read`、`issues_report`

用於數據驅動的功能優先排序 — 分析哪些安裝痛點該優先修復。

## 路線圖

- [x] 模組 1：環境檢查
- [x] 模組 3：頻道設定 (Telegram, Discord, WhatsApp)
- [x] MCP：GitHub Issues 追蹤器
- [ ] 模組 2：安裝精靈（開發中）
- [ ] 模組 4：健康監控
- [ ] 模組 5：AI 助手（BYOK）
- [ ] Homebrew Cask formula
- [ ] Demo GIF / 影片
- [ ] 痛點分析報告

## 貢獻

早期階段，歡迎所有貢獻：

1. **測試** — 在你的 Mac 上跑跑看，回報問題
2. **分享痛點** — OpenClaw 設定過程中什麼最讓你頭痛？
3. **歡迎 PR** — 看看 [open issues](https://github.com/clawinstaller/claw-installer/issues)

## 授權

[MIT](LICENSE)

---

由 [@howardpen9](https://github.com/howardpen9) 搭配 OpenClaw agents（Friday、Shuri、Muse）共同打造。
