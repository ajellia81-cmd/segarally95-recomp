# 검증 기록

아래 초기 기록은 당시 상태입니다. 최신 결과는 문서 끝의 최종 게이트를 기준으로 확인하세요.

## 초기 준비 — 2026-10-21

작업은 원격 Linux 컨테이너에서 수행했습니다. 사용자 Windows PC는 사용하지 않았습니다.

- 초기 setup 시도: CMake 부재로 명확하게 실패. 이후 PyPI cmake 4.4.4 설치.
- `PATH=/root/.local/bin:$PATH bash .codex/setup.sh`: 성공, 종료 코드 0.
  CMake configure 및 `segamod2` 링크, `lift-check` 타깃 완료.
  기존 소스 컴파일 경고는 있었으며 경고 없는 빌드를 주장하지 않습니다.
- `bash -n .codex/setup.sh`: 성공.
- Python `plistlib.load`로 Info.plist 구문 및 APPL 패키지 타입 확인: 성공.
- `git diff --check`: 성공.
- 게임 실행/ROM 추출 타깃: 실행하지 않음. ROM 자산을 취득하거나 추가하지 않음.
- iOS 프로젝트: 소스 골격만 작성. Xcode/iOS SDK 컴파일, 시뮬레이터/실기기 실행,
  Metal 표시, 오디오, 컨트롤러, 터치, 저장, 성능은 검증하지 않음.
- Codex Cloud: 저장소 권한 확인 완료. 브라우저는 로그인이 필요하여 환경 생성/게시 및
  백그라운드 코딩 작업 시작은 확인되지 않음. 이 Linux 컴파일을 게시된 Codex 환경으로 간주하지 않음.

## 후속 작업: 앱 초기화 오류 반환

- Codex Cloud 설정 화면에서 환경 게시 완료(`환경이 게시되었습니다`, `게시됨`)를 확인했습니다.
  이는 후속 코딩 작업이 자동으로 계속 실행된다는 뜻은 아닙니다.
- `i960_host_load_extracted`: 두 명시적 경로가 없으면 실패하며 기본 경로/자동 추출로
  넘어가지 않습니다. 하위 로더의 성공/실패를 반환합니다. 체크섬/크기 검증 및 실패 시
  전역 상태 롤백은 아직 포함하지 않습니다.
- `i960_host_reset_checked`: 명시적 사운드 디렉터리를 받아 실패를 반환합니다.
  기존 데스크톱 reset은 기본 디렉터리 해석 및 실패 시 exit 동작을 유지합니다.
  성공 시 기존 사운드 스레드를 시작하므로 수명주기/스레드 정지 통합은 후속 작업입니다.
- `.codex/setup.sh`: ROM 없는 전체 lift-check 컴파일·링크 성공(기존 경고 있음).
- `cmake -S tests/host -B build/host-tests`, 빌드 후 `ctest --test-dir build/host-tests
  --output-on-failure`: 1/1 통과. 테스트는 가짜 로더로 null/빈 경로 거부, 오류 전파,
  성공 전파를 검사하며 ROM 파일 접근·게임 실행을 하지 않습니다.
- iOS SDK/실기기 검증은 여전히 미실시입니다.

## 후속 작업: 프레임 루프 경계

- `game_dispatch_main`의 기존 초기화 구간과 0x3190→0x3230 반복 구간을
  `i960_host_game_loop_begin` / `i960_host_game_loop_step`으로 기계적으로 분리했습니다.
  기존 데스크톱 진입점은 동일한 순서로 begin 후 step을 반복합니다.
- step은 이미 halt 상태이면 0, 한 반복을 마치면 1을 반환합니다.
  내부 게임 호출과 vsync 대기가 남아 있어 비차단 API가 아닙니다.
  초기 cold boot/후처리·pause·사운드 스레드 정지·shutdown 및 iOS 연결은 미완료입니다.
- 전체 ROM 없는 lift-check 컴파일·링크 통과. 기존 소스 경고는 남아 있습니다.
- host 테스트 2/2 통과. 추가 테스트는 실제 ROM/메모리/게임 서비스 대신 가짜 함수를
  링크하여 초기화 순서, 한 step의 호출 순서, halt 시 무실행, 데스크톱 반복 종료를
  검사합니다. 게임 플레이 및 하드웨어 정확도를 검증한 것이 아닙니다.

