class_name RoomDecor
extends RefCounted

const ITEMS := {
 "wallpaper": {"sand": {"name": "Warm sand", "count": 0, "color": "e6d8bf"}, "sky": {"name": "Postcard blue", "count": 3, "color": "bad6df"}, "forest": {"name": "Forest retreat", "count": 10, "color": "b8cbb4"}, "night": {"name": "Starry nights", "count": 25, "color": "384c70"}},
 "shelves": {"oak": {"name": "Oak shelves", "count": 0, "color": "785743"}, "white": {"name": "White shelves", "count": 5, "color": "eee5d5"}, "walnut": {"name": "Walnut shelves", "count": 15, "color": "443b39"}},
 "plant": {"none": {"name": "No plant", "count": 0}, "fern": {"name": "Travel fern", "count": 3}, "palm": {"name": "Island palm", "count": 20}},
 "rug": {"none": {"name": "No rug", "count": 0, "color": "ffffff"}, "sunset": {"name": "Sunset rug", "count": 5, "color": "ce8c6e"}, "ocean": {"name": "Ocean rug", "count": 12, "color": "669fae"}},
 "display": {"none": {"name": "No themed display", "count": 0}, "space": {"name": "Space display", "count": 0}, "winter": {"name": "Winter corner", "count": 0}, "escape": {"name": "European postcard gallery", "count": 0}},
 "furniture": {"none": {"name": "No furniture", "count": 0}, "desk": {"name": "Traveler’s desk", "count": 4}, "armchair": {"name": "Reading armchair", "count": 12}},
 "lighting": {"day": {"name": "Daylight", "count": 0}, "warm": {"name": "Warm evening", "count": 5}, "moon": {"name": "Moonlight", "count": 20}},
 "map": {"none": {"name": "No wall map", "count": 0}, "world": {"name": "My world map", "count": 8}},
 "buddy_bed": {"none": {"name": "No buddy bed", "count": 0}, "nest": {"name": "Pip’s nest", "count": 2}, "dock": {"name": "Orbit’s charging dock", "count": 5}, "cushion": {"name": "Ember’s cushion", "count": 8}},
 "trophy": {"none": {"name": "No regional trophy", "count": 0}, "Africa": {"name": "Africa explorer", "count": 0}, "Europe": {"name": "Europe explorer", "count": 0}, "Asia": {"name": "Asia explorer", "count": 0}, "North America": {"name": "North America explorer", "count": 0}, "South America": {"name": "South America explorer", "count": 0}, "Oceania": {"name": "Oceania explorer", "count": 0}, "Antarctica": {"name": "Antarctica explorer", "count": 0}},
}
const DEFAULTS := {"wallpaper": "sand", "shelves": "oak", "plant": "none", "rug": "none", "display": "none", "furniture": "none", "lighting": "day", "map": "none", "buddy_bed": "none", "trophy": "none"}

static func unlocked(kind: String, id: String, discoveries: Array[String]) -> bool:
 if kind == "trophy": return id == "none" or id in TravelMilestones.earned(discoveries)
 if kind == "display": return id == "none" or id in TravelCollections.earned(discoveries)
 return kind in ITEMS and id in ITEMS[kind] and discoveries.size() >= ITEMS[kind][id].count
