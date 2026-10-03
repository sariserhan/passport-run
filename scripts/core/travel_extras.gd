class_name TravelExtras
extends RefCounted

const CITIES := {
 "paris": {"name": "Paris · Riverside lights", "country": "FR", "layout": "bridge", "keepsake": "Mini riverside lantern", "color": "e8bf85"},
 "kyoto": {"name": "Kyoto · Garden walk", "country": "JP", "layout": "curve", "keepsake": "Garden wind chime", "color": "e9a9bc"},
 "new_york": {"name": "New York · Skyline steps", "country": "US", "layout": "climb", "keepsake": "Skyline snow globe", "color": "85c5e8"},
}
const LANDMARKS := {
 "eiffel": {"name": "Eiffel Tower climb", "country": "FR", "layout": "climb", "rows": 8, "keepsake": "Tower pennant"},
 "fuji": {"name": "Mount Fuji ascent", "country": "JP", "layout": "climb", "rows": 12, "keepsake": "Mountain medallion"},
 "pyramids": {"name": "Pyramid passage", "country": "EG", "layout": "bridge", "rows": 9, "keepsake": "Sandstone charm"},
}
const TRANSPORT := {
 "train": {"name": "Alpine train", "country": "CH", "layout": "classic", "keepsake": "Railway ticket"},
 "boat": {"name": "Venice boat", "country": "IT", "layout": "bridge", "keepsake": "Little wooden boat"},
 "tram": {"name": "Lisbon tram", "country": "PT", "layout": "curve", "keepsake": "Yellow tram model"},
 "cable_car": {"name": "Norwegian cable car", "country": "NO", "layout": "climb", "keepsake": "Mountain lift badge"},
}
const SECRETS := {
 "garden": {"name": "Hidden garden viewpoint", "country": "JP", "requires": "kyoto", "layout": "curve", "keepsake": "Secret garden blossom"},
 "rooftop": {"name": "Riverside rooftop", "country": "FR", "requires": "paris", "layout": "climb", "keepsake": "Rooftop telescope"},
 "harbor": {"name": "Quiet harbor lookout", "country": "US", "requires": "new_york", "layout": "bridge", "keepsake": "Harbor compass"},
}
const FESTIVALS := [
 {"name": "Lantern evenings", "route": ["JP", "KR"], "keepsake": "Festival lantern", "color": "ffa55c"},
 {"name": "Winter lights", "route": ["NO", "FI"], "keepsake": "Snowflake mobile", "color": "89d7ed"},
 {"name": "Summer music", "route": ["FR", "ES"], "keepsake": "Tiny festival drum", "color": "e4a4ce"},
]
const CHARACTERS := {
 "mira": {"name": "Mira the mapmaker", "story": "My maps have empty corners. Bring me memories of France and Japan and we will draw a new one together.", "route": ["FR", "JP"], "reward": "Mira’s illustrated map"},
 "leo": {"name": "Leo the conductor", "story": "Every ticket tells a story. Travel through Switzerland and Italy, then come back for a ticket to remember.", "route": ["CH", "IT"], "reward": "Leo’s golden ticket"},
 "nia": {"name": "Nia the gardener", "story": "Snow and sunshine both make a garden. Visit Norway and Portugal to help me choose plants for my next garden.", "route": ["NO", "PT"], "reward": "Nia’s travel terrarium"},
}
const RECIPES := {
 "lantern": {"name": "Postcard lantern", "cost": 3, "countries": ["FR"], "color": "ffcd75"},
 "mobile": {"name": "Journey star mobile", "cost": 5, "countries": ["JP", "US"], "color": "8fd2e6"},
 "terrarium": {"name": "World garden terrarium", "cost": 4, "countries": ["NO", "PT"], "color": "9cc98c"},
}
const PAGES := [["cities", "City stops"], ["branches", "Choose my journey"], ["landmarks", "Landmark challenges"], ["transport", "Local transport"], ["secrets", "Hidden scenic routes"], ["festivals", "Travel festivals"], ["characters", "Traveling characters"], ["crafting", "Souvenir workshop"], ["presets", "Room design presets"], ["globe", "Interactive globe"], ["recaps", "Journey movies"], ["multiplayer", "Take turns together"], ["friendly", "Friendly challenge codes"], ["accessibility", "Accessibility"], ["backup", "Offline passport backup"]]