## 2026-10-22: 네이티브 수명주기 기반

사운드 워커에 mutex/condition 기반 pause 확인과 재개 API를 추가했습니다.
PCM backpressure 대기에서도 pause/stop을 확인합니다. 네이티브 오디오 콜백은
try-lock으로 PCM을 읽고, 잠금 경쟁 시 기다리는 대신 무음을 반환합니다.
iOS NVRAM 저장은 같은 디렉터리의 임시 파일에 쓰고 flush/fsync 후 rename합니다.

원격 Linux 전체 lift-check 컴파일·링크 성공. 기존 경고는 남아 있습니다.
이 기록 시점에 사운드 스레드의 기기상 중단/재개 및 디스크 실패 상황은 미검증입니다.


## 2026-10-22: iOS 앱/Metal 연결 — SDK 검증 대기

- root CMake가 iOS 코어 정적 라이브러리와 네이티브 앱을 구성하도록 변경했습니다.
- Linux 전체 lift-check 컴파일·링크 성공. 네이티브 C 뷰어/입력도 별도로 컴파일했습니다.
- host 계약 테스트 3/3 통과: 명시적 로더, 루프 경계, 네이티브 입력 범위/NaN/해제.
- Apple SDK 컴파일용 GitHub Actions를 추가했습니다. 이 커밋 시점에는 CI 결과를
  아직 확인하지 않았으며 iOS/Metal 컴파일 성공을 주장하지 않습니다.
- unsigned 앱 컴파일만 허용하며 IPA/archive/export/서명/자산 업로드는 하지 않습니다.
- 실기기, 시뮬레이터 실행, 실제 게임 파일, 화면·오디오·컨트롤러 및 성능은 미검증입니다.

## 2026-10-22: 텍스처 경계 검사 추가

검증 대상 소스 커밋: `4a7ec7b0677239c1190e341344e1bd8b4857ed80`.
실행: https://github.com/ajellia81-cmd/segarally95-recomp/actions/runs/39700501174

| 검사 | 실제 결과 | 범위 |
|---|---|---|
| Linux lift-check | 컴파일·링크 성공 | 게임/ROM 실행 없음, 기존 경고 있음 |
| host 테스트 | 4/4 통과 | 명시적 로더, 루프 경계, 입력 정규화, 합성 SRAM 원자적 저장·복원 |
| iPhoneOS | unsigned 앱/Metal 컴파일·링크 성공 | Xcode 26.6, iOS SDK, arm64 |
| 패키징 전 검사 | 통과 | 기기 플랫폼, arm64, bundle ID, 실행 파일, metallib, 금지 자산 패턴 확인; IPA 미생성 |
| 시뮬레이터 | SDK 컴파일·설치·실행 및 중앙 단색 픽셀 통과, 텍스처 픽셀 실패 | 기존 검사 좌표가 가로 스크린샷만 전제; 회전 대응 및 실패 진단 추가 후 재검증 |

실패를 성공으로 간주하지 않았습니다. 위 실행은 최종 통과 실행이 아닙니다.

## 2026-10-22: IPA 생성 직전 최종 게이트 — 통과

검증 소스 커밋: `b58f3109488cf6f27d2b316d63ad351c9613267e`.
실행: https://github.com/ajellia81-cmd/segarally95-recomp/actions/runs/39702068638
이후 문서 전용 커밋은 검증된 구현·검사 코드를 바꾸지 않습니다.

| 게이트 | 실제 확인 결과 |
|---|---|
| Linux 전체 lift-check | 컴파일·링크 성공, 기존 경고 있음 |
| ROM 없는 host 계약 테스트 | 4/4 통과: explicit_asset_loading, game_loop_boundary, native_input_mapping, native_atomic_nvram |
| iPhoneOS SDK | unsigned arm64 앱과 Metal 셰이더 컴파일·링크 성공 |
| iPhoneSimulator SDK | unsigned 앱과 Metal 셰이더 컴파일·링크 성공 |
| 시뮬레이터 실행 | 앱 설치·실행 후 프로세스 생존 확인 |
| 합성 Metal 픽셀 | 중앙 단색 및 텍스처의 edge-clamp 픽셀 색 통과. 1206×2622 캡처의 회전 반영 |
| IPA 생성 전 검사 | 기기 플랫폼/arm64/bundle ID/실행 파일/metallib/금지 자산 패턴 확인 통과 |
| IPA/archive/export/서명/아티팩트 업로드 | 실행하지 않음 |

