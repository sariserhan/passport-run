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

Six headless suites passed (over 5,180 checks after the graphics update) plus 3 reporting tests. Real local Godot/backend integration passed 16 checks; backend types and 144 tests passed. Rendered modes passed at 375×667 and 390×844; long safe-area dialogs also passed down to 320×568.

Menu/HUD safe areas convert physical pixels separately on both axes, including side insets. Results and pause dialogs wrap and scroll, focus remains readable, and primary actions receive focus. The original illustrated share card and Kids reward were visually inspected. These are desktop UI checks, not iPhone profiling.

## Physical acceptance still required

Record model/iOS, cold launch, safe-area clearance on every screen, one-handed taps, all difficulty previews (especially Hard's 20 rows in 2 seconds), lock/focus/background/resume, sound/mute/haptics, sustained frame times, repeated-retry memory and thermal behavior. Target 60 FPS remains unverified. Native share-sheet integration is unfinished.

The user explicitly approved broad destination expansion on 2026-10-02; native acceptance must now include large destination lists and regional scenery. See [build status](build-status.md) and [backend setup](../backend/README.md) for service limitations.

## Reference graphics update

The updated native export packages five destination backdrops, menu key art, a transparent backpacker and the licensed Lilita One font. Desktop QA now exercises perspective preview/follow cameras and rounded stone meshes. Scene checks increased to 156; mode checks include bounded state waits and explicit preview readiness. See [visual assets](visual-assets.md). The latest export/build directory is `/private/tmp/passport-native-visual`. No physical-device acceptance is inferred from this visual pass.

## Animation and deadline update

The newest exported/signed project is `/private/tmp/passport-native-animated`. It includes the 16-pose backpacker atlas, passport animation and balance-v2 10-second per-row deadline. The attempted physical-phone install reported that the device was still locked. Animation checks passed headlessly and rendered (36), and real online integration passed 19 checks, including an actual 10-second timeout. No physical-device animation/FPS PASS is claimed.

### 197-destination native pass

Latest project: `/private/tmp/passport-native-world/PassportRun.xcodeproj`. Export includes the shared JSON catalog, geography license/source, five original backdrop paintings and the sixteen-scene world atlas. Signed generic-iPhone build succeeded. Resource-pack loading verifies all 197 destination textures. The new country scenes and Dubai search/passport/sticker UI were captured at 390×844 (`artifacts/destination-*.png`, `29-dubai-search.png` through `31-dubai-sticker.png`). Physical-device install/performance acceptance remains pending.

## Paid routes native continuation — 2026-10-02

Latest exported project: `/private/tmp/passport-native-cinema/PassportRun.xcodeproj`; signed app: `/private/tmp/passport-native-cinema/build/Build/Products/Debug-iphoneos/PassportRun.app`. Generic-iPhone Xcode build succeeded with the pinned StoreKit 2 plugin linked. Exported resource-pack loading verifies 282 destination records, every backdrop, geography source and license. Free travel includes 250 countries/territories; Special Expeditions has 24 paid locations and Cinema Worlds eight under a separate product. Tests and screenshots are excluded from the native pack.

Final desktop checks: 10,427 Godot assertions across eight suites, three Python report tests, backend typecheck and 155 backend tests. The 2,630 destination/payment assertions also passed rendered at 390×844. Real local HTTP smoke and 19 Godot/backend integration assertions passed. Live App Store products, purchase/restore/refund device acceptance, phone installation and FPS validation remain pending. The paired phone was previously locked; no new physical-device acceptance is claimed.
