class_name TravelGoals
extends RefCounted

const TRIPS := {
 "europe": {"name": "European Escape", "route": ["FR", "IT", "ES"], "cover": "Sunset", "color": "964d42"},
 "asia": {"name": "Asian Adventure", "route": ["JP", "TH", "ID"], "cover": "Jade", "color": "276e62"},
 "americas": {"name": "American Discovery", "route": ["US", "MX", "CA"], "cover": "Ocean", "color": "285f86"},
}

static func earned_covers(discoveries: Array[String]) -> Array[String]:
 var result: Array[String] = ["classic"]
 for id in TRIPS:
  if TRIPS[id].route.all(func(country): return country in discoveries): result.append(id)
 return result

static func regions(discoveries: Array[String]) -> Dictionary:
 var result := {}
 for id in GameCatalog.FREE_DESTINATIONS:
  var region: String = GameCatalog.FREE_DESTINATIONS[id].region
  if not result.has(region): result[region] = {"completed": 0, "total": 0}
  result[region].total += 1
  if id in discoveries: result[region].completed += 1
 return result
