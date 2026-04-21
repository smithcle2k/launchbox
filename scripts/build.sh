#!/bin/zsh
# Build LaunchBox for the iOS Simulator (macOS).
# CloudKit sharing: use a Simulator (or device) signed into iCloud to exercise invite/accept flows.
set -euo pipefail
cd "$(dirname "$0")/.."

# Use an available simulator name (iPhone 16 may not exist on newer Xcode).
DEST="${LAUNCHBOX_SIM_DEST:-platform=iOS Simulator,name=iPhone 17}"

xcodebuild \
  -project LaunchBox.xcodeproj \
  -scheme LaunchBox \
  -destination "$DEST" \
  -configuration Debug \
  build

echo "Build finished."
