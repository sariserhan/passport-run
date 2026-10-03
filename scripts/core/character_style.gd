class_name CharacterStyle
extends RefCounted

const OUTFITS := {"classic": {"name": "Classic Explorer", "count": 0, "color": "ffffff"}, "trail": {"name": "Forest Trail", "count": 3, "color": "d3f1de"}, "polar": {"name": "Polar Explorer", "count": 10, "color": "d5eaff"}, "cosmic": {"name": "Cosmic Explorer", "count": 25, "color": "eedcff"}}
const HATS := {"none": {"name": "No Hat", "count": 0}, "sun": {"name": "Sun Hat", "count": 3}, "winter": {"name": "Winter Hat", "count": 10}, "space": {"name": "Space Cap", "count": 25}}
const BACKPACKS := {"classic": "b58147", "europe": "964d42", "asia": "276e62", "americas": "285f86"}

static func unlocked(kind: String, id: String, discoveries: Array[String]) -> bool:
 if kind == "backpack": return id in TravelGoals.earned_covers(discoveries)
 var items: Dictionary = OUTFITS if kind == "outfit" else HATS
 return id in items and discoveries.size() >= items[id].count
