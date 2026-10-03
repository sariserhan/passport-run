class_name CharacterStyle
extends RefCounted

const OUTFITS := {"classic": {"name": "Classic Explorer", "count": 0, "color": "ffffff"}, "trail": {"name": "Forest Trail", "count": 3, "color": "d3f1de"}, "polar": {"name": "Polar Explorer", "count": 10, "color": "d5eaff"}, "cosmic": {"name": "Cosmic Explorer", "count": 25, "color": "eedcff"}, "balloon_gold": {"name": "Golden Balloon Explorer", "badge": "arcade:clean_boss", "color": "ffe0a0"}, "balloon_sky": {"name": "Sky Balloon Explorer", "badge": "arcade:100_pops", "color": "aedcff"}, "balloon_shadow": {"name": "Twilight Balloon Explorer", "badge": "arcade:no_drops", "color": "dfc5f0"}}
const HATS := {"none": {"name": "No Hat", "count": 0}, "sun": {"name": "Sun Hat", "count": 3}, "winter": {"name": "Winter Hat", "count": 10}, "space": {"name": "Space Cap", "count": 25}}
const BACKPACKS := {"classic": "b58147", "europe": "964d42", "asia": "276e62", "americas": "285f86"}

static func unlocked(kind: String, id: String, discoveries: Array[String], badges: Array[String] = []) -> bool:
 if kind == "backpack": return id in TravelGoals.earned_covers(discoveries)
 var items: Dictionary = OUTFITS if kind == "outfit" else HATS
 if id not in items: return false
 if items[id].has("badge"): return items[id].badge in badges
 return discoveries.size() >= items[id].count
