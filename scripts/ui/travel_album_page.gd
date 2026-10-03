class_name TravelAlbumPage
extends VBoxContainer

var destination_id := "FR"
var profile: PlayerProfile

func _ready() -> void:
 add_theme_constant_override("separation", 12)
 var art := TravelArtwork.new()
 art.country_id = destination_id
 art.show_traveler = false
 art.custom_minimum_size.y = 190
 add_child(art)
 add_text(GameCatalog.country_name(destination_id), 25)
 var souvenir := SouvenirCard.new()
 souvenir.destination_id = destination_id
 souvenir.quantity = int(profile.souvenir_counts.get(destination_id, 1))
 add_child(souvenir)
 add_text(CountryRewards.fact(destination_id), 18)
 var record: Dictionary = profile.destination_records.get(destination_id, {})
 add_text("Best jump clear: %d tiles" % record.jump if record.has("jump") else "Best jump clear: not recorded yet", 18)
 add_text("Best balloon score: %d pts" % record.arcade if record.has("arcade") else "Best balloon score: not recorded yet", 18)
 add_text("Collected %d time%s" % [profile.souvenir_counts.get(destination_id, 1), "" if profile.souvenir_counts.get(destination_id, 1) == 1 else "s"], 16)

func add_text(value: String, font_size: int) -> void:
 var label := Label.new()
 label.text = value
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.add_theme_font_size_override("font_size", font_size)
 label.add_theme_color_override("font_color", Color("fff2d6"))
 add_child(label)
