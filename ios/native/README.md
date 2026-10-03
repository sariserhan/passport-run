# iPhone challenge links

Run `python3 tools/export_iphone.py /private/tmp/passport-native-travel-expansion` before building the generated Xcode project. The exporter preserves Godot's generated StoreKit registration, adds the small Objective-C URL receiver and registers `passport-run://challenge/…`.

The receiver writes one pending link into Documents; Godot reads it through `user://passport-challenge.txt` and opens the existing review/import screen. Godot's [Apple embedded source](https://github.com/godotengine/godot/blob/4.5/drivers/apple_embedded/os_apple_embedded.mm) maps user data to Documents. Other URL schemes retain the original delegate handler.

Device acceptance remains pending: open a copied challenge link with the app closed, then with it already running; review and play both imports. Check malformed links and a paid-route link without ownership. These are installed-app links, not hosted web or universal links.


## Picture sharing

The exporter also includes `PassportShare.m`. After Godot exports a room, album page or journal postcard, it atomically writes a short request in `user://passport-share-request.json`. The native bridge polls while the app is active, accepts only the five known picture filenames, rejects expired/oversized requests, and opens Apple's [UIActivityViewController](https://developer.apple.com/documentation/uikit/uiactivityviewcontroller) with the rendered image. It anchors the popover for iPad, reports presentation/cancellation/completion, and leaves the original PNG saved. The bridge does not expose profile files or upload anything itself.

Run `python3 tools/check_iphone_sharing.py` to compile and launch the exact bridge in an isolated temporary iPhone simulator. The test verifies presentation and cancellation and removes its simulator afterward. `python3 tests/test_iphone_export.py` checks that exporter integration preserves StoreKit registration and challenge links.

Physical-device acceptance: export through `tools/export_iphone.py`, install the resulting Xcode build, then share room, album, journal, photo and scrapbook pictures. Check cancellation, sharing again, saving to Photos and returning to gameplay. Recipient delivery requires choosing and confirming a destination in the system share sheet.

The batch also includes `tools/check_iphone_sharing_device.py`, which accepts an explicitly selected paired device and an existing provisioning profile. It compiles a separate sharing test app, verifies presentation/cancellation-handler execution on the phone, and uninstalls that test app. No production app or profile is replaced. The iPhone 14 Pro check passed on 2026-10-03.

The new journeys batch adds `passport-run-movie.gif` and `passport-run-backup.json` to the share whitelist. These are shared as file URLs so the original animated movie and portable backup survive export. The isolated native smoke app tests picture, backup, and movie presentation and cancellation; it does not send them to a recipient.
