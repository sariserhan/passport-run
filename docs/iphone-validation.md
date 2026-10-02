# iPhone validation — 2026-10-02

## Native evidence

Godot 4.5.2 standard and its matching iOS template are installed. Xcode detects a paired iPhone15,2. The existing Apple development certificate's OU confirmed Team ID `BA24C6W48D`. The development bundle is `com.serhansari.passportrun`; no private credentials are committed.

Godot export succeeded. Unsigned Xcode compilation and a development-signed generic iPhone build both succeeded. Automatic development provisioning used the Mac's existing account. No App Store/TestFlight upload occurred.

The device-specific build could not start because Xcode reported: **“Ssari phone needs to be unlocked to enable development services.”** No installation, launch, physical-device performance or human acceptance PASS is claimed.

The iPhone-only ARM64 preset exports an Xcode project. Mobile ETC2/ASTC texture import is enabled; iOS minimum is 15.0 because this Xcode rejects Godot's default 14.0. Backend sources, tests, docs, screenshots and reference images are excluded from runtime packaging. Tracking and file-sharing capabilities are disabled. Online URL defaults empty, so the native build is offline.

The most recent exported project and signed development app are temporary local artifacts; do not assume `/private/tmp` survives cleanup. Regenerate with:

```sh
mkdir -p /private/tmp/passport-native-final
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  --export-debug iPhone /private/tmp/passport-native-final/PassportRun.zip
xcodebuild -project /private/tmp/passport-native-final/PassportRun.xcodeproj \
  -scheme PassportRun -configuration Debug -destination 'generic/platform=iOS' \
  -derivedDataPath /private/tmp/passport-native-final/build \
  -allowProvisioningUpdates build
```

After the phone is unlocked, open this Xcode project, select the paired phone, and Run. Signed build artifacts live under the selected derived-data `Build/Products/Debug-iphoneos/PassportRun.app`. Follow the [Godot iOS export guide](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_ios.html).

## Desktop verification

Six headless suites passed (5,165 checks) plus 3 reporting tests. Real local Godot/backend integration passed 16 checks; backend types and 144 tests passed. Rendered modes passed at 375×667 and 390×844; long safe-area dialogs also passed down to 320×568.

Menu/HUD safe areas convert physical pixels separately on both axes, including side insets. Results and pause dialogs wrap and scroll, focus remains readable, and primary actions receive focus. The original illustrated share card and Kids reward were visually inspected. These are desktop UI checks, not iPhone profiling.

## Physical acceptance still required

Record model/iOS, cold launch, safe-area clearance on every screen, one-handed taps, all difficulty previews (especially Hard's 20 rows in 2 seconds), lock/focus/background/resume, sound/mute/haptics, sustained frame times, repeated-retry memory and thermal behavior. Target 60 FPS remains unverified. Native share-sheet integration is unfinished.

Keep the five-country scope until validation supports expansion (spec section 91). See [build status](build-status.md) and [backend setup](../backend/README.md) for service limitations.
