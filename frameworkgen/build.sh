#!/usr/bin/env bash
set -euo pipefail

IOS="$(cd "$(dirname "$0")/.." && pwd)"
LIB="$IOS/frameworkgen/lib"
cd "$IOS"

pod_install() {
  if bundle check >/dev/null 2>&1; then bundle exec pod install; else pod install; fi
}

step() {
  case "$1" in
    bootstrap)
      [ -d "$IOS/../node_modules/react-native" ] || { echo "Run yarn install in $(cd "$IOS/.." && pwd) first." >&2; exit 1; }
      xcodegen generate --quiet
      pod_install
      ruby "$LIB/stage.rb" vendor
      ;;
    archive) ruby "$LIB/archive.rb" ;;
    xcframework) ruby "$LIB/xcframework.rb" ;;
    stage) ruby "$LIB/stage.rb" artifacts ;;
    guards) ruby "$LIB/guards.rb" ;;
    package) ruby "$LIB/package.rb" ;;
    render) ruby "$LIB/render_package.rb" ;;
    verify) ruby "$IOS/frameworkgen/verify/verify.rb" ;;
    all) for s in bootstrap archive xcframework stage guards package render; do step "$s"; done ;;
    *) echo "usage: $0 [bootstrap|archive|xcframework|stage|guards|package|render|verify|all]..." >&2; exit 64 ;;
  esac
}

[ $# -gt 0 ] || set -- all
for s in "$@"; do step "$s"; done
