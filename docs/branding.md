# Passport Run app branding

The app icon and matching splash screen were created with the built-in imagegen tool. The selected artwork lives in the project; exports do not depend on the generation cache.

- `assets/branding/icon-source.png`: original square illustration.
- `assets/branding/app-icon.png`: opaque 1024×1024 App Store and Godot icon.
- `assets/branding/ios-icon-*.png`: iPhone, iPad, notification, settings, and Spotlight sizes.
- `assets/branding/PassportRun.iconset` and `PassportRun.icns`: macOS icon assets.
- `assets/branding/splash-screen.png`: matching portrait launch illustration and title.

`tools/build_brand_assets.gd` creates packaging sizes using Godot’s image resampler. Rebuild with `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/build_brand_assets.gd`, then `iconutil -c icns assets/branding/PassportRun.iconset -o assets/branding/PassportRun.icns` on macOS.

`project.godot` uses the new window icon, macOS native icon, and boot splash. `export_presets.cfg` assigns all iOS icon sizes and both launch image scales. The native launch screen uses aspect fit, keeping the title visible in different screen shapes.

## Verification

The exported Xcode project at `/private/tmp/passport-native-branding/PassportRun.xcodeproj` contains 16 opaque native icon entries. Its 1024-pixel icon matches the selected source; both native splash files match the selected launch artwork. The launch storyboard contains `scaleAspectFit` and no unresolved template placeholders. The unsigned iPhone Debug build succeeded, compiling the asset catalog and launch storyboard. This verifies build packaging, not physical-phone installation or launch.

## Final prompts

App icon:

> Use case: logo-brand. Create a single finished square full-bleed mobile game app icon for Passport Run, a travel and memory-path jumping game. Premium polished tactile 3D illustration, clean bold silhouette legible at tiny home-screen size. A deep teal passport with a simple warm-gold embossed globe, resting at a slight dynamic angle, with a small ascending trail of three chunky stepping tiles behind it that suggests jumping across the world. Warm cream page edges, subtle gold sunlight, restrained deep navy/teal background filling every corner. Central composition, strong visual hierarchy, generous safe margins for iOS rounding. Match an inviting travel-adventure game. No text, no letters, no border, no pre-rounded corners, no phone mockup, no watermarks, no extra objects. Output one square opaque image, not an asset grid. The same artwork will be used centered on the launch splash.

Splash, using the selected icon as its reference:

> Create a finished portrait launch/splash screen for Passport Run using the attached app icon as the exact visual identity reference. Retain its tactile teal passport with embossed golden globe and three chunky world-map stepping tiles, but compose them as a smaller central emblem in a spacious very dark navy travel-night backdrop. Portrait tall phone composition, no mockup, full bleed. Upper 20 percent and bottom 20 percent calm deep navy negative space. Passport emblem centered around the middle, occupies at most 60 percent of total image width so it fits small phones and iPads. Beneath it, centered elegant bold warm-cream title with exact text 'PASSPORT RUN', two lines PASSPORT then RUN. Smaller centered gold tagline exactly 'Remember. Jump. Explore.' Keep all lettering and emblem inside the central 60 percent of image width. Soft subtle glow, exceptionally clean polished game branding, no buttons, no loader, no app-store badges, no extra objects, no watermarks. Match the reference, readable and calm. Use tall 1:2 portrait composition if possible.
