class_name CharacterStyle
extends RefCounted

const CHARACTERS := {
 "classic": {"name": "Classic Explorer", "index": 0, "count": 0},
 "backpacker": {"name": "Girl Backpacker", "index": 1, "count": 0},
 "photographer": {"name": "Travel Photographer", "index": 2, "count": 3},
 "city": {"name": "City Wanderer", "index": 3, "count": 5},
 "hiker": {"name": "Forest Hiker", "index": 4, "count": 10},
 "mountaineer": {"name": "Mountain Climber", "index": 5, "count": 20},
 "surfer": {"name": "Coastal Surfer", "index": 6, "count": 35},
 "naturalist": {"name": "Wildlife Naturalist", "index": 7, "count": 50},
 "pilot": {"name": "Sky Pilot", "index": 8, "count": 75},
 "desert": {"name": "Desert Nomad", "index": 9, "count": 100},
 "polar": {"name": "Polar Adventurer", "index": 10, "count": 150},
 "champion": {"name": "World Champion", "index": 11, "world": true},
 "fox": {"name": "Fox Backpacker", "index": 0, "count": 1, "group": "Animal travelers", "fantasy_art": true},
 "cat": {"name": "Cat Globetrotter", "index": 1, "count": 4, "group": "Animal travelers", "fantasy_art": true},
 "panda": {"name": "Panda Trail Buddy", "index": 2, "count": 8, "group": "Animal travelers", "fantasy_art": true},
 "penguin": {"name": "Penguin Explorer", "index": 3, "count": 12, "group": "Animal travelers", "fantasy_art": true},
 "astronaut": {"name": "Astronaut Voyager", "index": 4, "count": 18, "group": "Space travelers", "fantasy_art": true},
 "robot": {"name": "Orbit the Robot", "index": 5, "count": 30, "group": "Space travelers", "fantasy_art": true},
 "wizard": {"name": "Wandering Wizard", "index": 6, "count": 45, "group": "Fantasy travelers", "fantasy_art": true},
 "elf": {"name": "Woodland Elf", "index": 7, "count": 60, "group": "Fantasy travelers", "fantasy_art": true},
 "dragon": {"name": "Dragon Adventurer", "index": 8, "count": 80, "group": "Fantasy travelers", "fantasy_art": true},
 "fairy": {"name": "Fairy Pathfinder", "index": 9, "count": 110, "group": "Fantasy travelers", "fantasy_art": true},
 "mushroom": {"name": "Mushroom Rambler", "index": 10, "count": 160, "group": "Fantasy travelers", "fantasy_art": true},
 "knight": {"name": "Passport Knight", "index": 11, "count": 200, "group": "Fantasy travelers", "fantasy_art": true},
}

static func world_complete(discoveries: Array[String]) -> bool:
 return GameCatalog.FREE_DESTINATIONS.keys().all(func(id): return id in discoveries)

static func character_unlocked(id: String, discoveries: Array[String], purchased: bool = false) -> bool:
 if id not in CHARACTERS: return false
 var item: Dictionary = CHARACTERS[id]
 if item.has("world"): return world_complete(discoveries)
 return purchased or discoveries.size() >= item.count

static func character_texture(id: String) -> Texture2D:
 var character: Dictionary = CHARACTERS.get(id, CHARACTERS.classic)
 var path := "res://assets/realistic/fantasy-travelers.png" if character.get("fantasy_art", false) else "res://assets/realistic/travelers.png"
 return RealisticArt.region(load(path), character.index, Vector2i(4, 3))

const OUTFITS := {"classic": {"name": "Classic Explorer", "count": 0, "color": "ffffff"}, "trail": {"name": "Forest Trail", "count": 3, "color": "d3f1de"}, "polar": {"name": "Polar Explorer", "count": 10, "color": "d5eaff"}, "cosmic": {"name": "Cosmic Explorer", "count": 25, "color": "eedcff"}, "balloon_gold": {"name": "Golden Balloon Explorer", "badge": "arcade:clean_boss", "color": "ffe0a0"}, "balloon_sky": {"name": "Sky Balloon Explorer", "badge": "arcade:100_pops", "color": "aedcff"}, "balloon_shadow": {"name": "Twilight Balloon Explorer", "badge": "arcade:no_drops", "color": "dfc5f0"}}
const HATS := {"none": {"name": "No Hat", "count": 0}, "sun": {"name": "Sun Hat", "count": 3}, "winter": {"name": "Winter Hat", "count": 10}, "space": {"name": "Space Cap", "count": 25}}
const BACKPACKS := {"classic": "b58147", "europe": "964d42", "asia": "276e62", "americas": "285f86"}

static func unlocked(kind: String, id: String, discoveries: Array[String], badges: Array[String] = []) -> bool:
 if kind == "backpack": return id in TravelGoals.earned_covers(discoveries)
 var items: Dictionary = OUTFITS if kind == "outfit" else HATS
 if id not in items: return false
 if items[id].has("badge"): return items[id].badge in badges
 return discoveries.size() >= items[id].count
