#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
for tool in cmake cc python3; do
  command -v "$tool" >/dev/null || { echo "Missing prerequisite: $tool" >&2; exit 1; }
done
# Compile only. Never run the game or invoke ROM extraction targets here.
cmake -S . -B build/cloud -DCMAKE_BUILD_TYPE=Debug
cmake --build build/cloud --target lift-check --parallel 2
