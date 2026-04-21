#!/bin/zsh
# Boot simulator, build with a fixed DerivedData path, install, and launch (macOS).
set -euo pipefail
cd "$(dirname "$0")/.."

SIM_NAME="${LAUNCHBOX_SIM_NAME:-iPhone 17}"
BUNDLE_ID="com.csmith.LaunchBox"
DERIVED="${PWD}/build/DerivedData"

xcrun simctl boot "$SIM_NAME" 2>/dev/null || true
open -a Simulator

xcodebuild \
  -project LaunchBox.xcodeproj \
  -scheme LaunchBox \
  -destination "platform=iOS Simulator,name=$SIM_NAME" \
  -configuration Debug \
  -derivedDataPath "$DERIVED" \
  build

APP_PATH=$(find "$DERIVED" -name "LaunchBox.app" -type d -print -quit)
if [[ -z "$APP_PATH" ]]; then
  echo "Could not find LaunchBox.app under $DERIVED" >&2
  exit 1
fi

xcrun simctl install booted "$APP_PATH"
xcrun simctl launch booted "$BUNDLE_ID"
echo "Launched $BUNDLE_ID on booted simulator."
