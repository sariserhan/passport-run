class_name TravelMilestones
extends RefCounted

const CONTINENTS := ["Africa", "Europe", "Asia", "North America", "South America", "Oceania", "Antarctica"]

static func continent(id: String) -> String:
 var region: String = GameCatalog.FREE_DESTINATIONS.get(id, {}).get("region", "")
 for name in ["Africa", "Europe", "Asia"]:
  if name in region: return name
 if region == "South America": return "South America"
 if region in ["North America", "Central America", "Caribbean"]: return "North America"
 if region == "Antarctic": return "Antarctica"
 return "Oceania"

static func progress(discoveries: Array[String]) -> Dictionary:
 var result := {}
 for name in CONTINENTS: result[name] = {"completed": 0, "total": 0}
 for id in GameCatalog.FREE_DESTINATIONS:
  var name := continent(id)
  result[name].total += 1
  if id in discoveries: result[name].completed += 1
 return result

static func earned(discoveries: Array[String]) -> Array[String]:
 var result: Array[String] = []
 var counts := progress(discoveries)
 for name in CONTINENTS:
  if counts[name].total > 0 and counts[name].completed == counts[name].total: result.append(name)
 return result
