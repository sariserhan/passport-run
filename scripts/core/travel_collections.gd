class_name TravelCollections
extends RefCounted

const SETS := {
 "space": {"name": "Space display", "route": ["SPACE", "MOON", "MARS", "SATURN"]},
 "winter": {"name": "Winter corner", "route": ["CA", "NO", "IS"]},
 "escape": {"name": "European postcard gallery", "route": ["FR", "IT", "ES"]},
}

static func earned(discoveries: Array[String]) -> Array[String]:
 var result: Array[String] = []
 for key in SETS:
  if SETS[key].route.all(func(id): return id in discoveries): result.append(key)
 return result
