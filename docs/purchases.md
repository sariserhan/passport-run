# Paid route setup

Two independent non-consumable products in App Store Connect for bundle `com.serhansari.passportrun`:

| Product | Unlock |
| --- | --- |
| `com.serhansari.passportrun.special_routes` | Special Expeditions: 16 landmarks and eight fantasy destinations |
| `com.serhansari.passportrun.cinema_worlds` | Cinema Worlds: eight original movie-inspired destinations |

Create both products with their localized descriptions, prices, availability and review screenshots. Prices in the game come from Apple's product response; no price is hardcoded. Until configured, purchase buttons remain unavailable and packs locked. Each purchase unlocks only its own route.

The pinned [Godot StoreKit 2 integration v0.2](https://github.com/godot-sdk-integrations/godot-storekit2/releases/tag/v0.2), built for Godot 4.5.2, is bundled under `ios/plugins/godot-storekit2` with its license. Native StoreKit verifies transactions and current entitlements; GDScript reads that native result. No saved premium flag, passport stamp, backend passport merge or purchase-event string grants ownership. Cancelled and pending purchases stay locked. Restore explicitly calls App Store sync. Refund/expiry events remove access. Challenge codes containing either pack enforce the matching entitlement.

Desktop builds have no checkout and remain locked. Paid routes use local scores; the competitive country catalog stays unchanged. Tests simulate the native API only inside excluded test files. Real App Store sandbox purchase, restore, refund and restart testing on an unlocked iPhone remains required; a signed build alone does not prove purchases.

Official references: [current entitlement](https://developer.apple.com/documentation/storekit/product/currententitlement), [App Store sync](https://developer.apple.com/documentation/storekit/appstore/sync()), and the pinned plugin's README and Swift implementation. Context7 was unavailable in this session, so official source documentation was used.