CI 명령은 `.github/workflows/ios-compile.yml`에 보존했습니다.

```sh
bash .codex/setup.sh
cmake -S tests/host -B build/host-tests
cmake --build build/host-tests --parallel 2
ctest --test-dir build/host-tests --output-on-failure
# macOS matrix: iphoneos, iphonesimulator
cmake -S . -B build/ios-<SDK> -G Xcode -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT=<SDK> -DCMAKE_OSX_DEPLOYMENT_TARGET=15.0 -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO
cmake --build build/ios-<SDK> --target SegaRallyIOS --config Debug -- CODE_SIGNING_ALLOWED=NO
bash scripts/package-unsigned-ipa.sh --check build/ios-iphoneos/SegaRallyIOS.app
bash scripts/ios-simulator-smoke.sh build/ios-iphonesimulator
```

스크린샷은 러너 안에서만 검사했고 업로드하지 않았습니다. 합성 프레임은 직접 생성한
픽셀·정점·팔레트이며 게임 초기화/ROM/추출 데이터에 접근하지 않습니다.
ROM 취득·추출·업로드·커밋·배포를 하지 않았고 upstream/main을 수정하지 않았습니다.

실제 iPhone 설치, 게임 부팅·플레이·화면 일치, BGM/효과음, 실제 터치/패드 조작,
백그라운드 복귀, 실제 게임 NVRAM, 장시간 성능은 미검증입니다.
합성 픽셀 통과는 실제 게임 동작이나 전체 GL/Metal 시각적 일치를 증명하지 않습니다.
개인 서명과 기기 검증은 이후 단계이며 현재 요청의 정지 지점은 IPA 생성 전입니다.

## 2026-10-22: 추가 승인된 IPA 생성 — 통과

사용자가 미서명 IPA 생성, iPhone 18 Pro Max 화면 대응, 컨트롤러 연결 시 터치 숨김 및
분리 시 복원을 추가 요청했습니다. 위의 IPA 생성 전 정지 지점은 이 요청으로 갱신됐습니다.

소스 `9cd2790817d643bd24885e23d21dfee3a4ec9064`,
CI https://github.com/ajellia81-cmd/segarally95-recomp/actions/runs/39704629334 — 전체 성공.

- Linux lift-check, host 테스트 4/4 통과.
- iPhoneOS arm64 Release 및 simulator Debug 앱/Metal 컴파일·링크 성공.
- `package-unsigned-ipa.sh --check` 및 `--create` 성공.
- iPhone 17 Pro Max 시뮬레이터(1320×2868, scale=3): 합성 단색·텍스처 픽셀,
  안전 영역/조작부 비중첩 및 터치 숨김/복원 정책 통과. 실제 컨트롤러 연결은 미검증.
- 다운로드 후 패키지 CRC, CI 체크섬, arm64 Mach-O 및 앱 구성 검사 성공.
- Apple 서명·ROM 자산·App Store 배포·공개 Release 없음. 개인용 다운로드 아티팩트만 보관.
- 실제 iPhone 18 Pro Max와 게임 실행은 미검증. 상세 정보 및 SHA-256은 IPA_BUILD.md 참조.


## 2026-10-22: 0.2 ZIP 준비·전체 화면 와이드·앱 표시 — 최종 통과

검증/IPA 소스: `b9c6bfe552d1635041baa9b6e7a048c144f251fc`.
CI https://github.com/ajellia81-cmd/segarally95-recomp/actions/runs/39731770134 — 세 작업 전체 성공.
이후 문서 전용 커밋은 빌드된 소스/검사 코드를 바꾸지 않습니다.

