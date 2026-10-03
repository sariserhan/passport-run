class_name CharacterQuests
extends RefCounted

const QUESTS := {
 "penguin": {"name": "Snow Passport", "route": ["NO", "IS", "FI"]},
 "astronaut": {"name": "Space Explorer", "route": ["SPACE", "MOON", "MARS"]},
 "panda": {"name": "Eastern Adventure", "route": ["CN", "JP", "KR"]},
 "cat": {"name": "City Break", "route": ["FR", "IT", "GB"]},
 "wizard": {"name": "Wizard’s Journey", "route": ["WIZARD_CASTLE", "WIZARD_VILLAGE", "ENCHANTED_FOREST"]},
 "elf": {"name": "Forest Wanderer", "route": ["ELVEN_VALLEY", "ENCHANTED_FOREST", "HOBBIT_VILLAGE"]},
 "dragon": {"name": "Fire and Flight", "route": ["DRAGON_ISLAND", "VOLCANIC_REALM", "CLOUD_CITY"]},
 "fairy": {"name": "Enchanted Passport", "route": ["ENCHANTED_FOREST", "WONDERLAND", "ELVEN_VALLEY"]},
 "mushroom": {"name": "Small Wonders", "route": ["HOBBIT_VILLAGE", "ENCHANTED_FOREST", "CRYSTAL_CAVERN"]},
 "knight": {"name": "Castle Quest", "route": ["WIZARD_CASTLE", "DRAGON_ISLAND", "ELVEN_VALLEY"]},
}

static func complete(id: String, discoveries: Array[String]) -> bool:
 return id in QUESTS and QUESTS[id].route.all(func(place): return place in discoveries)

static func count(id: String, discoveries: Array[String]) -> int:
 if id not in QUESTS: return 0
 return QUESTS[id].route.filter(func(place): return place in discoveries).size()
