# 클라우드 작업 환경

Codex Cloud의 `segarally95-recomp` 환경 게시 완료를 설정 UI에서 확인했습니다.
공개 범위는 `나만`, 연결 저장소는 `ajellia81-cmd/segarally95-recomp`뿐입니다.
설정 채팅: https://chatgpt.com/local/01a15e75-be36-76a5-872e-33dc2fbf6033

게시된 파일시스템/설치 스크립트의 기준은 최초 준비 커밋
`17e23580dc436346c4173712840cbe7a7891b283`입니다. 최신 이식 코드는 포크의
`ios-port`에 있으므로 후속 클라우드 작업은 먼저 최신 브랜치와 HEAD를 확인해야 합니다.
환경 자체를 다시 게시할 때는 설치 스크립트의 기준 커밋 검사도 함께 갱신합니다.

환경 게시만으로 후속 코딩 작업이 자동으로 계속 실행되지는 않습니다.
이후 구현은 별도의 원격 채팅 실행 환경에서 진행하고 GitHub에 저장했습니다.
사용자 Windows PC에는 의존하지 않습니다.

## 검증 역할

- Linux: `bash .codex/setup.sh`로 실행 없는 `lift-check` 컴파일.
- `tests/host`: ROM 없는 로더·루프·입력/와이드 비례·NVRAM·합성 ZIP 계약 테스트.
- GitHub Actions: Apple SDK로 iPhoneOS/시뮬레이터의 unsigned 앱 및 Metal 컴파일.
- 시뮬레이터: ROM 없는 생성 픽셀/삼각형으로 앱 설치·실행 및 표시 검증.
- IPA 패키징: 준비 단계에서는 `--check`만 실행했습니다. 2026-10-22 추가 승인 후
  미서명 Release IPA를 생성하고 다운로드용 아티팩트로 3일간 보관합니다.
  ROM/게임 데이터/Apple 서명/공개 Release는 포함하지 않습니다.

GitHub/CI에는 ROM 및 파생 데이터를 추가하지 않습니다. 사용자 제공 B ZIP은 별도
개인 scratch에서 가져오기/변환만 검증했고 게임을 실행하지 않았습니다. 앱은 설치 후
기기에 사용자가 복사한 ZIP을 비공개 캐시에서 준비합니다. 인터넷 ROM 취득·배포,
optional tools 복제, upstream 푸시 및 Apple 서명 자산 추가는 수행하지 않습니다.
