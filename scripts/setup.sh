#!/bin/bash
# 넥슨 플러그와 NGM(넥슨 게임 매니저)을 CrossOver 보틀에 설치하고 Wine 호환 설정을 적용해요.
# 넥슨 파일은 이 저장소에 없고, 실행할 때 넥슨 공식 서버(platform.nexon.com)에서 받아요.
#
# 사용법:
#   ./scripts/setup.sh                       # 보틀 이름이 "Azur Promilia"일 때
#   BOTTLE="내 보틀" ./scripts/setup.sh       # 다른 이름일 때
#
# 이미 받아 둔 파일을 쓰려면 (선택):
#   PLUG_ZIP=/path/65538.z00  NGM_SRC=/path/folder-with-NGM.exe-NGM64.exe-SIG.exe
set -euo pipefail

BOTTLE="${BOTTLE:-Azur Promilia}"
CX_BIN="${CX_BIN:-/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DRIVE_C="$HOME/Library/Application Support/CrossOver/Bottles/$BOTTLE/drive_c"

PLUG_URL="https://platform.nexon.com/NexonPlug/Install/InstallData/65538.z00"
NGM_URL="https://platform.nexon.com/NGM/Bin"
UA="Mozilla/5.0"
# Wine에서는 Chromium 계열 화면의 GPU 렌더링이 검은 화면이 돼서 소프트웨어 렌더링을 써요.
GL_FLAGS="--use-gl=swiftshader --use-angle=swiftshader --in-process-gpu"

say()  { printf '\n==> %s\n' "$*"; }
warn() { printf '주의: %s\n' "$*" >&2; }
die()  { printf '오류: %s\n' "$*" >&2; exit 1; }
bwine() { "$CX_BIN/wine" --bottle "$BOTTLE" "$@"; }
reg_add() { bwine reg add "$@" /f >/dev/null 2>&1 || die "레지스트리 설정 실패: $*"; }

[ -x "$CX_BIN/wine" ] || die "CrossOver를 찾을 수 없어요: $CX_BIN"
[ -d "$DRIVE_C" ] || die "보틀 '$BOTTLE'이 없어요. CrossOver에서 먼저 만들어 주세요 (README 1단계)."
command -v python3 >/dev/null || die "python3가 필요해요. 터미널에서 xcode-select --install 을 실행해 주세요."
if bwine tasklist 2>/dev/null | grep -qiE '^(NexonPlug|NGM64|NGM)\.exe'; then
  die "보틀 안에서 넥슨 플러그나 NGM이 실행 중이에요. 먼저 종료해 주세요."
fi
if [ ! -d "$DRIVE_C/Program Files (x86)/Microsoft/EdgeWebView/Application" ]; then
  warn "WebView2 런타임이 보이지 않아요. NGM 화면에 필요해요 (README 2단계)."
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

say "1/4 넥슨 플러그 설치"
if [ -n "${PLUG_ZIP:-}" ]; then
  cp "$PLUG_ZIP" "$TMP/nexonplug.zip"
else
  echo "공식 서버에서 받는 중 (약 180MB): $PLUG_URL"
  curl -fL --retry 3 -A "$UA" -o "$TMP/nexonplug.zip" "$PLUG_URL"
fi
mkdir -p "$DRIVE_C/Nexon/NexonPlug"
python3 -I "$SCRIPT_DIR/extract_zip.py" "$TMP/nexonplug.zip" "$DRIVE_C/Nexon/NexonPlug"
reg_add 'HKLM\Software\Nexon\NexonPlug' /v RootPath /t REG_SZ /d 'C:\Nexon\NexonPlug'
reg_add 'HKLM\Software\Nexon\NexonPlug' /v Executable /t REG_SZ /d 'C:\Nexon\NexonPlug\NexonPlug.exe'
UNINSTALL='HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\NexonPlug'
reg_add "$UNINSTALL" /v DisplayName /t REG_SZ /d 'NexonPlug'
reg_add "$UNINSTALL" /v InstallLocation /t REG_SZ /d 'C:\Nexon\NexonPlug'
reg_add "$UNINSTALL" /v Publisher /t REG_SZ /d 'NEXON Korea Corp.'

say "2/4 NGM(넥슨 게임 매니저) 설치"
# NGM이 없으면 게임 설치/실행 버튼에서 "게임 실행에 실패했습니다"가 떠요.
NGM_DIR="$DRIVE_C/ProgramData/Nexon/NGM"
mkdir -p "$NGM_DIR"
for f in NGM.exe NGM64.exe SIG.exe; do
  if [ -n "${NGM_SRC:-}" ]; then
    cp "$NGM_SRC/$f" "$TMP/$f"
  else
    curl -fL --retry 3 -A "$UA" -o "$TMP/$f" "$NGM_URL/$f"
  fi
  cp "$TMP/$f" "$NGM_DIR/$f"
done
for e in NGM.exe NGM64.exe; do
  reg_add 'HKLM\Software\Microsoft\Internet Explorer\MAIN\FeatureControl\FEATURE_BROWSER_EMULATION' /v "$e" /t REG_DWORD /d 11001
  reg_add 'HKLM\Software\Wow6432Node\Microsoft\Internet Explorer\MAIN\FeatureControl\FEATURE_BROWSER_EMULATION' /v "$e" /t REG_DWORD /d 11001
done

say "3/4 NGM 검은 화면 방지 (WebView2 소프트웨어 렌더링)"
for root in HKCU HKLM; do
  for e in NGM.exe NGM64.exe; do
    reg_add "$root\\Software\\Policies\\Microsoft\\Edge\\WebView2\\AdditionalBrowserArguments" /v "$e" /t REG_SZ /d "$GL_FLAGS"
  done
done

say "4/4 보틀 창이 다른 앱 위에 떠 있지 않게 설정"
reg_add 'HKCU\Software\Wine\Mac Driver' /v WindowsFloatWhenInactive /t REG_SZ /d none

say "완료했어요. 이제 ./scripts/make-launcher-app.sh 로 넥슨 플러그 실행 앱을 만들어 주세요."
