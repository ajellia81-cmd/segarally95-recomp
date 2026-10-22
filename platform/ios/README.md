# 개인용 iOS 네이티브 포트

이 타깃은 UIKit 앱에 기존 lifted C 코어를 정적으로 링크합니다. 동적 코드 생성은
사용하지 않습니다. 데스크톱 SDL/OpenGL/Cocoa 경로를 제외하고 네이티브 뷰어,
Metal 타일·GEO 출력, AVAudioEngine PCM, 터치 및 GCController 입력을 사용합니다.
실제 게임/실기기 동작 및 성능은 별도의 검증이 필요합니다.

## 빌드 준비

macOS + Xcode + iOS SDK/Metal 도구가 필요합니다. 저장소 루트에서 실행합니다.

```sh
bash scripts/ios-readiness.sh
```

기본 동작은 도구 검사와 Xcode 프로젝트 생성까지입니다. 앱/IPA를 만들지 않습니다.
`.github/workflows/ios-compile.yml`은 Apple SDK로 unsigned 앱과 셰이더의 컴파일·링크를
검증합니다. 2026-10-22 사용자 추가 요청에 따라 iPhoneOS Release 앱을 미서명 IPA로
패키징하고, 다운로드용 Actions 아티팩트로 3일간 보관합니다. ROM과 Apple 서명은 포함하지 않습니다.

직접 동일한 SDK 컴파일 검증을 실행하려면:

```sh
bash scripts/ios-readiness.sh --compile-check iphonesimulator
bash scripts/ios-readiness.sh --compile-check iphoneos
```

기본 bundle ID는 `local.personal.segarally95`이며 CMake의
`-DSEGAMOD2_BUNDLE_ID=개인.고유.식별자`로 지정할 수 있습니다.
`bash scripts/package-unsigned-ipa.sh --check`는 기기 앱/번들 ID/arm64/Metal 리소스와
게임 자산 미포함 여부를 검사하고 종료합니다. CI도 이 검사 모드만 실행합니다.
IPA 생성은 사용자가 추가로 승인했습니다. 직접 생성할 때는 아래 명령을 사용합니다.

```sh
bash scripts/package-unsigned-ipa.sh --create build/ios-iphoneos/SegaRallyIOS.app build/SegaRallyIOS-iPhone18ProMax-unsigned.ipa
```
개인 설치에는 개인 서명 또는 사이드로드 도구의 재서명이 별도로 필요합니다.
인증서·프로파일·Apple 계정·게임 파일을 저장소나 클라우드에 올리지 마세요.

## 기기에서만 준비하는 파일

앱에는 게임 자산이 없습니다. `시작`을 한 번 누르면 파일 앱의 이 앱 아래 `ROMs`
폴더를 만듭니다. 본인이 이미 보유한 파일을 기기에서 직접 준비해야 합니다.
클라우드 작업/CI는 게임 파일을 읽거나 다운로드·추출하지 않습니다.

- `maincpu_deinterleaved.bin`: 1 MiB
- `main_data_deinterleaved.bin`: 12 MiB
- 같은 ROMs 폴더에 `ROMS/manifest.yaml`에 정의된 Revision B의 원본 보드 파일들

앱은 기존 체크섬 검증을 거치며 명시적 파일만 읽습니다. 자동 추출이나 기본 경로
탐색으로 누락된 파일을 채우지 않습니다. 실행 실패 후 다시 시작하려면 앱을 완전히
종료한 뒤 열어 주세요. 전역 코어의 재시작/여러 인스턴스는 지원하지 않습니다.

## 조작과 수명주기

- 터치: 좌/우, 가속/브레이크, 코인/START, 시점, 기어 1→4 순환.
- 패드: 왼쪽 스틱/D-pad 조향, RT/A 가속, LT/B 브레이크, Y 코인,
  Menu 시작, X 시점, LB/RB 기어. 첫 번째 extendedGamepad를 사용합니다.
- 백그라운드/오디오 중단: 입력 해제, 코어의 호스트 체크포인트에서 사운드 워커
  정지 확인 후 NVRAM 저장. UI 스레드는 게임 루프를 실행하지 않습니다.
- NVRAM은 Application Support/SegaRally/nvram.yaml에 임시 파일+rename으로 저장합니다.
- 컨트롤러가 없으면 터치 버튼을 표시하고, 지원되는 extendedGamepad 연결 시 숨깁니다.
  분리하면 다시 표시하며 전환 시 기존 터치 입력을 해제합니다. 앱 실행/일시정지/종료 메뉴는 유지합니다.
- iPhone 18 Pro Max의 2868×1320 가로 패널을 목표로 실제 화면의 nativeScale을 사용합니다.
  게임 원본 4:3 비율을 유지하며, 노치/홈 안전 영역 내 중앙 캔버스 양옆에 조작부를 배치합니다.
  화면을 늘리거나 자르지 않으며, 가로 양방향 회전에 따라 drawable을 다시 계산합니다.
- 게임 내부 타일 해상도·카메라·FOV는 변경하지 않습니다. 세로 화면은 지원하지 않습니다.

## 현재 제한과 검증

ROM 없는 합성 단색·텍스처 삼각형의 Metal 화면 출력과 가장자리 픽셀 색을
시뮬레이터에서 확인했습니다. iPhoneOS/시뮬레이터 SDK 컴파일·링크, host 테스트
4/4 및 IPA 생성 전 검사도 통과했습니다. 이는 이전 준비 단계의 기록이며,
새 화면 배치/IPA 빌드 결과는 `docs/ios/IPA_BUILD.md`를 참조하세요.
실제 게임 파일을 사용한 화면·팔레트·오디오·조작·저장·백그라운드 복귀·성능은
미검증입니다. Metal은 기존 GL 재질 정렬/깊이/스텐실 합성 계약을 옮긴 초기 구현이며
시각적 일치/성능을 보장하지 않습니다. iOS는 원본 게임 타이밍을 따릅니다.
자세한 실행 기록은 `docs/ios/VALIDATION.md`를 참조하세요.
