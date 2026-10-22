# 개인용 iPhone/iOS 이식 계획

## 상태와 범위

기준: main `6fe9db1a276996f1893e9e94d50617e49580688c`.
작업 대상은 `ajellia81-cmd/segarally95-recomp`의 `ios-port` 브랜치뿐입니다.
이 변경은 환경 준비, 소스 조사, 독립 앱 골격입니다. 플레이 가능한 포트가 아닙니다.
ROM 취득/업로드/추출/배포, upstream 수정, Apple 서명은 포함하지 않습니다.

## 소스 조사 결과

| 경로 | 관찰 | 이식 작업 |
|---|---|---|
| CMakeLists.txt | C99, SDL2/PNG/OpenGL 선택 의존성; APPLE 조건에서 OpenGL/Cocoa 링크 | macOS와 iOS 분리, UIKit 타깃 구성 |
| src/lift_main.c, src/host/lift_cli.c | CLI main 및 데스크톱 실행 흐름 | init/step/pause/shutdown 수명주기 추출 |
| src/host/sys24_viewer.c | SDL 윈도, OpenGL 2.1 호환 컨텍스트, 키보드 이벤트와 표시 결합 | 입력/표시 분리, Metal 타일 합성부터 구현 |
| lib/model2/geo/model2_geo_gl.c | 기존 GL GEO 표시 경로 | 변환 계약 확인 후 단계적으로 Metal로 이식 |
| src/host/model2_snd_lift.c | SDL 오디오 장치 열기/일시정지/닫기 | iOS 오디오 세션·중단·재개·출력 경로 변경 처리 |
| src/host/model2_nvram.c | I960_HOST_NVRAM 또는 build/lift/nvram.yaml | Application Support 아래 명시적 쓰기 경로와 원자적 저장 |
| lib/model2/host/model2_rom.c, README.md | 첫 실행 시 호스트가 ROM 추출 가능 | 클라우드에서 실행 금지; 추후 기기 내 사용자 파일 경로 계약 분리 |

Rules.txt와 .cursor/rules의 게임 의미·변환 규칙을 유지합니다.
Metal 이식으로 임의 FOV, 카메라, 메쉬 자동 맞춤을 추가하지 않습니다.

## 단계와 완료 기준

| 단계 | 결과물 | 검증/완료 기준 |
|---|---|---|
| 0. 클라우드 기반 준비 | 포크 전용 브랜치, AGENTS, setup 스크립트, 이 계획 | ROM 없는 lift-check 컴파일; Codex 환경 게시 상태 별도 확인 |
| 1. 앱 골격 | platform/ios 독립 UIKit/MTKView 앱 | macOS/Xcode에서 unsigned 시뮬레이터 빌드 및 실행; clear 화면, 회전, 비활성 시 그리기 중지 확인 |
| 2. 코어 경계 | CLI 루프에서 init/step/pause/shutdown 분리, ROM 누락 오류 전달 | 데스크톱 컴파일 회귀 없음; ROM 없는 init 실패가 명확하고 추출을 자동 시작하지 않음 |
| 3. Metal 표시 | 합성 타일 업로드/색순서/필터/letterbox; 이후 GEO 렌더 경로 | 자체 생성 픽셀/삼각형으로 검증; 기존 변환 계약 유지, 기기 GPU 확인 |
| 4. iOS 서비스 | 샌드박스 저장, 파일 선택/복사 정책, AVAudioSession 및 오디오 브리지 | synthetic 오디오 중단/재개, 파일 오류·쓰기 실패·저장 복구 검증 |
| 5. 입력 | 터치 조향/페달/시작/코인, GCController 아날로그/버튼 | 입력 스냅샷 API; 멀티터치·취소·백그라운드·패드 분리 시 held 입력 해제 |
| 6. 개인 기기 통합 | 서명된 개인 설치, 사용자 소유 파일은 기기에만 유지 | 실제 iPhone에서 게임/음성/저장/프레임 페이싱 확인 후에만 지원 주장 |

단계 2의 경계 확정 전에 게임 코어를 UIKit 메인 스레드에서 무한 루프로 실행하지 않습니다.
논리 tick과 표시 주사율을 분리하되 원래 게임 타이밍을 먼저 확인합니다.
첫 목표는 원래 동작 보존이며 120/165fps 등은 측정 전 보장하지 않습니다.

## 다음 클라우드 작업 지시

1. 이 문서와 AGENTS.md, Rules.txt를 읽고 현재 브랜치/remote를 확인합니다.
2. bash .codex/setup.sh로 ROM 없는 컴파일을 확인합니다.
3. 단계 2를 작은 커밋으로 진행합니다. CLI 루프 및 전역 상태·오디오 스레드 소유권을
   먼저 조사하고, 소스 근거와 실행하지 않은 부분을 기록합니다.
4. Apple SDK가 없는 환경에서는 iOS/Metal API 컴파일 성공을 주장하지 않습니다.
5. 커밋을 포크의 작업 브랜치에 저장하고 검토 가능한 diff를 남깁니다.

## 검증 기록

아래 기록은 실행한 명령만 기재합니다. Xcode, 시뮬레이터, 실기기, 게임 재생은 미검증입니다.
상세 결과는 VALIDATION.md에 기록합니다.

## 구현 진행

- 단계 2의 첫 경계: 명시적 파일 로더와 오류 반환 reset API 추가.
- 기존 game_dispatch_main의 초기화/반복 구간을 begin/step으로 분리.
  ROM 없는 가짜 서비스 테스트로 호출 순서와 halt 경계를 검증함.
- 다음 작업: cold boot부터 새 루프 진입으로 이어지는 소유권 설계, pause/resume 시
  입력 해제와 vsync 타이머/사운드 스레드 정지·재개, 일관된 shutdown/오류 복구.
  현재 begin/step은 UIKit에서 호출하지 않으며, 루트 main을 iOS에 연결하지 않음.

## 2026-10-22 네이티브 통합

UIKit 앱이 기존 lifted 코어를 소유하는 백그라운드 작업을 시작합니다. iOS 빌드에서
SDL/OpenGL/Cocoa와 데스크톱 main/녹화/오디오를 제외하고 별도 뷰어를 링크합니다.
네이티브 뷰어는 기존 vsync 콜백을 사용하므로 타이밍과 cold boot 순서를 유지합니다.
기존 begin/step API는 독립 호출하지 않고 원래 boot 흐름에서 사용합니다.

Metal 타일·GEO 출력, 기존 텍스처/팔레트·재질 정렬, AVAudioEngine 44.1kHz PCM,
터치·GCController, 입력 해제·오디오 중단·백그라운드 저장 경로를 구현했습니다.
이 항목들은 구현 상태이며, 게임/실기기 검증 완료를 의미하지 않습니다.

IPA 생성 전 준비 게이트:
1. ROM 없는 Linux 컴파일 및 계약 테스트.
2. Apple SDK 대상 C/Objective-C/Metal 컴파일·링크(CI, 서명 없음).
3. 기기 검증에 필요한 파일 경로·조작·알려진 제한을 문서화.
4. 별도 요청 전에는 IPA archive/export 및 개인 서명은 수행하지 않음.
