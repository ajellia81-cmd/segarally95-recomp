# Sega Rally Championship 0.2.1 — 개인용 IPA

최신 사용자 요청: Revision B ZIP 자동 준비, iPhone 18 Pro Max 전체 화면 와이드,
앱 이름/흰 배경 아이콘 변경. 컨트롤러 연결 시 터치 숨김/분리 시 복원은 유지합니다.
진동/햅틱 기능은 포함하지 않습니다.

## 설치 후 준비

파일 앱 → 나의 iPhone → **Sega Rally Championship → ROMs**에 본인이 보유한
B 버전이 포함된 **srallyc.zip 하나**를 넣고 앱에서 시작합니다. ZIP을 풀거나 BIN을
직접 만들 필요가 없습니다. 앱 Documents 최상위와 파일명 뒤 복사 번호도 인식합니다.
여러 ZIP을 동시에 두지 마세요. C 버전만 있는 ZIP은 지원하지 않습니다.
처음 시작을 누르면 ROMs 폴더가 생성되며, ZIP을 복사한 후 다시 시작할 수 있습니다.

필수 파일의 이름/크기/CRC를 확인한 뒤 새 비공개 준비 디렉터리에서 원본 선택과
ROM_LOAD32_WORD 순서의 BIN 변환을 진행합니다. 원본 ZIP은 바꾸지 않으며 준비 폴더는
iCloud 백업에서 제외합니다. 실패 시 구체적인 파일 오류를 표시합니다.

## 화면과 패키지

- 전체 화면을 nativeScale로 렌더링합니다. 2868×1320 가로 패널에서도 검은 4:3 양옆
  여백을 두지 않습니다. 3D 투영 창을 가로로 넓히고 세로 시야/기존 물체 비례를 유지합니다.
- 2D 타일과 스플래시는 화면 전체에 맞춥니다. 조작부는 화면 위 노치/홈 안전 영역 안에 표시합니다.
- 게임 내 카메라/GEO 명령은 변경하지 않습니다. 실제 주행에서 외곽 오브젝트 표시와 시각적 일치는 미검증입니다.
- 앱 표시 이름: Sega Rally Championship. 버전: 0.2.1(3). bundle ID: local.personal.segarally95.
- 흰 배경 아이콘은 사용자 제공 그림을 바탕으로 만들었습니다. iOS의 기본 모서리 마스크를 사용합니다.
- 미서명 iPhoneOS arm64 Release IPA이며 설치 시 사용자의 개인 서명이 필요합니다.
- ROM/게임 데이터/Apple 서명 자산을 IPA·git·CI에 포함하지 않습니다. IPA는 3일간 Actions
  아티팩트로 보관하며 App Store나 공개 Release에 게시하지 않습니다.

## 0.2 시작 실패 후속 조사

사용자가 0.2에서 시작 버튼을 누른 후 “게임 파일 검증 또는 코어 초기화 실패”를
보고했습니다. 이전 합성 시뮬레이터 검사는 실제 게임 초기화를 검증하지 않았습니다.
제공된 B ZIP의 준비 파일로 Linux에서 코어 CRC 및 사운드 파일 읽기만 다시 실행해
성공했으나, 사용자 기기의 실패 단계/원인은 아직 확정하지 못했습니다.

0.2.1은 준비 디렉터리를 복사해 보관하는 명시적 코어 경로를 설정합니다. ROM 검증과
BIN/사운드/지연 GEO 로더가 같은 디렉터리를 사용하며 환경변수에만 의존하지 않습니다.
검증기와 사운드 파일 로더의 고정 경로 버퍼도 확대하고 잘림을 거부합니다.

