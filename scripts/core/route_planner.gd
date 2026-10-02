class_name RoutePlanner
extends RefCounted

# Temporary five-destination travel graph. Replace with a curated geographic dataset at scale.
const REGIONAL_WEIGHT: int = 80
const FLIGHT_INTERVAL: int = 3
var route_seed: int = 1
var route: Array[String] = []
var completed: Array[String] = []

func start(home: String, seed_value: int) -> void:
	assert(GameCatalog.COUNTRIES.has(home))
	route_seed = seed_value
	route.assign([home])
	completed.clear()

func current() -> String:
	return route.back() if not route.is_empty() else ""

func complete_current() -> void:
	if not current().is_empty() and current() not in completed:
		completed.append(current())

func choices() -> Array[String]:
	var remaining: Array[String] = []
	for id in GameCatalog.COUNTRIES:
		if id not in route:
			remaining.append(id)
	if remaining.is_empty():
		return remaining
	var nearby: Array[String] = []
	for id in GameCatalog.COUNTRIES[current()].neighbors:
		if id in remaining:
			nearby.append(id)
	var seed_value := GameCatalog.derived_seed(route_seed, completed.size())
	var long_haul: bool = nearby.is_empty() or completed.size() % FLIGHT_INTERVAL == 0 or PathGenerator.lane_at(seed_value, 100, 0) >= REGIONAL_WEIGHT
	var pool: Array[String] = remaining if long_haul else nearby
	var choices_out: Array[String] = []
	while not pool.is_empty() and choices_out.size() < (3 if long_haul else 1):
		var index := PathGenerator.lane_at(seed_value, pool.size(), choices_out.size() + 1)
		choices_out.append(pool[index])
		pool.remove_at(index)
	return choices_out

func travel_to(id: String) -> bool:
	if current() not in completed or id not in choices():
		return false
	route.append(id)
	return true

static func standardized(home: String, seed_value: int) -> Array[String]:
	var planner := RoutePlanner.new()
	planner.start(home, seed_value)
	while planner.route.size() < GameCatalog.COUNTRIES.size():
		planner.complete_current()
		var options := planner.choices()
		if options.is_empty():
			break
		planner.travel_to(options[0])
	return planner.route.duplicate()
