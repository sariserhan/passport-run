class_name ReviewPrompt
extends RefCounted

# Apple's own rating sheet (SKStoreReviewController) via ios/native/PassportReview.m.
# iOS decides whether it actually appears and caps it at three times a year; we ask
# once at each stamp milestone, only at happy moments.
const REQUEST := "user://passport-review-request"
const MILESTONES := [3, 15, 40]

static func due(profile: PlayerProfile, mode: String) -> String:
	if mode in ["kids", "tutorial", "practice"]: return ""
	for count in MILESTONES:
		var key := "review-%d" % count
		if profile.discoveries.size() >= count and key not in profile.prompts_shown: return key
	return ""

static func request() -> void:
	if OS.get_name() != "iOS": return
	var file := FileAccess.open(REQUEST, FileAccess.WRITE)
	if file: file.store_string("1")
