class_name AdService
extends Node

# Forced interstitial at every EVERY-th failure (memory game and Balloon Tour), shown on
# the results screen, never mid-run. Kids and tutorial never count; Remove Ads turns it
# off. Non-personalized requests and no tracking prompt; Google's consent form (EU/UK)
# runs first. Plugin calls live in admob_bridge.gd, loaded only on iOS.
const EVERY := 4
const PRODUCT_ID := "com.serhansari.passportrun.remove_ads"
# Google's public test unit until the real AdMob unit goes in this project setting.
const UNIT_SETTING := "passport_run/ads/interstitial_ios"
const TEST_UNIT := "ca-app-pub-3940256099942544/4411468910"

signal finished
var remove_ads: RoutePurchase
var failures := 0
var showing := false
var last_due := false # whether the latest failure was due an ad (testable off-device)
var bridge: RefCounted

func _ready() -> void:
	if OS.get_name() != "iOS": return
	bridge = load("res://scripts/core/admob_bridge.gd").new()
	bridge.closed.connect(func(): showing = false; finished.emit())
	bridge.begin()

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

func privacy_options_required() -> bool:
	return bridge != null and bridge.privacy_options_required()

func show_privacy_options() -> void:
	if bridge: bridge.show_privacy_options()
