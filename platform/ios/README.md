# Sega Rally Championship — 개인용 iOS 포트

사용자 포크의 `ios-port` 전용입니다. ROM/게임 데이터는 앱 및 저장소/CI에 포함하지 않습니다.
실제 게임 동작과 iPhone/Backbone 조작은 아직 검증이 필요합니다.

## ZIP 하나로 준비

1. 앱의 `시작`을 한 번 눌러 폴더를 만듭니다.
2. 파일 앱 → 나의 iPhone → **Sega Rally Championship → ROMs**에 본인이 보유한
   **Revision B를 포함한 `srallyc.zip`**을 그대로 넣습니다.
3. 앱에서 다시 `시작`을 누릅니다. 앱 내부에서 필요한 원본 파일 선택·크기/CRC 검증·
   BIN 변환을 수행합니다. 사용자가 ZIP을 풀거나 BIN을 만들 필요가 없습니다.

`srallyc(1).zip`처럼 복사 번호가 붙어도 찾습니다. ROMs 대신 앱 Documents 최상위에
넣어도 인식합니다. 여러 ZIP을 동시에 두지 마세요. ROMs 폴더가 먼저 검색됩니다.
일반적인 stored/deflated ZIP을 지원하며, ZIP64/암호화/분할 ZIP은 지원하지 않습니다.
Revision C만 있는 ZIP은 지원하지 않습니다. B의 프로그램 파일은
`epr-17888b.12`, `epr-17889b.13`이며 합본 ZIP의 `srallycb/` 하위 폴더도 자동 탐색합니다.
필수 공통 파일은 `ROMS/manifest.yaml`에 명시되어 있습니다.

원본 ZIP은 변경하지 않습니다. 준비 결과는 앱의 Application Support 내 새 폴더에
작성하며 성공한 뒤 이전 준비 캐시를 정리합니다. 준비 결과와 ROMs는 iCloud 백업에서
제외합니다. 기존의 수동 원본+BIN 배치도 ZIP이 없을 때 계속 사용할 수 있습니다.
잘못된 파일/누락/손상은 이름을 포함한 오류로 표시하며, 파일 준비 실패 후에는 앱을
재설치하지 않고 다시 시도할 수 있습니다. 게임을 한번 실행한 뒤 재시작은 앱을 완전히
종료한 뒤 열어야 합니다.

## 화면과 입력

- iPhone 18 Pro Max의 가로 화면 전체를 실제 nativeScale로 렌더링합니다.
- 3D는 세로 시야와 기존 4:3 물체 비례를 유지하면서 가로 투영 창을 넓힙니다.
  2D 타일/스플래시는 전체 화면에 맞춰 표시합니다. 게임 내부 카메라/GEO 명령은 바꾸지 않습니다.
- 조작부는 노치/홈 안전 영역 안에 겹쳐 표시합니다. 지원되는 extendedGamepad가
  연결되면 게임 터치 버튼을 숨기고, 분리하면 복원합니다. 전환 시 눌린 터치를 해제합니다.
- 시작/일시정지/종료 메뉴는 계속 사용할 수 있습니다. 진동/햅틱 기능은 포함하지 않습니다.
- 터치: 좌/우, 가속/브레이크, 코인/START, 시점, 기어 1→4 순환.
- 패드: 왼쪽 스틱/D-pad 조향, RT/A 가속, LT/B 브레이크, Y 코인, Menu 시작,
  X 시점, LB/RB 기어. 첫 번째 extendedGamepad를 사용합니다.
- 앱 비활성화/오디오 중단 시 입력을 해제하고 호스트 체크포인트에서 정지·저장합니다.
  NVRAM은 Application Support/SegaRally/nvram.yaml에 원자적으로 저장합니다.

## macOS 빌드

```sh
bash scripts/ios-readiness.sh --compile-check iphoneos
bash scripts/package-unsigned-ipa.sh --create build/ios-iphoneos/SegaRallyIOS.app build/SegaRallyChampionship-v0.2-unsigned.ipa
```

GitHub Actions는 iPhoneOS Release 및 simulator Debug 앱/Metal을 컴파일하고,
개인용 미서명 IPA를 3일간 아티팩트로 보관합니다. 개인 설치에는 SideStore 등으로
사용자의 서명이 필요합니다. 인증서·프로파일·Apple 계정·ROM을 git/CI에 넣지 않습니다.
기본 bundle ID는 `local.personal.segarally95`이며 `-DSEGAMOD2_BUNDLE_ID=개인.고유.식별자`로
설정할 수 있습니다. 앱 표시 이름은 Sega Rally Championship, 버전은 0.2(2)입니다.
아이콘은 사용자 제공 그림을 흰 배경에 배치한 파생 아이콘입니다.

검증 기록과 실제 게임/기기 미검증 범위는 `docs/ios/VALIDATION.md`를 참조하세요.


### 시작 실패 진단 (0.2.1)

준비 폴더를 코어에 직접 설정하며 모든 보드 로더가 같은 폴더를 사용합니다.
시작 실패 팝업은 ROM 검증/BIN 로딩/사운드·코어 초기화를 구분하고, 파일 앱의
앱 최상위에 `startup-diagnostics.txt`를 저장합니다. 다시 실패하면 팝업 또는 로그로
실패한 단계와 파일/오류 코드를 확인합니다. ROM을 바꿔야 한다고 먼저 단정하지 마세요.
사용자 기기의 0.2 시작 실패 원인은 아직 확정되지 않았으며 0.2.1의 실기기 재확인이 필요합니다.


### 준비 폴더 보존 (0.2.2)

0.2/0.2.1은 캐시 정리에서 URL 끝 슬래시 차이로 활성 준비 폴더까지 지울 수 있었습니다.
0.2.2는 같은 부모 안의 고유 폴더 이름으로 현재 폴더를 보존합니다. 기존 ZIP을 그대로
ROMs에 두고 다시 준비할 수 있습니다. Foundation 회귀 검사는 게임 데이터 없이 수행합니다.
