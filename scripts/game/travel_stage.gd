class_name TravelStage
extends Node3D
var kind := ""
var key := ""
var rows := 10
var reduced_motion := false
var frozen := false
var clock := 0.0
var vehicle: Node3D
func _ready() -> void:
 var cream := MeshFactory.material(Color("e6cc91"))
 var blue := MeshFactory.material(Color("588a9e"))
 var red := MeshFactory.material(Color("bd7364"))
 if kind == "city" and key == "paris" or kind == "landmark" and key == "eiffel":
  for level in 6:
   var width := 3.3 - level * 0.45
   MeshFactory.box(self, Vector3(width, 0.35, width), Vector3(-7, level * 1.3, -rows * 1.4), cream)
  MeshFactory.box(self, Vector3(0.25, 3, 0.25), Vector3(-7, 8, -rows * 1.4), cream)
 elif kind == "city" and key == "kyoto" or kind == "secret" and key == "garden":
  for z in [-5, -13, -21]:
   for x in [-6, 6]:
    MeshFactory.box(self, Vector3(0.3, 3.5, 0.3), Vector3(x, 1.7, z), red)
    MeshFactory.box(self, Vector3(3, 0.3, 0.5), Vector3(x, 3.5, z), red)
    MeshFactory.sphere(self, 1.3, Vector3(x, 4.5, z), MeshFactory.material(Color("e9a9bc")))
 elif kind == "city" or kind == "secret":
  for i in 12:
   MeshFactory.box(self, Vector3(2, 3 + i % 5, 2), Vector3((-1 if i % 2 == 0 else 1) * (6 + i % 3), (3 + i % 5) * 0.5, -3 - i * 2), blue)
 elif kind == "landmark" and key == "fuji":
  MeshFactory.cylinder(self, 6, 1.8, 5, Vector3(9, 2.5, -rows * 1.5), blue)
  MeshFactory.cylinder(self, 1.8, 0, 2.5, Vector3(9, 6.25, -rows * 1.5), MeshFactory.material(Color("f2f3ef")))
 elif kind == "landmark":
  for level in 8:
   var width := 8.0 - level * 0.85
   MeshFactory.box(self, Vector3(width, 0.8, width), Vector3(9, level * 0.8, -rows * 1.5), cream if key == "pyramids" else blue)
 elif kind == "transport":
  vehicle = Node3D.new()
  add_child(vehicle)
  vehicle.position = Vector3(7, 0, -10)
  var length := 8.0 if key == "train" else 4.0
  MeshFactory.box(vehicle, Vector3(2.5, 1.2, length), Vector3(0, 0.6, 0), cream)
  if key != "boat":
   MeshFactory.box(vehicle, Vector3(2.3, 1.5, length * 0.8), Vector3(0, 1.9, 0), red if key == "tram" else blue)
   for z in [-length * 0.25, length * 0.25]:
    for x in [-1.25, 1.25]: MeshFactory.sphere(vehicle, 0.45, Vector3(x, 0, z), blue)
  else: MeshFactory.box(vehicle, Vector3(0.12, 4, 0.12), Vector3(0, 2.5, 0), red)
  if key == "cable_car":
   MeshFactory.box(self, Vector3(0.08, 0.08, rows * 3), Vector3(7, 5, -rows * 1.5), cream)
 elif kind == "festival":
  var color := MeshFactory.material(Color(TravelExtras.festival().color))
  for i in 16:
   var x := -6 if i % 2 == 0 else 6
   MeshFactory.box(self, Vector3(0.1, 3, 0.1), Vector3(x, 1.5, -2 - i * 1.5), cream)
   MeshFactory.sphere(self, 0.5, Vector3(x, 3.2, -2 - i * 1.5), color)
func _process(delta: float) -> void:
 if frozen or reduced_motion or not vehicle: return
 clock += delta
 vehicle.position.z = -10 + sin(clock * 0.4) * 5
 vehicle.position.y = 1.5 + sin(clock * 0.5) if key == "cable_car" else sin(clock) * 0.1 if key == "boat" else 0
