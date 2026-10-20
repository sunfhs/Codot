#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT/Resources/Info.plist")
ARCH="$(uname -m)"
[[ "$ARCH" != x86_64 ]] || ARCH=x64
NAME="codex-usage-compact-v$VERSION-macos-$ARCH"
BUNDLE="$ROOT/build/$NAME"
mkdir -p "$BUNDLE/scripts" "$BUNDLE/Resources"
ditto "$ROOT/build/CodexVisual.app" "$BUNDLE/CodexVisual.app"
cp "$ROOT/scripts/install.command" "$BUNDLE/scripts/install.command"
# Keep the double-click entry at the package root; it resolves its resources in place.
printf '#!/bin/bash\ncd "$(dirname "$0")"\nexec bash scripts/install.command\n' > "$BUNDLE/Install.command"
chmod +x "$BUNDLE/Install.command" "$BUNDLE/scripts/install.command"
cp "$ROOT/Resources/com.orangeshushu.CodexVisual.plist" "$BUNDLE/Resources/"
cp "$ROOT/../README.md" "$ROOT/../README.en.md" "$ROOT/../README.ja.md" "$ROOT/../NOTICE.md" "$BUNDLE/"
ditto -c -k --sequesterRsrc --keepParent "$BUNDLE" "$ROOT/build/$NAME.zip"
(cd "$ROOT/build" && shasum -a 256 "$NAME.zip" > "$NAME.zip.sha256")