static func festival_key() -> String:
 return GameCatalog.today_utc().left(7)
static func festival() -> Dictionary:
 return FESTIVALS[posmod(int(festival_key().right(2)) - 1, FESTIVALS.size())].duplicate(true)
static func catalog(kind: String) -> Dictionary:
 return {"city": CITIES, "landmark": LANDMARKS, "transport": TRANSPORT, "secret": SECRETS}.get(kind, {})
static func stage(kind: String, key: String) -> Dictionary:
 return catalog(kind).get(key, {}).duplicate(true)
static func unlocked(profile: PlayerProfile, kind: String, key: String) -> bool:
 var entry := stage(kind, key)
 if entry.is_empty() or not profile.can_visit(entry.country): return false
 return kind != "secret" or "city:" + entry.requires in profile.extras.completed
static func clean(raw: Variant) -> Dictionary:
 var value := {"completed": [], "materials": 0, "crafted": [], "ornament": "none", "characters": {}, "presets": [], "recaps": []}
 if not raw is Dictionary: return value
 if raw.get("materials") is int or raw.get("materials") is float: value.materials = clampi(int(raw.materials), 0, 999)
 if raw.get("crafted") is Array:
  for key in raw.crafted:
   if key is String and key in RECIPES and key not in value.crafted: value.crafted.append(key)
 if raw.get("ornament") in value.crafted: value.ornament = raw.ornament
 if raw.get("completed") is Array:
  for token in raw.completed.slice(0, 256):
   if not token is String or token in value.completed: continue
   var parts: PackedStringArray = token.split(":")
   if parts.size() == 2 and parts[1] in catalog(parts[0]) or token.begins_with("festival:") and token.length() == 16: value.completed.append(token)
 if raw.get("characters") is Dictionary:
  for key in CHARACTERS:
   var request: Variant = raw.characters.get(key)
   if request is Dictionary:
    var ids: Array = []
    if request.get("countries") is Array:
     for id in request.countries:
      if id in CHARACTERS[key].route and id not in ids: ids.append(id)
    value.characters[key] = {"countries": ids, "rewarded": ids.size() == CHARACTERS[key].route.size()}
 if raw.get("presets") is Array:
  for item in raw.presets.slice(0, 6):
   if item is Dictionary: value.presets.append({"name": str(item.get("name", "My room")).left(32), "room": clean_room(item.get("room")), "ornament": item.get("ornament", "none") if item.get("ornament") in value.crafted else "none"})
 if raw.get("recaps") is Array:
  for recap in raw.recaps.slice(-10):
   if not recap is Dictionary or not recap.get("route") is Array: continue
   var ids: Array = recap.route.filter(func(id): return id is String and id in GameCatalog.DESTINATIONS).slice(0, 300)
   if not ids.is_empty(): value.recaps.append({"name": str(recap.get("name", "My journey")).left(64), "date": str(recap.get("date", "")).left(10), "route": ids, "tiles": clampi(int(recap.get("tiles", 0)) if recap.get("tiles") is int or recap.get("tiles") is float else 0, 0, 10000000)})
 return value
static func clean_room(raw: Variant) -> Dictionary:
 var value := {"display": [], "postcards": [], "decor": RoomDecor.DEFAULTS.duplicate(), "positions": {}}
 if not raw is Dictionary: return value
 for field in ["display", "postcards"]:
  if raw.get(field) is Array:
   for id in raw[field].slice(0, 6 if field == "display" else 3):
    if id is String and id in GameCatalog.DESTINATIONS and id not in value[field]: value[field].append(id)
 if raw.get("decor") is Dictionary:
  for key in RoomDecor.DEFAULTS:
   if raw.decor.get(key) in RoomDecor.ITEMS[key]: value.decor[key] = raw.decor[key]
 if raw.get("positions") is Dictionary:
  for id in value.display:
   var point: Variant = raw.positions.get(id)
   if point is Array and point.size() == 2 and point.all(func(n): return (n is int or n is float) and is_finite(float(n))): value.positions[id] = [clampf(point[0], 0, 1), clampf(point[1], 0, 1)]
 return value
