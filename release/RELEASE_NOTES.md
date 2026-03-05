# ClawInstaller v0.2.0-beta

> macOS 原生 OpenClaw 安裝精靈 — V2 全新介面

## v0.2.0 更新內容

### 全新 V2 介面

- **全面 UI 重設計** — 所有頁面重新設計，明亮主題、更清爽的視覺體驗
- **精靈模式 / 控制台模式分離** — 安裝流程為單頁精靈（760x540），完成後控制台自動放大（960x640）
- **App Logo** — 正確載入 ClawInstaller 品牌 Logo（修復 SPM Bundle.module 資源載入）
- **Agent 角色卡片** — Welcome 頁面展示三位 AI Agent：阿貓、土豆、小可愛
- **安裝完成頁面** — 全新慶祝畫面：安裝統計、QR Code 社群分享、快速開始引導
- **強制亮色模式** — 不再跟隨系統深色模式

### 自有文件站

- **繁體中文文件站上線** — [clawinstaller.github.io/website](https://clawinstaller.github.io/website/)
- **7 頁內容**：快速開始、安裝流程、Agent 介紹、頻道設定、系統監控、FAQ
- **App 連結更新** — 「閱讀文件」和「查看新手教學」改指向自家文件站

### 控制台優化

- **視窗自動放大** — 進入控制台後視窗從 760x540 → 960x640
- **Sidebar 不截斷** — 設定最小寬度 180px，文字完整顯示

### CI 修復

- **Resource Bundle 打包** — CI build 現在正確複製 SPM resource bundle 到 .app，Logo 在 DMG 版本也能正常顯示

## 功能模組

| 模組 | 狀態 | 說明 |
|------|------|------|
| 環境檢測 | ✅ 完成 | 自動偵測 Node.js、系統架構、套件管理器，一鍵修復 |
| 安裝精靈 | ✅ 完成 | 一鍵安裝 OpenClaw，即時終端機輸出、進度條 |
| 頻道設定 | ✅ 完成 | Telegram、Discord、WhatsApp 設定指引 |
| LLM 設定 | ✅ 完成 | 選擇 AI 供應商，自動驗證 API Key |
| AI 助手 | ✅ 完成 | 內建繁中 AI 助手，自動帶入系統狀態 |
| 健康監控 | ✅ 完成 | Gateway 狀態、控制按鈕、自動刷新 |
| 文件站 | ✅ 新增 | 繁體中文新手教學 + FAQ |

## 安裝方式

### 直接下載

1. 下載下方的 `ClawInstaller-0.2.0-beta-macos.dmg`
2. 打開 DMG，將 ClawInstaller 拖入「應用程式」資料夾
3. 首次開啟：右鍵 → 打開（繞過 macOS 安全提示）
4. 如果看到「ClawInstaller 已損壞」，請在終端機執行：
   ```bash
   xattr -cr /Applications/ClawInstaller.app
   ```

> 正式版將加入 Apple 公證簽名，屆時雙擊就能直接開啟。

## 系統需求

- macOS 14.0（Sonoma）或更新版本
- Apple Silicon 或 Intel Mac
- 約 100MB 磁碟空間

## 已知問題

- 尚未加入 Apple 公證簽名，首次開啟需手動允許
- WhatsApp QR 掃描需要 Gateway 先啟動

## 回饋與社群

發現 Bug？[開 Issue 回報](https://github.com/clawinstaller/claw-installer/issues/new)

文件站：[clawinstaller.github.io/website](https://clawinstaller.github.io/website/)
Threads：[@0xhoward_peng](https://www.threads.com/@0xhoward_peng)
