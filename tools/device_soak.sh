#!/usr/bin/env bash
# Self-playing soak test on a connected iPhone. Uses an isolated save (Autoplay.SAVE).
# Usage: tools/device_soak.sh <device-id> [minutes] [output.csv]
set -euo pipefail
DEVICE="$1"; MINUTES="${2:-12}"; OUT="${3:-device-soak.csv}"
BUNDLE=com.serhansari.passportrun
TMP="$(mktemp -d)"
echo "{\"minutes\": $MINUTES}" > "$TMP/autoplay.json"
copy() { xcrun devicectl device copy "$1" --device "$DEVICE" --domain-type appDataContainer --domain-identifier "$BUNDLE" "${@:2}" --timeout 30 >/dev/null; }
copy to --source "$TMP/autoplay.json" --destination Documents/autoplay.json
xcrun devicectl device process launch --terminate-existing --device "$DEVICE" "$BUNDLE" --timeout 60 >/dev/null
echo "Soaking for $MINUTES minutes; keep the phone unlocked and on power."
deadline=$((SECONDS + MINUTES * 60 + 120))
# Autoplay deletes its trigger and quits when finished.
while [ $SECONDS -lt $deadline ] && xcrun devicectl device info processes --device "$DEVICE" 2>/dev/null | grep -q PassportRun.app; do sleep 30; done
copy from --source Documents/autoplay-profile.json.perf.csv --destination "$OUT"
echo "Saved $OUT"
