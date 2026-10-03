class_name TravelScrapbook
extends VBoxContainer
var profile: PlayerProfile
var page: Dictionary = {}
func _ready() -> void:
 add_theme_constant_override("separation", 12)
 var title := Label.new()
 title.text = page.get("title", "My travel scrapbook")
 title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 title.add_theme_font_size_override("font_size", 28)
 add_child(title)
 var grid := GridContainer.new()
 grid.columns = 2 if page.get("layout") == "grid" else 1
 grid.add_theme_constant_override("h_separation", 10)
 grid.add_theme_constant_override("v_separation", 12)
 add_child(grid)
 for id in page.get("countries", []):
  var stack := VBoxContainer.new()
  stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  grid.add_child(stack)
  var art := TravelArtwork.new()
  art.country_id = id
  art.show_traveler = false
  art.custom_minimum_size.y = 130 if grid.columns == 2 else 145
  stack.add_child(art)
  var stamp := Label.new()
  stamp.text = "✓ " + GameCatalog.country_name(id)
  stamp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  stamp.add_theme_font_size_override("font_size", 17)
  stack.add_child(stamp)
 var note := Label.new()
 note.text = page.get("note", "")
 note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 note.add_theme_font_size_override("font_size", 19)
 add_child(note)
