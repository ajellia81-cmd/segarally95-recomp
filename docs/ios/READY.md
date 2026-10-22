# IPA 생성 전 준비 상태

> 이 문서는 이전 요청의 준비 단계 기록입니다. 2026-10-22 사용자가 IPA 생성을
> 추가 승인했습니다. 현재 패키지와 검증 결과는 [IPA_BUILD.md](IPA_BUILD.md)를 참조하세요.

작업 대상: `ajellia81-cmd/segarally95-recomp`, `ios-port`. upstream/main은 수정하지 않았습니다.
현재 목표는 개인용 iOS 포트의 소스·빌드 준비이며, 실제 게임의 완주 검증이 아닙니다.

## 준비된 실행 경로

UIKit 앱 → 단일 백그라운드 코어 소유자 → 기존 cold boot/게임 루프 →
네이티브 뷰어 콜백 → 불변 프레임 스냅샷 → Metal 표시.

- 4:3 타일 하단/3D/타일 우선순위 합성, 기존 GEO 투영·재질·팔레트 계산 재사용.
- AVAudioEngine 44.1 kHz stereo PCM. 오디오 콜백은 PCM 잠금을 기다리지 않음.
- 앱 비활성화/오디오 중단 시 입력 해제, 체크포인트에서 사운드 워커 정지 및 저장.
- 터치 및 GCController 조향·페달·코인·시작·시점·기어.
- Application Support의 NVRAM 원자적 저장. ROMs 폴더는 iCloud 백업 제외.
- 게임 파일 누락 시 오류를 표시하며 자동 다운로드/추출하지 않음.
- 동적 코드 생성/JIT 경로를 추가하지 않음.

## 빌드/패키징 경계

```sh
# Xcode 프로젝트 생성까지만. IPA나 앱을 만들지 않음.
bash scripts/ios-readiness.sh

# 명시적 SDK 컴파일 검증: unsigned .app/Metal만 생성. IPA는 생성하지 않음.
bash scripts/ios-readiness.sh --compile-check iphoneos

# 기기 바이너리·bundle ID·Metal 리소스·자산 제외 여부 검사만 수행.
bash scripts/package-unsigned-ipa.sh --check build/ios-iphoneos/SegaRallyIOS.app
```

별도 IPA 생성 요청 전에는 패키징 스크립트의 `--create`를 실행하지 않습니다.
unsigned IPA를 생성하더라도 개인 설치에는 개인 서명/사이드로드 재서명이 필요합니다.
서명 인증서·프로파일·Apple 계정·게임 자산은 저장소 및 CI에 포함하지 않습니다.

빌드는 사용자 Windows PC가 아닌 GitHub의 macOS/Linux 러너에서 검증합니다.
빌드 스크립트는 소스로 보존되어 있으며 CI 결과는 워크플로 실행에 연결됩니다.
CI는 앱/IPA/스크린샷을 아티팩트로 업로드하지 않습니다.

## 검증 범위

확정된 명령·커밋·실행 링크는 `VALIDATION.md`의 최종 게이트를 참조하세요.
합성 삼각형 검증은 실제 게임 파일이나 게임 부팅 경로를 사용하지 않습니다.
실제 iPhone 설치, 게임 부팅/플레이, 텍스처 시각적 일치, BGM/효과음,
패드/터치 체감, 백그라운드 복귀, 장시간 저장 및 성능은 아직 미검증입니다.
전역 코어는 실행 종료 후 앱을 다시 열어야 하며 한 프로세스 내 재시작은 지원하지 않습니다.
