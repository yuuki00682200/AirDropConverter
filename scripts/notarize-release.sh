#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
task_notary_profile="${1:?Usage: ./scripts/notarize-release.sh KEYCHAIN_PROFILE}"
task_signing_identity="${SIGNING_IDENTITY:-Developer ID Application: MEMEMAKER, K.K. (JUBC2Y3XJ7)}"
task_app_path="build/Build/Products/Release/AirDropConverter.app"
task_version="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$task_app_path/Contents/Info.plist")"
task_zip_path="build/AirDropConverter-v${task_version}.zip"
codesign --force --options runtime --timestamp --sign "$task_signing_identity" "$task_app_path"
codesign --verify --strict "$task_app_path"
ditto -c -k --sequesterRsrc --keepParent "$task_app_path" "$task_zip_path"
xcrun notarytool submit "$task_zip_path" --keychain-profile "$task_notary_profile" \
  --wait --output-format json > build/notarization-result.json
python3 - <<'PY'
import json
from pathlib import Path
result = json.loads(Path("build/notarization-result.json").read_text())
print("Notarization:", result.get("id"), result.get("status"))
if result.get("status") != "Accepted":
    raise SystemExit("Notarization was not accepted. Inspect build/notarization-result.json before publishing.")
PY
xcrun stapler staple "$task_app_path"
xcrun stapler validate "$task_app_path"
codesign --verify --strict "$task_app_path"
spctl --assess --type execute --verbose=2 "$task_app_path"
ditto -c -k --sequesterRsrc --keepParent "$task_app_path" "$task_zip_path"
(
  cd build
  shasum -a 256 "AirDropConverter-v${task_version}.zip" > SHA256SUMS.txt
)
echo "Ready for GitHub Releases: $task_zip_path and build/SHA256SUMS.txt"