실패 시 경로 설정 / ROM 검증 / BIN 로딩 / 사운드·코어 초기화 중 해당 단계와 파일명,
CRC·크기 또는 파일/스레드 오류를 팝업으로 표시합니다. 파일 앱의 앱 Documents에
`startup-diagnostics.txt`를 생성합니다. 로그는 앱 버전·준비 경로·BIN 크기·검사 결과만
기록하며 ROM 바이트를 포함하지 않습니다. 오류가 계속되면 이 로그로 다음 원인을 좁힙니다.
로그 저장은 일반 파일 쓰기이므로 실패할 수도 있으며, 팝업의 오류가 우선입니다.

수정 소스: `2050dddd9bac186b125616b88256d4d289368a09`.
CI: https://github.com/ajellia81-cmd/segarally95-recomp/actions/runs/39733937745
파일: `SegaRallyChampionship-v0.2.1-unsigned.ipa` — 1,782,855 bytes.
SHA-256: `31e6fced804bb249ee5ae327e95a35d10a60856bf4521adc20e5dac03410ab51`.
다운로드 후 CRC·CI 체크섬·arm64·iPhoneOS·0.2.1(3)·앱 이름·아이콘·metallib 및
ROM/서명 자산 미포함 검사 통과. host 6/6과 Linux lift-check 통과.
CI 세 작업 전체 성공. Apple SDK 기기/시뮬레이터 컴파일과 기기 IPA 생성 통과.
시뮬레이터 합성 Metal 픽셀·전체 와이드 drawable·안전 영역·터치 숨김/복원 정책도 통과했습니다.
이 합성 검사는 새 오류 팝업의 실제 실패 경로나 게임 초기화를 실행하지 않습니다.
현재 수정이 사용자의 시작 실패를 해결했다고 주장하지 않으며 실제 기기에서 다시 확인해야 합니다.

## 이전 0.2 검증 기록

소스 커밋: `b9c6bfe552d1635041baa9b6e7a048c144f251fc`.
CI: https://github.com/ajellia81-cmd/segarally95-recomp/actions/runs/39731770134

파일: `SegaRallyChampionship-v0.2-unsigned.ipa` — 1,781,150 bytes.
SHA-256: `b61234ba43c2df28388179ebfacda69462b2cb1d71bca540b6a44421cbb1004e`.
다운로드한 IPA의 CRC 및 CI 체크섬 일치, arm64 Mach-O, iPhoneOS 플랫폼,
0.2(2) 표시 이름, Assets.car/AppIcon, metallib 및 ROM/서명 자산 미포함을 확인했습니다.

- 최신 CI 전체 성공: Linux lift-check, host 5/5, iPhoneOS Release 및 Simulator Debug 앱/Metal 컴파일·링크, 패키징 및 IPA 생성.
- iPhone 17 Pro Max 시뮬레이터에서 앱 설치·실행, 합성 단색/텍스처 픽셀, 전체 화면 와이드 및 안전 영역 조작부, 터치 숨김/복원 정책 통과.
  캡처 1320×2868, drawable 2868×1320, scale=3. 실제 패드 연결 시험은 아닙니다.
- 로컬 host 계약 테스트 5/5 통과: 로더, 루프, 입력/와이드 물체 비례, 원자적 저장, ZIP 처리.
- ZIP 테스트는 합성 바이트만 사용합니다. stored/deflated, 합본 하위 폴더, 인터리브 순서,
  누락·잘못된 CRC·로컬 헤더 손상·잘림·경로 탈출·심볼릭 링크·크기 불일치를 확인했습니다.
- 사용자 제공 B 합본 ZIP으로 별도 scratch에서 실제 가져오기/변환을 실행했습니다.
  생성된 BIN 두 개는 기존 검증된 변환 결과와 SHA-256이 일치했습니다.
- 실제 ROM 및 파생 파일은 저장소/CI에 업로드하지 않았으며 게임은 실행하지 않았습니다.

실제 iPhone 18 Pro Max 설치·게임 부팅/플레이·오디오·Backbone/패드·백그라운드 복귀·
장시간 성능은 미검증입니다. 시뮬레이터 합성 화면/정책 검사는 실제 게임 시험을 대신하지 않습니다.
