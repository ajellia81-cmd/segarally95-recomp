# Personal iOS port workspace

- Work only in ajellia81-cmd/segarally95-recomp on ios-port or a child branch.
  Never push to upstream, open upstream PRs, or merge without an explicit request.
- Read Rules.txt and .cursor/rules/*.mdc before changing game/runtime semantics.
- Do not obtain, upload, commit, or distribute ROMs, extracted game data, or ROM-derived
  test fixtures. Never invoke rom-blocks, extraction scripts, or game run targets in cloud.
- Cloud setup: bash .codex/setup.sh. It compiles lift-check only; compilation is not
  evidence of game execution, iOS compilation, or device functionality.
- platform/ios is a standalone, asset-free app scaffold. It is not connected to
  the lifted game. Follow docs/ios/PLAN.md for staged integration and acceptance gates.
- Keep Apple signing identities, profiles and credentials out of git and cloud setup.
- Record exact commands and results. Never report Metal rendering, audio, touch,
  controllers, gameplay, or performance as tested without actual evidence.
