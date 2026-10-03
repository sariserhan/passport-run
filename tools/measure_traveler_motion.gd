extends SceneTree

func _initialize() -> void:
 var result := {}
 for kind in ["human", "fantasy"]:
  var path := "res://assets/realistic/" + ("fantasy-travelers-motion.png" if kind == "fantasy" else "travelers-motion.png")
  var source := Image.load_from_file(ProjectSettings.globalize_path(path))
  var cell := Vector2(source.get_size()) / Vector2(6, 12)
  var rows := []
  for row in 12:
   var poses := []
   for column in 6:
    var origin := Vector2i(Vector2(column, row) * cell)
    var extent := Vector2i(Vector2(column + 1, row + 1) * cell) - origin
    var left := extent.x
    var top := extent.y
    var right := 0
    var bottom := 0
    for y in extent.y:
     for x in extent.x:
      if source.get_pixel(origin.x + x, origin.y + y).a > 0.5:
       left = mini(left, x)
       top = mini(top, y)
       right = maxi(right, x + 1)
       bottom = maxi(bottom, y + 1)
    poses.append([origin.x + left, origin.y + top, origin.x + right, origin.y + bottom])
   rows.append(poses)
  result[kind] = rows
 var output := FileAccess.open("res://resources/traveler-motion.json", FileAccess.WRITE)
 output.store_string(JSON.stringify(result))
 print("Measured 144 traveler animation poses")
 quit()
