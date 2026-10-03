class_name DestinationTheme
extends RefCounted

const COLORS := {"stone": "b5a38e", "ice": "b6dfed", "sand": "dbba7e", "lantern": "b79480", "jungle": "839b78", "ocean": "8cc6c8", "space": "7483b3", "magic": "ab92c7", "lava": "80655c"}
const SOUVENIRS := {
 "FR": "Miniature Eiffel Tower", "IT": "Venetian carnival mask", "DE": "Cuckoo-clock keepsake", "JP": "Origami crane", "EG": "Pyramid miniature", "TR": "Blue glass charm", "GB": "Red telephone-box miniature", "US": "Liberty torch keepsake", "CA": "Maple-leaf pin", "MX": "Painted ceramic keepsake", "BR": "Carnival feather", "AR": "Tango shoe charm", "AU": "Koala keepsake", "NO": "Northern-lights globe", "GR": "Tiny blue-roof house", "ES": "Painted fan", "PT": "Blue tile keepsake", "CN": "Red lantern charm", "IN": "Lotus keepsake", "KR": "Paper fan", "TH": "Elephant keepsake", "ID": "Temple miniature", "MY": "Twin-towers miniature", "PH": "Pearl keepsake", "NL": "Windmill miniature", "MA": "Mosaic tile", "TN": "Ceramic bowl", "ZA": "Protea keepsake", "KE": "Giraffe charm", "NG": "Patterned fabric keepsake", "CL": "Mountain charm", "BO": "Salt-flat crystal", "CO": "Coffee-bean charm", "VE": "Waterfall keepsake", "PY": "Lace keepsake", "UY": "Mate-cup miniature", "JM": "Palm-tree charm", "SA": "Desert rose", "BG": "Rose keepsake", "MN": "Horse charm", "KZ": "Steppe eagle pin", "RU": "Painted nesting doll",
 "EVEREST": "Summit pennant", "SAHARA": "Sand-filled hourglass", "UNDERWATER": "Glowing shell", "SPACE": "Astronaut patch", "MOON": "Moon-rock keepsake", "MARS": "Mars rover miniature", "SATURN": "Ringed planet charm", "CRYSTAL_CAVERN": "Crystal shard", "CLOUD_CITY": "Cloud-in-a-bottle", "DRAGON_ISLAND": "Dragon scale", "HOBBIT_VILLAGE": "Round-door charm", "ELVEN_VALLEY": "Silver leaf", "VOLCANIC_REALM": "Obsidian keepsake", "WIZARD_CASTLE": "Magic wand", "WIZARD_VILLAGE": "Potion bottle", "ENCHANTED_FOREST": "Glowing acorn", "DINOSAUR_ISLAND": "Fossil keepsake", "WONDERLAND": "Pocket-watch charm",
}

static func style(id: String) -> String:
 if id == "INFINITE" or id in ["SPACE", "MOON", "MARS", "SATURN"]: return "space"
 if id in ["VOLCANIC_REALM", "DRAGON_ISLAND"]: return "lava"
 if id in GameCatalog.CINEMA_DESTINATIONS or id in ["CRYSTAL_CAVERN", "CLOUD_CITY"]: return "magic"
 if id in ["UNDERWATER", "GREAT_BARRIER_REEF", "VENICE", "SANTORINI"]: return "ocean"
 if id in ["EVEREST", "NORTHERN_LIGHTS", "NO", "IS", "FI", "SE", "GL", "AQ"]: return "ice"
 if id in ["JP", "CN", "KR", "TW", "HK", "MO"]: return "lantern"
 if id in ["SAHARA", "PETRA", "GRAND_CANYON"]: return "sand"
 if id in ["AMAZON", "SERENGETI", "VICTORIA_FALLS", "ANGKOR_WAT"]: return "jungle"
 var region: String = GameCatalog.DESTINATIONS.get(id, {}).get("region", "")
 if region in ["Northern Africa", "Western Asia", "Central Asia"]: return "sand"
 if region in ["South America", "Central America", "South-Eastern Asia", "Middle Africa", "Eastern Africa", "Western Africa"]: return "jungle"
 if region in ["Caribbean", "Melanesia", "Micronesia", "Polynesia", "Australia and New Zealand"]: return "ocean"
 return "stone"

static func color(id: String) -> Color:
 return Color(COLORS[style(id)])

static func layout(id: String) -> String:
 var theme := style(id)
 if theme in ["ice", "lava", "magic"]: return "climb"
 if theme in ["ocean", "jungle"]: return "bridge"
 return "curve"

static func souvenir(id: String) -> String:
 return SOUVENIRS.get(id, GameCatalog.country_name(id) + " · " + {"stone": "city miniature", "ice": "snowflake pin", "sand": "sandstone charm", "lantern": "paper lantern", "jungle": "leaf keepsake", "ocean": "shell keepsake", "space": "star fragment", "magic": "enchanted crystal", "lava": "obsidian charm"}[style(id)])
