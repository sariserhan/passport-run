class_name AdService
extends Node

# Forced interstitial at every EVERY-th failure (memory game and Balloon Tour), shown on
# the results screen, never mid-run. Kids and tutorial never count; Remove Ads turns it
# off. Non-personalized requests and no tracking prompt; Google's consent form (EU/UK)
# runs first. Plugin calls live in admob_bridge.gd, loaded only on iOS.
const EVERY := 4
const PRODUCT_ID := "com.serhansari.passportrun.remove_ads"
# Real AdMob units live in these project settings; debug builds always use Google's
# public test units so development never requests live ads (invalid-traffic risk).
const UNIT_SETTING := "passport_run/ads/interstitial_ios"
const TEST_UNIT := "ca-app-pub-3940256099942544/4411468910"
const BANNER_SETTING := "passport_run/ads/banner_ios"
const TEST_BANNER := "ca-app-pub-3940256099942544/2435281174" # Google's adaptive-banner test unit

signal finished
signal banner_resized(pixels: int) # 0 when hidden; the menu pads its bottom by this
var remove_ads: RoutePurchase
var failures := 0
var showing := false
var ads_seen := 0 # full-screen ads closed this session
var last_due := false # whether the latest failure was due an ad (testable off-device)
var bridge: RefCounted
var banner_wanted := false

func _ready() -> void:
	if OS.get_name() != "iOS": return
	bridge = load("res://scripts/core/admob_bridge.gd").new()
	bridge.closed.connect(func(): showing = false; ads_seen += 1; finished.emit())
	bridge.banner_resized.connect(func(pixels: int): banner_resized.emit(pixels))
	bridge.begin()

static func unit_id(setting: String, test_unit: String) -> String:
	return test_unit if OS.is_debug_build() else str(ProjectSettings.get_setting(setting, test_unit))

# Returns true when an ad is now covering the screen; `finished` fires when it closes.
func note_failure(mode: String) -> bool:
	last_due = false
	if mode in ["kids", "tutorial"] or (remove_ads and remove_ads.unlocked): return false
	failures += 1
	last_due = failures % EVERY == 0
	if not last_due or showing or not bridge or not bridge.ready_to_show(): return false # never block the player
	showing = true
	bridge.show()
	return true

# Banners belong on menu screens only: never during play, results or Kids Mode, and
# never after Remove Ads. The caller passes whether a menu screen is showing.
func set_menu_banner(menu_showing: bool) -> void:
	var wanted := menu_showing and not (remove_ads and remove_ads.unlocked)
	if wanted == banner_wanted: return
	banner_wanted = wanted
	if bridge:
		if wanted: bridge.show_banner()
		else: bridge.hide_banner()

func privacy_options_required() -> bool:
	return bridge != null and bridge.privacy_options_required()

func show_privacy_options() -> void:
	if bridge: bridge.show_privacy_options()
