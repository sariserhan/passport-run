class_name MeshFactory
extends RefCounted

static var stone_texture: NoiseTexture2D
static var beveled_meshes: Dictionary = {}

static func stone_material(color: Color) -> StandardMaterial3D:
	if not stone_texture:
		var noise := FastNoiseLite.new()
		noise.seed = 742
		noise.frequency = 0.12
		var tones := Gradient.new()
		tones.set_color(0, Color("a6a6a6"))
		tones.set_color(1, Color("f2f2f2"))
		stone_texture = NoiseTexture2D.new()
		stone_texture.width = 128
		stone_texture.height = 128
		stone_texture.noise = noise
		stone_texture.color_ramp = tones
	var mat := material(color)
	mat.albedo_texture = stone_texture
	return mat

static func material(color: Color, roughness: float = 0.85) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	return mat

static func box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return instance(parent, mesh, pos, mat)

static func sphere(parent: Node3D, radius: float, pos: Vector3, mat: Material, scale_y: float = 1.0) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0 * scale_y
	mesh.radial_segments = 24
	mesh.rings = 12
	return instance(parent, mesh, pos, mat)

static func cylinder(parent: Node3D, bottom: float, top: float, height: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.height = height
	mesh.radial_segments = 10
	return instance(parent, mesh, pos, mat)

static func instance(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	parent.add_child(node)
	return node

static func capsule(parent: Node3D, radius: float, height: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	mesh.rings = 8
	return instance(parent, mesh, pos, mat)

static func beveled_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, bevel: float = 0.10) -> MeshInstance3D:
	var key := Vector4(size.x, size.y, size.z, bevel)
	if beveled_meshes.has(key):
		return instance(parent, beveled_meshes[key], pos, mat)
	# A single rounded stone mesh: flat top, chamfered rim, rounded corners.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	var outline: Array[Vector2] = []
	var radius: float = minf(bevel * 2, minf(size.x, size.z) * 0.25)
	for corner in 4:
		var angle: float = corner * PI / 2
		var center := Vector2(cos(angle + PI / 4), sin(angle + PI / 4)) * sqrt(2.0)
		center *= Vector2(size.x / 2 - radius, size.z / 2 - radius)
		for step in 5:
			var a: float = angle + step * PI / 8
			outline.append(center + Vector2(cos(a), sin(a)) * radius)
	var rings: Array[Vector2] = [Vector2(size.y / 2, bevel), Vector2(size.y / 2 - bevel, 0), Vector2(-size.y / 2 + bevel, 0), Vector2(-size.y / 2, bevel)]
	for i in outline.size():
		var next: int = (i + 1) % outline.size()
		for level in 3:
			var corners: Array[Vector3] = []
			for point in [outline[i], outline[next]]:
				for ring in [rings[level], rings[level + 1]]:
					var p: Vector2 = point * Vector2(1 - ring.y * 2 / size.x, 1 - ring.y * 2 / size.z)
					corners.append(Vector3(p.x, ring.x, p.y))
			for index in [0, 1, 2, 2, 1, 3]:
				surface.set_uv(Vector2(corners[index].x / size.x + 0.5, corners[index].z / size.z + 0.5))
				surface.add_vertex(corners[index])
		for top in [true, false]:
			var ring: Vector2 = rings[0] if top else rings[3]
			var a: Vector2 = outline[i] * Vector2(1 - ring.y * 2 / size.x, 1 - ring.y * 2 / size.z)
			var b: Vector2 = outline[next] * Vector2(1 - ring.y * 2 / size.x, 1 - ring.y * 2 / size.z)
			for vertex in [Vector3(0, ring.x, 0), Vector3(a.x, ring.x, a.y) if top else Vector3(b.x, ring.x, b.y), Vector3(b.x, ring.x, b.y) if top else Vector3(a.x, ring.x, a.y)]:
				surface.set_uv(Vector2(vertex.x / size.x + 0.5, vertex.z / size.z + 0.5))
				surface.add_vertex(vertex)
	surface.generate_normals()
	beveled_meshes[key] = surface.commit()
	return instance(parent, beveled_meshes[key], pos, mat)
