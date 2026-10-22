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
  설정 채팅: https://chatgpt.com/local/01a15e75-be36-76a5-872e-33dc2fbf6033
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