| 검사 | 확인 결과 |
|---|---|
| Linux 전체 lift-check | 컴파일·링크 성공, 기존 경고 있음 |
| host 계약 테스트 | 5/5 통과: 로더, 루프, 입력/와이드 비례, 원자적 NVRAM, 합성 ZIP 준비 |
| ZIP 오류/변환 | stored/deflate, merged B 하위 경로, 정확한 인터리브; 누락/CRC/헤더/잘림/탈출/심볼릭 링크/크기 오류 거부 |
| 사용자 제공 B ZIP | 별도 개인 scratch에서 필수 19파일 CRC·크기와 가져오기 성공; 생성된 BIN 2개의 SHA-256이 기존 canonical 변환과 일치. 게임 실행 없음 |
| Apple SDK | arm64 iPhoneOS Release 및 Simulator Debug 앱/Metal 컴파일·링크 성공 |
| 시뮬레이터 | iPhone 17 Pro Max 앱 설치·실행 및 프로세스 생존, 합성 단색/텍스처 픽셀 통과 |
| 전체 화면/입력 정책 | 1320×2868 캡처, drawable 2868×1320, scale=3; 화면 전체 canvas, 안전 영역 조작부, 터치 숨김/복원 정책 통과 |
| IPA | 패키징 검사/생성 성공, 다운로드 후 CRC·CI 체크섬·arm64·iPhoneOS·0.2(2)·앱 이름·아이콘/metallib 확인 |
| 제외 자산 | IPA에 ROM/BIN/ZIP/서명 자산 없음; ROM/파생 파일의 git/CI 업로드 없음 |

앱 이름은 Sega Rally Championship, 아이콘은 사용자 제공 그림을 흰 배경으로 처리한
1024×1024 원본에서 Xcode가 생성했습니다. 3D 호스트 투영 창을 넓히며 세로 시야/물체
픽셀 비례를 유지합니다. 2D 화면은 전체 캔버스에 맞춥니다. 진동/햅틱은 포함하지 않습니다.

IPA: `SegaRallyChampionship-v0.2-unsigned.ipa`, 1,781,150 bytes.
SHA-256: `b61234ba43c2df28388179ebfacda69462b2cb1d71bca540b6a44421cbb1004e`.
개인 서명 후 설치해야 하며 App Store/공개 Release 게시를 하지 않았습니다.

실제 iPhone 18 Pro Max 설치, 실제 ROM으로 앱 부팅/플레이, 와이드 외곽 오브젝트 표시,
BGM/효과음, Bluetooth/USB/Backbone 연결, 백그라운드 복귀 및 장시간 성능은 미검증입니다.
합성 시뮬레이터/host 테스트는 실제 게임/기기 검증을 대신하지 않습니다.


## 2026-10-22: 사용자 0.2 시작 실패 보고 — 0.2.1 조사 빌드

사용자가 실제 기기에서 “게임 파일 검증 또는 코어 초기화 실패”를 보고했습니다.
이전 합성 시뮬레이터 통과는 게임 초기화 검증이 아니었으며, 0.2의 실기기 시작 성공으로
해석하면 안 됩니다. 현재 실패 단계/원인은 로그가 없어 확정하지 못했습니다.

소스: `2050dddd9bac186b125616b88256d4d289368a09`.
CI: https://github.com/ajellia81-cmd/segarally95-recomp/actions/runs/39733937745

- 명시적 ROM 디렉터리를 코어가 복사해 보관하고 모든 resolver가 이를 우선 사용하도록 변경.
  검증은 별도 명시적 경로 API로 실행하므로 앱 환경변수만으로 디렉터리를 전달하지 않습니다.
- 검증 실패에 파일명·크기·CRC/읽기 오류, 사운드 로딩 실패에 파일명·열기/짧은 읽기/할당 오류,
  사운드 스레드 생성 실패에 pthread 오류 코드를 제공합니다.
- 앱은 시작 단계를 분리해 오류 팝업과 Documents/startup-diagnostics.txt에 기록합니다.
  로그는 버전·경로·파일 크기·결과를 포함하고 ROM 바이트를 포함하지 않습니다.
