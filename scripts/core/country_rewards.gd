class_name CountryRewards
extends RefCounted

# Primary sources and verification date are recorded in docs/country-facts.md.
const FACTS := {
	"US": "The Statue of Liberty stands in New York Harbor.",
	"FR": "The Eiffel Tower is in Paris.",
	"EG": "The pyramids at Giza are in Egypt.",
	"TR": "Istanbul has neighborhoods in Europe and Asia.",
	"JP": "Mount Fuji is Japan’s highest mountain.",
}

static func fact(id: String) -> String:
	if id in FACTS:
		return FACTS[id]
	var country: Dictionary = GameCatalog.COUNTRIES.get(id, {})
	if country.is_empty():
		return ""
	var capitals: Array = country.capital
	return "Capital: " + ", ".join(capitals) + "." if not capitals.is_empty() else GameCatalog.country_name(id) + " is in " + str(country.region) + "."
