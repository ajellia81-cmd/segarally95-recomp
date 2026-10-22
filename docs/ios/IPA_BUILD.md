# 개인용 IPA 빌드 — iPhone 18 Pro Max

2026-10-22 사용자가 IPA 생성 및 iPhone 18 Pro Max 화면 대응을 추가 승인했습니다.
이전 문서의 “IPA 생성 직전 중지”는 당시 요청 범위이며, 이번 요청으로 갱신되었습니다.
작업 대상은 사용자 포크의 `ios-port`뿐입니다.

## 화면과 입력

- 공식 2868×1320 가로 패널을 목표로 실제 기기의 nativeScale로 Metal drawable을 계산합니다.
- 게임은 원본 4:3 비율로 표시합니다. 가로 양옆 조작부는 게임 화면과 겹치지 않으며,
  노치/홈 안전 영역을 지킵니다. 게임의 타일 해상도·카메라·FOV는 바꾸지 않습니다.
- 컨트롤러가 없으면 터치 게임 버튼을 표시합니다. 지원되는 extendedGamepad가 연결되면
  버튼을 숨기고, 분리하면 복원합니다. 전환 시 눌린 터치 입력을 해제합니다.
- 앱 시작/일시정지/종료 메뉴는 컨트롤러 유무와 관계없이 남겨 둡니다.

## 패키지

- iPhoneOS arm64 Release, unsigned. ROM/게임 데이터/Apple 서명 자산 미포함.
- GitHub Actions 아티팩트에 IPA와 SHA-256을 3일간 보관하며 공개 Release는 생성하지 않습니다.
- iPhone에 설치할 때 SideStore 등 사용자의 개인 서명 과정이 필요합니다.
- 게임 파일은 앱 설치 후 사용자의 기기에서 직접 준비합니다. 클라우드에서는 읽거나 추출하지 않습니다.

## 검증

검증 소스: `9cd2790817d643bd24885e23d21dfee3a4ec9064`.
빌드 실행: https://github.com/ajellia81-cmd/segarally95-recomp/actions/runs/39704629334
전체 CI 성공을 확인했습니다. 이후 커밋은 문서만 갱신합니다.

| 검사 | 결과 |
|---|---|
| Linux lift-check 및 host 계약 테스트 | 전체 컴파일·링크, 4/4 통과 |
| iPhoneOS Release | arm64 앱/Metal 컴파일·링크, 패키징 전 검사, IPA 생성 및 아티팩트 보관 성공 |
| Simulator Debug | 앱/Metal 컴파일·링크 및 설치·실행 성공 |
| 합성 Metal 및 UI | 단색/텍스처 edge-clamp 픽셀, 안전 영역/게임-조작부 비중첩, 터치 표시→숨김→복원 및 눌린 터치 해제 정책 통과 |

러너에는 iPhone 18 Pro Max 시뮬레이터가 없어 같은 1320×2868 패널 크기의
**iPhone 17 Pro Max 시뮬레이터**를 사용했습니다. 캔버스 drawable=1728×1260,
scale=3이며, 캔버스 내부에서 게임 원본 4:3 화면을 최대 크기로 표시합니다.
전체 화면 픽셀 수와 게임 화면 픽셀 수는 조작부/안전 영역 때문에 다릅니다.
이 검사는 ROM 없이 생성한 프레임과 UI 정책을 검사하며, 실제 컨트롤러를 연결한 테스트가 아닙니다.

확인된 패키지: `SegaRallyIOS-iPhone18ProMax-unsigned.ipa`, 324,386 bytes.
SHA-256: `5adbffac3a144cfbb2893be3df8ef25e8ca1c086fe56f9d12a5119c9384ee910`.
다운로드 후 zip CRC, CI의 SHA-256 일치, arm64 Mach-O, iPhoneOS 플랫폼,
UIDeviceFamily=[1], 가로 양방향, Metal 라이브러리 및 서명/ROM 파일 미포함을 확인했습니다.

실제 iPhone 18 Pro Max 설치/실행, 게임 부팅·플레이·시각적 일치, BGM/효과음,
실제 Bluetooth/USB/Backbone 연결 및 입력, 백그라운드 복귀, 장시간 성능은 미검증입니다.
이는 개인 테스트용 첫 IPA이며 완성된 게임 동작을 보장하지 않습니다.

공식 기기 사양: https://www.apple.com/iphone-18-pro/specs/
