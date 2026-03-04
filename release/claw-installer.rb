# Homebrew Cask formula for ClawInstaller
# Install: brew install --cask openclaw/tap/claw-installer

cask "claw-installer" do
  version "0.1.0-beta"
  sha256 "86e88e603cd7935af3fcaa2f25d9df20bea628b68dfb0f9c10814ae0ee1b976d"

  url "https://github.com/clawinstaller/claw-installer/releases/download/v#{version}/ClawInstaller-#{version}-macos.zip"
  name "ClawInstaller"
  desc "One-click installer and setup wizard for OpenClaw AI assistant"
  homepage "https://github.com/clawinstaller/claw-installer"

  depends_on macos: ">= :sonoma"

  app "ClawInstaller.app"

  zap trash: [
    "~/.openclaw",
    "~/Library/Application Support/ClawInstaller",
    "~/Library/Caches/ai.openclaw.installer",
    "~/Library/Preferences/ai.openclaw.installer.plist",
  ]

  caveats <<~EOS
    ClawInstaller helps you set up OpenClaw AI assistant.
    
    After installation:
    1. Open ClawInstaller from Applications
    2. Follow the setup wizard
    3. Configure your preferred channels (Telegram, Discord, WhatsApp)
    
    For more information, visit:
      https://docs.openclaw.ai
  EOS
end
