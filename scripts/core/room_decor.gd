class_name RoomDecor
extends RefCounted

const ITEMS := {
 "wallpaper": {"sand": {"name": "Warm sand", "count": 0, "color": "e6d8bf"}, "sky": {"name": "Postcard blue", "count": 3, "color": "bad6df"}, "forest": {"name": "Forest retreat", "count": 10, "color": "b8cbb4"}, "night": {"name": "Starry nights", "count": 25, "color": "384c70"}},
 "shelves": {"oak": {"name": "Oak shelves", "count": 0, "color": "785743"}, "white": {"name": "White shelves", "count": 5, "color": "eee5d5"}, "walnut": {"name": "Walnut shelves", "count": 15, "color": "443b39"}},
 "plant": {"none": {"name": "No plant", "count": 0}, "fern": {"name": "Travel fern", "count": 3}, "palm": {"name": "Island palm", "count": 20}},
 "rug": {"none": {"name": "No rug", "count": 0, "color": "ffffff"}, "sunset": {"name": "Sunset rug", "count": 5, "color": "ce8c6e"}, "ocean": {"name": "Ocean rug", "count": 12, "color": "669fae"}},
}
const DEFAULTS := {"wallpaper": "sand", "shelves": "oak", "plant": "none", "rug": "none"}

static func unlocked(kind: String, id: String, discoveries: Array[String]) -> bool:
 return kind in ITEMS and id in ITEMS[kind] and discoveries.size() >= ITEMS[kind][id].count