- Linux 전체 lift-check 성공(기존 경고 있음), host 6/6 통과.
  native_startup_paths는 합성 파일로 768자 초과 경로, 경로 소유권과 환경변수 우선순위,
  ROM 누락/불일치, 사운드 파일 성공/누락/짧은 읽기 및 오류 초기화를 검사합니다.
  사운드 CPU/스레드/게임은 실행하지 않습니다.
- 사용자 제공 B 준비 파일로 별도 scratch에서 명시적·공유 resolver의 코어 CRC와 사운드
  파일 읽기만 실행해 모두 0을 확인했습니다. 사운드 CPU/스레드/게임 실행은 하지 않았습니다.
- CI 세 작업 전체 성공. iPhoneOS Release/Simulator Debug SDK 컴파일·링크, IPA 생성 및
  다운로드 후 패키지 검사 통과. 시뮬레이터 합성 Metal 픽셀, 전체 와이드 drawable,
  안전 영역 및 터치 숨김/복원 정책 통과. 새 오류 팝업의 실제 실패 경로나 게임 초기화를
  이 합성 검사가 실행한 것은 아닙니다.

IPA: `SegaRallyChampionship-v0.2.1-unsigned.ipa`, 1,782,855 bytes.
SHA-256: `31e6fced804bb249ee5ae327e95a35d10a60856bf4521adc20e5dac03410ab51`.
사용자의 시작 오류 해결 여부는 실기기 재시험 전입니다. 계속 실패하면 새 팝업 또는
startup-diagnostics.txt가 필요합니다. ROM/파생 데이터의 git/CI/IPA 포함은 없습니다.


## 2026-10-22: 0.2.1 진단 로그 확인 — 활성 준비 폴더 삭제 오류 수정

사용자 기기의 로그는 ZIP 가져오기 완료 후 준비 폴더 및 두 BIN의 stat가 모두
ENOENT(errno=2)였음을 확인했습니다. ROM 내용 CRC 검사가 시작되기 전의 실패입니다.
개인 컨테이너 경로/UUID와 첨부 로그 자체는 git/CI에 넣지 않았습니다.

원인: 캐시 정리에서 NSURL 객체의 isEqual:로 현재 폴더를 구분했습니다. 열거 URL과
isDirectory:YES로 만든 URL의 끝 슬래시 표현 차이 때문에 같은 현재 폴더도 삭제 대상이
됩니다. 같은 부모 안의 생성된 고유 폴더 이름으로 비교하도록 수정하고, 정리 후 폴더
존재를 C stat로 확인합니다. 원본 ZIP은 변경하지 않으므로 다시 준비할 수 있습니다.

소스: `3100f79b25b4fcb8c977cc863292015291c7dac5`.
CI: https://github.com/ajellia81-cmd/segarally95-recomp/actions/runs/39735298120

- Apple Foundation 회귀 검사에서 `Legacy NSURL equality would delete active directory: YES`
  확인. 수정된 동일 정리 함수는 활성 폴더와 합성 BIN을 보존하고 이전 준비 폴더만 삭제했습니다.
  일반 사용자 폴더 보존 및 슬래시 없는 활성 URL 변형도 검사했습니다. 게임 데이터 없음.
- Linux 전체 lift-check 및 host 6/6 통과.
- CI 세 작업 전체 성공. iPhoneOS Release/Simulator Debug 앱·Metal 컴파일·링크,
  기기 IPA 생성 및 시뮬레이터 합성 Metal 픽셀·전체 와이드·안전 영역·터치 정책 검사 통과.
- 다운로드 후 CRC·CI 체크섬·arm64·iPhoneOS·0.2.2(4)·앱 이름·아이콘/metallib·제외 자산 검사 통과.

IPA: `SegaRallyChampionship-v0.2.2-unsigned.ipa`, 1,782,976 bytes.
SHA-256: `385197d1f5815ab00f660230920a5e3005659869b9d75034cf16d5cff46a6faf`.
실제 iPhone에서 게임 시작 성공 여부는 사용자 재시험 전입니다. ROM/게임 데이터의
CI·git·IPA 포함이나 실제 게임/사운드 CPU 실행은 하지 않았습니다.
