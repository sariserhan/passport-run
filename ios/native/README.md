# iPhone challenge links

Run `python3 tools/export_iphone.py /private/tmp/passport-native-travel-expansion` before building the generated Xcode project. The exporter preserves Godot's generated StoreKit registration, adds the small Objective-C URL receiver and registers `passport-run://challenge/…`.

The receiver writes one pending link into Documents; Godot reads it through `user://passport-challenge.txt` and opens the existing review/import screen. Godot's [Apple embedded source](https://github.com/godotengine/godot/blob/4.5/drivers/apple_embedded/os_apple_embedded.mm) maps user data to Documents. Other URL schemes retain the original delegate handler.

Device acceptance remains pending: open a copied challenge link with the app closed, then with it already running; review and play both imports. Check malformed links and a paid-route link without ownership. These are installed-app links, not hosted web or universal links.
