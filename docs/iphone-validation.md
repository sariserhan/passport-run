# iPhone validation — continuation on macOS

## Current evidence (2026-10-02)

Godot 4.5.2 standard is installed at `/Applications/Godot.app`. Its matching iOS export template is installed in the user's Godot export-template directory. Xcode is selected and reports a paired available physical iPhone (`iPhone15,2`). This is detection only; the game has **not** been installed or tested on that phone.

The inherited four headless suites passed on this Mac. After the layout changes, all five suites passed: core 1,143; scene 149; progression 3,487; modes 346; mobile UI 20. Rendered modes passed at 375×667 (348 checks), including real local share-card generation. The mobile UI suite also passed rendered at 480×900, 390×844, 375×667, and 320×568. These are desktop window sizes, not physical-device acceptance.

Safe-area padding now initializes on startup and updates on resize for both menu and HUD. It converts physical screen pixels separately on both axes, including side insets. Pause/result dialogs use a safe-area scroll viewport, wrap text, fit narrow screens, and scroll to focused actions. Initial focus goes to the first action. The mobile test covers retina notch/home-indicator conversion, side insets, unavailable display geometry, startup padding, narrow cards, and reaching the last action in a long dialog.

`export_presets.cfg` contains an iPhone-only, ARM64, Xcode-project-only preset. Runtime export includes all runtime resources (including dynamically loaded difficulty presets), excluding test scripts, QA screenshots, source docs, reference images, and transfer archives. `assets/icon.svg` is an original temporary passport icon. Tracking and file-sharing capabilities are disabled.

Export preflight recognizes the preset and installed template, but stops with exactly these configuration errors:

- `App Store Team ID not specified.`
- `Invalid Identifier: Identifier is missing.`

The unsigned runtime resource pack exported successfully (about 97 KiB) and launched headlessly from an empty directory, without access to source resources. Export logs confirm all four difficulty presets are included and tests/artifacts/transfer archives are excluded. This validates packaging, not native compilation.

No Team ID or bundle identifier was guessed. No Xcode project, signed app, device performance result, or TestFlight upload exists yet.

## Next action

Set the approved Apple Team ID and bundle identifier in **Project → Export → iPhone → Application**. Godot requires these values even for an Xcode-only export. Export to a fresh empty directory outside the repository, then open the generated Xcode project and select the paired phone. Use the existing Xcode account for signing.

Command-line equivalent after setting the two fields:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  --export-debug iPhone /absolute/path/to/empty/output/PassportRun.zip
```

The preset exports project files only; build/run happens in Xcode. Follow the [Godot 4.5 iOS export guide](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_ios.html) and [export option reference](https://docs.godotengine.org/en/4.5/classes/class_editorexportplatformios.html).

Run the automated checks with:

```sh
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot ./tools/check.sh
/Applications/Godot.app/Contents/MacOS/Godot --path . \
  --script tests/test_mobile_ui.gd
```

## Physical-device acceptance still required

Record the model/iOS version; cold launch; notch and home-indicator clearance on menu, ready, preview, pause, country results, failure and sharing; one-handed touch comfort; Easy/Moderate/Hard preview readability; background/foreground and lock/unlock; mute, music/effects and haptics; sustained frame times, memory and thermal behavior through repeated retries and country changes. Target 60 FPS is unverified. Native share-sheet integration remains unfinished.

Complete this validation before adding major country content, following specification section 91. Backend, ads, purchases and hosted challenge links remain at the status documented in `HANDOFF.md`.
