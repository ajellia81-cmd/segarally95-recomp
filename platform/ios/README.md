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
검증합니다. IPA/archive/export/서명/아티팩트 업로드는 하지 않습니다.

직접 동일한 SDK 컴파일 검증을 실행하려면:

```sh
bash scripts/ios-readiness.sh --compile-check iphonesimulator
bash scripts/ios-readiness.sh --compile-check iphoneos
```

개인 설치용 서명 팀/고유 bundle ID 설정과 IPA archive/export는 별도 단계입니다.
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
- 세로 화면은 지원하지 않으며 4:3 원본 화면을 가로 화면 중앙에 표시합니다.

## 현재 제한과 검증

실제 게임 파일을 사용한 화면·팔레트·오디오·조작·저장·백그라운드 복귀·성능은
미검증입니다. Metal은 기존 GL 재질 정렬/깊이/스텐실 합성 계약을 옮긴 초기 구현이며
시각적 일치/성능을 보장하지 않습니다. iOS는 원본 게임 타이밍을 따릅니다.
자세한 실행 기록은 `docs/ios/VALIDATION.md`를 참조하세요.
