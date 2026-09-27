#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
xcodebuild -project AirDropConverter.xcodeproj -scheme AirDropConverter \
  -configuration Release -derivedDataPath build CODE_SIGNING_ALLOWED=NO \
  'ARCHS=arm64 x86_64' ONLY_ACTIVE_ARCH=NO build
task_app_path="build/Build/Products/Release/AirDropConverter.app"
codesign --force --sign - "$task_app_path"
codesign --verify --strict "$task_app_path"
ditto -c -k --sequesterRsrc --keepParent "$task_app_path" build/AirDropConverter-local.zip
echo "Created build/AirDropConverter-local.zip (ad-hoc signed, not notarized)"
