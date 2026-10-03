#!/usr/bin/env bash
# Release build for TestFlight/App Store.
# Without ASC_* variables: archives and exports a signed .ipa locally (no upload).
# With ASC_KEY_ID, ASC_ISSUER_ID and ASC_KEY_PATH (App Store Connect API key .p8): uploads to TestFlight.
# Usage: tools/release_iphone.sh [output-dir]
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-/private/tmp/passport-release}"
BUILD="$(date -u +%Y%m%d%H%M)" # CFBundleVersion must increase for every upload
python3 tools/export_iphone.py --release "$OUT"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD" "$OUT/PassportRun/PassportRun-Info.plist"
AUTH=()
DESTINATION=export
if [ -n "${ASC_KEY_ID:-}" ]; then
  AUTH=(-authenticationKeyPath "$ASC_KEY_PATH" -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID")
  DESTINATION=upload
fi
cat > "$OUT/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>$DESTINATION</string>
  <key>teamID</key><string>BA24C6W48D</string>
  <key>signingStyle</key><string>automatic</string>
  <key>manageAppVersionAndBuildNumber</key><false/>
</dict></plist>
PLIST
xcodebuild -project "$OUT/PassportRun.xcodeproj" -scheme PassportRun -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$OUT/PassportRun.xcarchive" -allowProvisioningUpdates ${AUTH[@]+"${AUTH[@]}"} CODE_SIGN_IDENTITY="Apple Development" archive
xcodebuild -exportArchive -archivePath "$OUT/PassportRun.xcarchive" -exportOptionsPlist "$OUT/ExportOptions.plist" \
  -exportPath "$OUT/export" -allowProvisioningUpdates ${AUTH[@]+"${AUTH[@]}"}
echo "Build $BUILD: $([ "$DESTINATION" = upload ] && echo 'uploaded to App Store Connect' || echo "$OUT/export")"
