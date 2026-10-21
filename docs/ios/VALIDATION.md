# 검증 기록 — 2026-10-21

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
