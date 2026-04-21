#!/bin/zsh
# Capture basic simulator screenshots after install/launch (macOS).
# Usage: from repo root: chmod +x scripts/screenshots.sh && ./scripts/screenshots.sh
# Optional: export LAUNCHBOX_SIMS='iPhone 17|iPhone 17 Pro|iPad (A16)'
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ -n "${LAUNCHBOX_SIMS:-}" ]]; then
  SIMPL=(${(s:|:)LAUNCHBOX_SIMS})
else
  SIMPL=( "iPhone 17" "iPhone 17 Pro" "iPad (A16)" )
fi
BUNDLE_ID="com.csmith.LaunchBox"
DERIVED="${ROOT}/build/DerivedData"
OUT="${ROOT}/artifacts/shots"

mkdir -p "$OUT"

for SIM_NAME in $SIMPL; do
  echo "== Device: $SIM_NAME =="
  xcrun simctl boot "$SIM_NAME" 2>/dev/null || true
  open -a Simulator 2>/dev/null || true

  xcodebuild \
    -project LaunchBox.xcodeproj \
    -scheme LaunchBox \
    -destination "platform=iOS Simulator,name=$SIM_NAME" \
    -configuration Debug \
    -derivedDataPath "$DERIVED" \
    CODE_SIGNING_ALLOWED=NO \
    build

  APP_PATH=$(find "$DERIVED" -name "LaunchBox.app" -type d -print -quit)
  xcrun simctl install booted "$APP_PATH"
  xcrun simctl launch booted "$BUNDLE_ID" || true

  sleep 3
  safe=$(echo "$SIM_NAME" | tr ' ' '-')
  xcrun simctl io booted screenshot "${OUT}/${safe}-01-after-launch.png"

  echo "  → (manual) open History, then wait…"
  sleep 5
  xcrun simctl io booted screenshot "${OUT}/${safe}-02-history-or-chores.png"

  echo "  → (manual) open Settings…"
  sleep 5
  xcrun simctl io booted screenshot "${OUT}/${safe}-03-settings.png"

  sleep 5
  xcrun simctl io booted screenshot "${OUT}/${safe}-04-extra.png"
done

echo "Screenshots in $OUT (default: 6.1\", 6.7\" class, and iPad)."
