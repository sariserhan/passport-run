class_name TravelActivities
extends RefCounted
const BUDDY_QUESTS := {
 "bird": {"name": "Pip’s Island Flight", "route": ["JP", "IS", "ID"], "reward": "Explorer scarf"},
 "robot": {"name": "Orbit’s City Scan", "route": ["FR", "US", "JP"], "reward": "Star antenna"},
 "dragon": {"name": "Ember’s Northern Nap", "route": ["NO", "FI", "CA"], "reward": "Tiny travel crown"},
}
const WEEKS := [
 {"name": "Northern Lights", "route": ["NO", "IS", "FI"], "reward": "Aurora keepsake"},
 {"name": "Island Hopping", "route": ["JP", "ID", "PH"], "reward": "Island compass"},
 {"name": "Mediterranean Memories", "route": ["FR", "IT", "ES"], "reward": "Sunset medallion"},
]
const HUNTS := [
 {"id": "FR", "clue": "Find the country whose capital is Paris.", "reward": "Eiffel treasure key"},
 {"id": "JP", "clue": "Find the country whose capital is Tokyo.", "reward": "Cherry-blossom treasure"},
 {"id": "EG", "clue": "Find the country whose capital is Cairo.", "reward": "Golden scarab treasure"},
]
const BINGO := [["countries", "Complete three destinations", 3], ["flawless", "A flawless finish", 1], ["buddy", "Travel with a buddy", 1], ["photo", "Take a travel photo", 1], ["knowledge", "Earn a knowledge sticker", 1], ["room", "Interact with your room", 1], ["mastery", "Earn silver mastery", 1], ["hunt", "Find a treasure", 1], ["expedition", "Finish a weekly expedition", 1]]
const LINES := [[0,1,2], [3,4,5], [6,7,8], [0,3,6], [1,4,7], [2,5,8], [0,4,8], [2,4,6]]
const CUSTOM_DEFAULTS := {"nickname": "Traveler", "motto": "Collect moments, travel the world.", "ink": "ruby", "weather": "clear", "time": "day", "pose": "wave", "confetti": "gold", "sound": "stamp"}

static func week_key(date: String = "") -> String:
 if date.is_empty(): date = GameCatalog.today_utc()
 var days := int(Time.get_unix_time_from_datetime_string(date + "T00:00:00")) / 86400
 return str(int(floor(float(days + 3) / 7)))

static func expedition() -> Dictionary:
 return WEEKS[posmod(int(week_key()), WEEKS.size())].duplicate(true)

static func question(id: String) -> Dictionary:
 if id not in GameCatalog.FREE_DESTINATIONS: return {}
 var country: Dictionary = GameCatalog.FREE_DESTINATIONS[id]
 var capitals: Array = country.get("capital", [])
 if capitals.is_empty(): return {}
 var answer: String = str(capitals[0])
 var options: Array[String] = [answer]
 for other in ["FR", "JP", "EG", "CA", "GB"]:
  var values: Array = GameCatalog.FREE_DESTINATIONS[other].get("capital", [])
  if not values.is_empty() and str(values[0]) not in options: options.append(str(values[0]))
  if options.size() == 3: break
 options.sort()
 return {"prompt": "Which city is a capital of " + country.name + "?", "answer": answer, "options": options}

