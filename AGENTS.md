# Personal iOS port workspace

- Work only in ajellia81-cmd/segarally95-recomp on ios-port or a child branch.
  Never push to upstream, open upstream PRs, or merge without an explicit request.
- Read Rules.txt and .cursor/rules/*.mdc before changing game/runtime semantics.
- Do not obtain, upload, commit, or distribute ROMs, extracted game data, or ROM-derived
  test fixtures. Never invoke rom-blocks, extraction scripts, or game run targets in cloud.
- Cloud setup: bash .codex/setup.sh. It compiles lift-check only; compilation is not
  evidence of game execution, iOS compilation, or device functionality.
- platform/ios is an asset-free native app linked to the lifted core. Configure
  the repository root with CMAKE_SYSTEM_NAME=iOS. Follow platform/ios/README.md.
- User authorized an unsigned personal-use IPA build on 2026-10-22. Package only
  the asset-free app; no Apple signing, App Store release, ROMs or game data.
  Store the IPA as a short-lived Actions artifact for user download, not a release.
- Default scripts/ios-readiness.sh stops at Xcode project generation. The opt-in
  --compile-check compiles an unsigned app; neither mode creates an IPA.
- Keep Apple signing identities, profiles and credentials out of git and cloud setup.
- Record exact commands and results. Never report Metal rendering, audio, touch,
  controllers, gameplay, or performance as tested without actual evidence.
