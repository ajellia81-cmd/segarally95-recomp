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