static func clean(raw: Variant) -> Dictionary:
 var result := {"custom": CUSTOM_DEFAULTS.duplicate(), "rewards": {}, "mastery": {}, "knowledge": [], "timeline": [], "scrapbook": [], "buddy_progress": {}, "accessories": {}, "weekly": {}, "bingo": {}, "hunt": 0, "hunt_solved": false, "hunt_rewarded": false, "spaces": {}, "room": {"space": "main", "lamp": true, "seated": false, "resting": true}}
 if not raw is Dictionary: return result
 if raw.get("rewards") is Dictionary:
  for token in raw.rewards.keys().slice(0, 4096):
   if token is String and token.length() <= 96 and raw.rewards[token] is String: result.rewards[token] = raw.rewards[token].left(120)
 if raw.get("custom") is Dictionary:
  for field in CUSTOM_DEFAULTS:
   var value: Variant = raw.custom.get(field)
   if value is String:
    if field in ["nickname", "motto"]: result.custom[field] = value.strip_edges().left(32 if field == "nickname" else 80)
    elif value in {"ink": ["ruby", "jade", "ocean"], "weather": ["clear", "rain", "snow"], "time": ["day", "sunrise", "sunset", "night"], "pose": ["wave", "jump", "cheer"], "confetti": ["gold", "ocean", "forest"], "sound": ["stamp", "land", "team"]}[field]: result.custom[field] = value
 for field in ["mastery"]:
  if raw.get(field) is Dictionary:
   for id in raw[field]:
    if id is String and id in GameCatalog.DESTINATIONS and (raw[field][id] is int or raw[field][id] is float): result[field][id] = clampi(int(raw[field][id]), 0, 3)
 if raw.get("knowledge") is Array:
  for id in raw.knowledge:
   if id is String and id in GameCatalog.FREE_DESTINATIONS and id not in result.knowledge: result.knowledge.append(id)
 if raw.get("timeline") is Array:
  for event in raw.timeline.slice(-500):
   if event is Dictionary and event.get("text") is String and event.get("date") is String: result.timeline.append({"date": event.date.left(10), "text": event.text.left(160)})
 if raw.get("scrapbook") is Array:
  for page in raw.scrapbook.slice(0, 20):
   if not page is Dictionary: continue
   var ids: Array[String] = []
   if page.get("countries") is Array:
    for id in page.countries.slice(0, 4):
     if id is String and id in GameCatalog.DESTINATIONS and id not in ids: ids.append(id)
   result.scrapbook.append({"title": str(page.get("title", "My travels")).left(48), "note": str(page.get("note", "")).left(240), "countries": ids, "layout": "grid" if page.get("layout") == "grid" else "stack"})
 for field in ["hunt", "hunt_solved", "hunt_rewarded"]:
  if field == "hunt" and (raw.get(field) is int or raw.get(field) is float): result[field] = clampi(int(raw[field]), 0, HUNTS.size())
  elif field != "hunt" and raw.get(field) is bool: result[field] = raw[field]
 for friend in BUDDY_QUESTS:
  if raw.get("buddy_progress") is Dictionary and raw.buddy_progress.get(friend) is Array:
   result.buddy_progress[friend] = raw.buddy_progress[friend].filter(func(id): return id is String and id in BUDDY_QUESTS[friend].route)
  if raw.get("accessories") is Dictionary and raw.accessories.get(friend) == true: result.accessories[friend] = true
 if raw.get("weekly") is Dictionary and raw.weekly.get("week") == week_key():
  result.weekly = {"week": week_key(), "countries": [], "rewarded": raw.weekly.get("rewarded") == true}
  if raw.weekly.get("countries") is Array: result.weekly.countries = raw.weekly.countries.filter(func(id): return id is String and id in expedition().route)
 if raw.get("bingo") is Dictionary and raw.bingo.get("week") == week_key():
  result.bingo = {"week": week_key(), "lines": []}
  for goal in BINGO:
   var value: Variant = raw.bingo.get(goal[0], 0)
   result.bingo[goal[0]] = clampi(int(value), 0, goal[2]) if value is int or value is float else 0
  if raw.bingo.get("lines") is Array: result.bingo.lines = raw.bingo.lines.filter(func(value): return value is int or value is float).map(func(value): return clampi(int(value), 0, 7))
 if raw.get("spaces") is Dictionary:
  for key in ["main", "balcony", "nook", "gallery"]:
   if raw.spaces.get(key) is Dictionary: result.spaces[key] = raw.spaces[key]
 if raw.get("room") is Dictionary:
  if raw.room.get("space") in ["main", "balcony", "nook", "gallery"]: result.room.space = raw.room.space
  for key in ["lamp", "seated", "resting"]:
   if raw.room.get(key) is bool: result.room[key] = raw.room[key]
 return result
