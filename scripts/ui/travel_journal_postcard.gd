class_name TravelJournalPostcard
extends VBoxContainer
var page: Dictionary = {}

func _ready() -> void:
 add_theme_constant_override("separation", 12)
 custom_minimum_size.y = 760
 text("A DAY IN MY PASSPORT", 28)
 text(page.get("date", "") + " · UTC", 19)
 var countries: Array = page.get("countries", [])
 if not countries.is_empty():
  var artwork := TravelArtwork.new()
  artwork.country_id = countries.back()
  artwork.show_traveler = false
  artwork.custom_minimum_size.y = 185
  add_child(artwork)
 text("TODAY’S STAMPS", 21)
 var stamps := HFlowContainer.new()
 stamps.add_theme_constant_override("h_separation", 12)
 stamps.add_theme_constant_override("v_separation", 8)
 add_child(stamps)
 for id in countries.slice(0, 6):
  var frame := PanelContainer.new()
  var border := StyleBoxFlat.new()
  border.bg_color = Color("1c485e")
  border.border_color = Color("9bddbb")
  border.set_border_width_all(2)
  border.set_corner_radius_all(7)
  border.content_margin_left = 10
  border.content_margin_right = 10
  border.content_margin_top = 6
  border.content_margin_bottom = 6
  frame.add_theme_stylebox_override("panel", border)
  var stack := VBoxContainer.new()
  frame.add_child(stack)
  var stamp := Label.new()
  stamp.text = "✓ " + GameCatalog.country_name(id)
  stamp.add_theme_font_size_override("font_size", 18)
  stamp.add_theme_color_override("font_color", Color("9bddbb"))
  stack.add_child(stamp)
  var caption := Label.new()
  caption.text = "PASSPORT STAMP · " + page.get("date", "").substr(5)
  caption.add_theme_font_size_override("font_size", 11)
  caption.add_theme_color_override("font_color", Color("9bddbb"))
  stack.add_child(caption)
  stamps.add_child(frame)
 if countries.size() > 6: text("+ %d more stamps" % (countries.size() - 6), 17)
 if countries.is_empty(): text("A fresh page, ready for adventure.", 19)
 text("MY BEST MOMENT", 21)
 var moments: Array = page.get("moments", [])
 var best := "The journey is just beginning."
 if not moments.is_empty():
  best = moments.back()
  for moment in moments:
   if "Flawless" in moment or "Best" in moment: best = moment
 text(best, 20)
 text("TREASURES BROUGHT HOME", 21)
 var rewards: Array = page.get("rewards", [])
 if rewards.is_empty(): text("New memories are a reward, too.", 18)
 for reward in rewards.slice(maxi(0, rewards.size() - 4)): text("★ " + reward, 18)
 if rewards.size() > 4: text("And %d more rewards in my journal" % (rewards.size() - 4), 16)

func text(value: String, font_size: int) -> void:
 var label := Label.new()
 label.text = value
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.add_theme_font_size_override("font_size", font_size)
 label.add_theme_color_override("font_color", Color("fff2d6"))
 add_child(label)
