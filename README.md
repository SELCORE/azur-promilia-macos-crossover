# 아주르 프로밀리아 맥북 실행 가이드 (CrossOver)

Apple Silicon 맥에서 CrossOver로 넥슨 플러그와 아주르 프로밀리아(한국 PC판)를 설치하는 방법과 스크립트예요.

*Unofficial guide and helper scripts for installing Nexon Plug and Azur Promilia (Korean PC version) on Apple Silicon Macs with CrossOver.*

> **비공식 가이드예요.** 넥슨, 만쥬, CodeWeavers와 관련이 없어요.
> 넥슨은 macOS나 Wine 환경을 지원하지 않아요. 따라 하다가 생기는 계정 제재 등의 문제는 본인 책임이에요.
> 이 저장소에는 넥슨 파일이 들어 있지 않아요. 스크립트가 실행될 때 넥슨 공식 서버(`platform.nexon.com`)에서 받아요.

> **CrossOver가 없다면:** 무료 Wine과 DXMT로 돌리는 실험용 런처도 있어요. 앱 하나로 준비부터 실행까지 해요 → [azur-promilia-launcher](https://github.com/SELCORE/azur-promilia-launcher)
> 아직 실험 단계라 CrossOver 방법보다 확인된 부분이 적어요.

## 지금 상태 (2026-11-26 기준)

| 단계 | 결과 |
|---|---|
| 넥슨 플러그 설치와 실행 | 됨 (공식 설치 프로그램 대신 스크립트로 설치) |
| 넥슨 ID 로그인 | 됨 |
| 게임 다운로드 (약 82GB) | 됨 |
| 게임 실행 파일 시작 | 됨: Direct3D 11 장치 생성, 넥슨 보안 모듈(NGS-X) 초기화 성공 |
| 로그인 후 게임 실행 | 됨: 오픈 당일 [무료 Wine 런처](https://github.com/SELCORE/azur-promilia-launcher)에서 확인했어요. 같은 수정(글꼴, 서비스)을 이 가이드에도 넣었어요. CrossOver에서 직접 켜 보는 건 아직 확인 전이에요. |

게임 실행 파일 시작은 런처 없이 직접 켜서 확인했어요. 로그인 SDK에서 멈추고 꺼졌는데, 런처를 거치지 않아 로그인 정보가 없기 때문으로 보여요.

**테스트 환경:** MacBook Pro (M5 Pro, 메모리 24GB), macOS 27.0.1, CrossOver 26.3

## 준비물

- Apple Silicon 맥
- [CrossOver](https://www.codeweavers.com/crossover) 26 이상 (유료, 체험판 있음)
- 여유 공간 **170GB 이상**
  - 넥슨 플러그가 설치 전에 약 162GB를 요구해요.
  - 실제 설치 크기는 약 82GB예요.
- 터미널에서 쓸 `python3`
  - 없으면 터미널에서 `xcode-select --install`을 실행하세요.

## 설치

### 1. 보틀 만들기

1. CrossOver에서 새 보틀을 만들어요.
   - 이름: `Azur Promilia`
   - 템플릿: **Windows 10 64-bit**
2. 보틀 설정에서 Windows 버전을 **Windows 11**로 바꿔요.

보틀 이름을 다르게 지으면 아래 스크립트를 실행할 때 `BOTTLE="보틀 이름"`을 앞에 붙이세요.

### 2. 공식 설치 프로그램을 한 번 실행하기

1. [넥슨 플러그 설치 프로그램](https://platform.nexon.com/launcher/installer/win/KRPC/Install_NexonPlug.exe)을 받아요.
2. CrossOver의 "Run Command"로 이 보틀에서 실행해요.
3. 설치 창이 흰 화면으로 멈추면 닫아요.
   - Wine에서는 설치 창 화면이 표시되지 않아요.
   - 그래도 이 과정에서 NGM에 필요한 **WebView2 런타임**이 먼저 설치됐어요 (테스트 환경 기준).
4. 보틀 안에 `C:\Program Files (x86)\Microsoft\EdgeWebView` 폴더가 생겼으면 다음 단계로 넘어가요.

### 3. 설치 스크립트 실행하기

```bash
git clone https://github.com/SELCORE/azur-promilia-macos-crossover.git
cd azur-promilia-macos-crossover
./scripts/setup.sh
```

`setup.sh`가 하는 일:

1. 넥슨 공식 서버에서 넥슨 플러그(약 180MB)를 받아 보틀의 `C:\Nexon\NexonPlug`에 풀고, 설치 정보를 레지스트리에 등록해요.
2. NGM(넥슨 게임 매니저)을 공식 서버에서 받아 `C:\ProgramData\Nexon\NGM`에 넣어요.
   - NGM이 없으면 게임 설치를 누를 때 "게임 실행에 실패했습니다"가 떠요.
3. NGM 화면이 검게 나오지 않게 WebView2를 소프트웨어 렌더링으로 설정해요.
4. 보틀 창이 다른 맥 앱 위에 떠 있지 않게 Wine 설정(`WindowsFloatWhenInactive=none`)을 바꿔요.
5. 게임 안 한글이 보이도록 맥의 한글 글꼴을 게임이 찾는 윈도우 글꼴 이름으로 넣어요.
6. 게임시작 때 실패 팝업이 뜨지 않도록 Wine에서 켜지지 않는 "Nexon Launcher" 서비스를 꺼요.

넥슨 플러그나 NGM이 보틀에서 실행 중이면 스크립트가 멈춰요. 먼저 종료하고 다시 실행하세요.

### 4. 실행 앱 만들기

```bash
./scripts/make-launcher-app.sh
```

`~/Applications/넥슨플러그 (CrossOver).app`이 만들어져요. **넥슨 플러그는 항상 이 앱으로 켜세요.**

- 이 앱은 `--use-gl=swiftshader --use-angle=swiftshader --in-process-gpu` 옵션을 붙여서 넥슨 플러그를 켜요.
- CrossOver에서 `NexonPlug.exe`를 그냥 실행하면 창이 검게 나와요.

### 5. 로그인하고 게임 설치하기

1. **넥슨 ID로 로그인**하고 자동 로그인을 켜 두세요.
2. 아주르 프로밀리아 페이지에서 설치를 눌러요.
3. 다운로드는 약 82GB이고, 끝날 때까지 넥슨 플러그를 닫지 마세요.

## 알려진 문제

| 증상 | 해결 |
|---|---|
| 설치 프로그램이 흰 화면 | 정상이에요. 2단계처럼 닫고 `setup.sh`를 쓰세요. |
| 넥슨 플러그 창이 검은 화면 | 4단계 실행 앱으로 켜세요. |
| 설치를 누르면 "게임 실행에 실패했습니다" | NGM이 없을 때 나요. `setup.sh`로 설치하세요. |
| 게임시작을 누르면 "게임 실행에 실패했습니다"가 뜨는데 게임은 켜짐 | NGM이 Wine에서 켜지지 않는 "Nexon Launcher" 서비스를 기다리다 늦어져서 생겨요. `setup.sh`와 실행 앱이 이 서비스를 꺼 줘요. 실행 앱을 예전에 만들었다면 `make-launcher-app.sh`로 다시 만드세요. |
| 게임 안 일부 화면에서 한글이 빠져 보임 | 게임이 찾는 윈도우 글꼴(맑은 고딕, MiSans 등)이 보틀에 없어서 생겨요. `setup.sh`가 맥의 한글 글꼴(AppleGothic)을 그 이름으로 넣어 줘요. 이 맥 안에서만 쓰는 복사본이에요. |
| 다운로드가 99% 근처에서 취소됨, `GridDown Error(517)` | 다시 설치를 누르면 받아졌어요. 원인은 확인하지 못했어요. 처음부터 다시 받을 수도 있어요. |
| 넥슨 플러그 창이 다른 앱을 써도 계속 위에 떠 있음 | `setup.sh` 4번 설정으로 고쳐지길 기대하지만 아직 검증 중이에요. 그동안은 창을 최소화(⌘M)하세요. 다운로드 중에는 닫지 마세요. |
| 구글 등 외부 계정 로그인이 브라우저에서 돌아오지 않음 | 넥슨 ID로 로그인하세요. |
| DLSS, XeSS를 쓸 수 없음 | 맥에서는 지원되지 않아요. 게임 설정에서 끄세요. |

## 위험 요소

- **넥슨 게임 보안(NGS-X):** 시작할 때 초기화는 통과했어요. 그래도 게임 중 검사에서 Wine 환경을 잡아내서 막을 수 있어요.
  - 같은 보안을 쓰는 블루 아카이브는 Linux(Proton)에서 실행되고, 메이플스토리는 실행되지 않는 것으로 알려져 있어요 ([GamingOnLinux](https://www.gamingonlinux.com/anticheat/vendor/nexon-game-security/)).
- **맥 기기 정보:** 게임 로그에 기기 모델이 맥으로 기록돼요. 넥슨이 막기로 하면 막힐 수 있어요.
- **설치 파일 주소:** 넥슨이 설치 파일 주소를 바꾸면 `setup.sh`의 주소(`PLUG_URL`)도 바꿔야 해요.

## 제거

1. CrossOver에서 보틀을 삭제해요.
2. `~/Applications/넥슨플러그 (CrossOver).app`을 지워요.

## 라이선스

이 저장소의 스크립트와 문서는 [MIT 라이선스](LICENSE)예요. 넥슨, 넥슨 플러그, 아주르 프로밀리아는 각 권리자의 상표이자 저작물이에요.
