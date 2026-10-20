#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$ROOT/CodexVisual.app"
[[ -d "$SOURCE" ]] || SOURCE="$ROOT/build/CodexVisual.app"
[[ -d "$SOURCE" ]] || { echo 'Build first: bash scripts/build_app.sh'; exit 1; }
codesign --verify --deep --strict "$SOURCE"
INSTALL_DIR="$HOME/Applications"
APP="$INSTALL_DIR/CodexVisual.app"
AGENT="$HOME/Library/LaunchAgents/com.orangeshushu.CodexVisual.plist"
mkdir -p "$INSTALL_DIR" "$HOME/Library/LaunchAgents"
launchctl bootout "gui/$(id -u)" "$AGENT" 2>/dev/null || true
osascript -e 'tell application id "com.orangeshushu.CodexVisual" to quit' 2>/dev/null || true
for previous in "$APP" /Applications/CodexVisual.app; do
  if [[ -d "$previous" ]]; then
    mkdir -p "$INSTALL_DIR/CodexVisual-backups"
    BACKUP="$(mktemp -d "$INSTALL_DIR/CodexVisual-backups/$(date +%Y%m%d-%H%M%S)-XXXXXX")"
    mv "$previous" "$BACKUP/CodexVisual.app"
  fi
done
ditto --norsrc --noextattr "$SOURCE" "$APP"
defaults write com.orangeshushu.CodexVisual refreshMode -string everySixtySeconds
defaults write com.orangeshushu.CodexVisual menuBarDisplayMode -string bars
cat > "$AGENT" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Label</key><string>com.orangeshushu.CodexVisual</string>
<key>RunAtLoad</key><true/>
<key>ProgramArguments</key><array><string>PLACEHOLDER</string></array>
</dict></plist>
PLIST
/usr/libexec/PlistBuddy -c "Set :ProgramArguments:0 $APP/Contents/MacOS/CodexVisual" "$AGENT"
plutil -lint "$AGENT"
launchctl bootstrap "gui/$(id -u)" "$AGENT"
echo 'Installed / 已安装 / インストール完了 — ~/Applications/CodexVisual.app'
