#!/bin/bash
# 넥슨 플러그를 올바른 옵션으로 켜 주는 Mac 앱을 만들어요.
# CrossOver에서 NexonPlug.exe를 그냥 실행하면 창이 검게 나와서, 이 앱으로 실행해야 해요.
#
# 사용법:
#   ./scripts/make-launcher-app.sh                          # ~/Applications/넥슨플러그 (CrossOver).app
#   BOTTLE="내 보틀" ./scripts/make-launcher-app.sh [앱 경로]
set -euo pipefail

BOTTLE="${BOTTLE:-Azur Promilia}"
APP="${1:-$HOME/Applications/넥슨플러그 (CrossOver).app}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$SCRIPT_DIR/../launcher/NexonPlugLauncher.applescript"
PB=/usr/libexec/PlistBuddy

case "$BOTTLE" in
  *'"'* | *'\'* | *'&'* | *'|'*) echo "오류: 보틀 이름에 \" \\ & | 문자는 쓸 수 없어요." >&2; exit 1 ;;
esac

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
sed "s|__BOTTLE__|$BOTTLE|" "$SRC" > "$TMP/launcher.applescript"

mkdir -p "$(dirname "$APP")"
rm -rf "$APP"
osacompile -o "$APP" "$TMP/launcher.applescript" 2>"$TMP/osacompile.err" \
  || { cat "$TMP/osacompile.err" >&2; exit 1; }
"$PB" -c "Set :CFBundleIdentifier local.crossover.nexonplug-launcher" "$APP/Contents/Info.plist" 2>/dev/null \
  || "$PB" -c "Add :CFBundleIdentifier string local.crossover.nexonplug-launcher" "$APP/Contents/Info.plist"
"$PB" -c "Add :LSUIElement bool true" "$APP/Contents/Info.plist" 2>/dev/null || true
codesign --force --sign - "$APP" 2>/dev/null

echo "만들었어요: $APP"
echo "이 앱을 더블클릭하면 보틀 '$BOTTLE'에서 넥슨 플러그가 켜져요."
