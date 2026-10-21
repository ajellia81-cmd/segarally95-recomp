# iOS 앱 골격 (게임 미연결)

UIKit 앱 진입점, MTKView clear 패스, 비활성/활성 시 그리기 중지/재개만 포함합니다.
게임 렌더러, ROM 로딩, 오디오, 터치 조작, GCController는 아직 구현하지 않았습니다.
루트의 데스크톱 CMake 타깃과 독립적이며 ROM 리소스를 포함하지 않습니다.

macOS + Xcode에서 수행할 다음 검증 명령 (이 작업에서는 미실행):

```sh
cmake -S platform/ios -B build-ios-simulator -G Xcode \
  -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT=iphonesimulator
cmake --build build-ios-simulator --config Debug -- \
  CODE_SIGNING_ALLOWED=NO
```

실기기 빌드/설치는 별도의 Apple 개발 서명이 필요합니다. 인증서/프로파일을 커밋하지 않습니다.
이 골격의 clear 패스는 Model 2 Metal 백엔드 완성을 의미하지 않습니다.
상세 단계와 기준은 ../../docs/ios/PLAN.md를 참조하세요.
