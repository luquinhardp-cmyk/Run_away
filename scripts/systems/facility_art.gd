extends Node3D
## Environmental dressing is separate from gameplay/interactions/navigation.
var builder: Dictionary = {}
var detail: Node3D
var lamps: Array[OmniLight3D] = []
var grass: MultiMeshInstance3D
var world: WorldEnvironment
var rng := RandomNumberGenerator.new()
var static_batches := 0
var age := 0.0

func _ready() -> void:
	name = "RuralArt"
	rng.seed = 70421
	detail = Node3D.new()
	add_child(detail)
	_corridor()
	_rooms()
	_room_stories()
	_exterior()
	_basement()
	_ambience("exterior_wind", Vector3(0, 2, 12), 24, -30)
	_ambience("basement_drips", Vector3(-19, -1, -32), 12, -27)
	_ambience("electric_hum", Vector3(-7, 1.4, -33), 8, -34)
	static_batches = HorrorArt.merge_static(detail, self)
	Game.updated.connect(apply_quality)
	apply_quality()

func _ambience(clip: String, pos: Vector3, radius: float, volume: float) -> void:
	var audio := AudioStreamPlayer3D.new()
	audio.stream = load("res://assets/audio/" + clip + ".wav")
	audio.bus = "Effects"
	audio.position = pos
	audio.max_distance = radius
	audio.volume_db = volume
	add_child(audio)
	audio.finished.connect(audio.play)
	audio.play()

func box(pos: Vector3, size: Vector3, mat: Material, angle: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return piece(mesh, pos, mat, angle)

func piece(mesh: Mesh, pos: Vector3, mat: Material, angle: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	node.rotation = angle
	detail.add_child(node)
	return node

func pipe(a: Vector3, b: Vector3, radius: float, mat: Material, sides: int = 10) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = a.distance_to(b)
	mesh.radial_segments = sides
	mesh.rings = 1
	var node := piece(mesh, (a + b) * 0.5, mat)
	node.quaternion = Quaternion(Vector3.UP, (b - a).normalized())

func light_at(pos: Vector3, color: Color, energy: float, radius: float) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = radius
	light.shadow_enabled = false
	add_child(light)
	lamps.append(light)

func _corridor() -> void:
	var rust := HorrorArt.surface("rusted_iron")
	var concrete := HorrorArt.surface("damp_concrete")
	var stain := HorrorArt.surface("organic_residue")
	var wood := HorrorArt.surface("rotten_wood")
	var glow := HorrorArt.solid(Color("b19a64"), 0.6)
	for z in range(0, -41, -4):
		# Pipes, flange collars, brackets and sagging cables remain above/along walls.
		for x in [-1.76, -1.53]:
			pipe(Vector3(x, 2.66, z + 1.95), Vector3(x, 2.66, z - 1.95), 0.075 if x < -1.6 else 0.045, rust)
			pipe(Vector3(x, 2.66, z + 0.2), Vector3(x, 2.66, z + 0.28), 0.105 if x < -1.6 else 0.068, rust)
		box(Vector3(-1.65, 2.53, z), Vector3(0.55, 0.04, 0.09), rust)
		box(Vector3(0, 2.92, z), Vector3(0.7, 0.08, 0.24), rust)
		box(Vector3(0, 2.85, z), Vector3(0.52, 0.025, 0.12), glow)
		for i in 4:
			var p := Vector3(1.86, 1.1 + i * 0.12, z + rng.randf_range(-1.3, 1.3))
			box(p, Vector3(0.014, 0.035, rng.randf_range(0.3, 0.7)), stain, Vector3(0.1, 0, -0.25))
		# Damp lower wall band, imperfect concrete expansion joints.
		for side in [-1, 1]:
			if z % 8 != 0:
				box(Vector3(side * 1.9, 0.32, z), Vector3(0.025, 0.6, 3.5), concrete)
			for i in 3:
				box(Vector3(side * 1.91, 0.95 + i * 0.15, z + 0.7 + i * 0.15), Vector3(0.025, 0.025, 0.65), stain, Vector3(-0.4, 0, 0))
		# Cable droop is geometry, not a physics rope.
		for i in 5:
			var z1: float = z + 1.8 - i * 0.75
			pipe(Vector3(1.5, 2.8 - sin(float(i) / 5 * PI) * 0.28, z1), Vector3(1.5, 2.8 - sin(float(i + 1) / 5 * PI) * 0.28, z1 - 0.75), 0.012, rust, 6)
		# Small debris confined to edges, preserving the chase lane.
		for i in 5:
			var p := Vector3(rng.randf_range(1.35, 1.75), 0.035, z + rng.randf_range(-1.5, 1.5))
			box(p, Vector3(rng.randf_range(0.08, 0.23), 0.045, 0.15), concrete if i % 2 else wood, Vector3(0, rng.randf() * PI, 0))
		if z % 12 == 0: _puddle(Vector3(0.7, 0.015, z - 1), Vector2(1.0, 0.6))
	for z in [-6, -18, -30]:
		# Ribbed valve wheels.
		var torus := TorusMesh.new()
		torus.inner_radius = 0.13
		torus.outer_radius = 0.17
		torus.rings = 16
		torus.ring_segments = 6
		piece(torus, Vector3(-1.7, 2.2, z), rust, Vector3(PI / 2, 0, 0))
		pipe(Vector3(-1.7, 2.2, z), Vector3(-1.7, 2.66, z), 0.035, rust)

func _puddle(pos: Vector3, size: Vector2) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 24:
		tool.set_normal(Vector3.UP)
		tool.add_vertex(Vector3.ZERO)
		for vertex in [i + 1, i]:
			var angle := float(vertex) / 24 * TAU
			var radius := 0.5 * (1 + sin(angle * 3) * 0.16 + cos(angle * 7) * 0.08)
			tool.set_normal(Vector3.UP)
			tool.add_vertex(Vector3(cos(angle) * radius, 0, sin(angle) * radius))
	var mesh := tool.commit()
	var material := HorrorArt.solid(Color(0.14, 0.15, 0.12))
	material.roughness = 0.28
	material.metallic = 0.0
	var node := piece(mesh, pos, material)
	node.scale = Vector3(size.x, 1, size.y)

func _shelf(pos: Vector3) -> void:
	var rust := HorrorArt.surface("rusted_iron")
	for x in [-0.7, 0.7]:
		for z in [-0.35, 0.35]: box(pos + Vector3(x, 1.15, z), Vector3(0.04, 2.3, 0.04), rust)
	for y in [0.15, 0.85, 1.55, 2.22]:
		box(pos + Vector3(0, y, 0), Vector3(1.5, 0.04, 0.8), rust)
		for i in 2:
			box(pos + Vector3(-0.35 + i * 0.65, y + 0.18, 0), Vector3(0.45, 0.33, 0.48), HorrorArt.surface("rotten_wood"), Vector3(0, rng.randf_range(-0.07, 0.07), 0))

func _rooms() -> void:
	var rust := HorrorArt.surface("rusted_iron")
	var wood := HorrorArt.surface("rotten_wood")
	var cloth := HorrorArt.surface("torn_fabric")
	var dark := HorrorArt.solid(Color("191d1b"))
	# Infirmary: abandoned bed, stained mattress and broken window framing.
	box(Vector3(-8, 0.5, -1.05), Vector3(1.6, 0.1, 0.85), rust)
	box(Vector3(-8, 0.65, -1.05), Vector3(1.5, 0.22, 0.78), cloth)
	for x in [-8.7, -7.3]:
		for z in [-1.4, -0.7]: pipe(Vector3(x, 0, z), Vector3(x, 0.55, z), 0.035, rust)
	# Window is an opaque wall inset, no fake transparency through solid geometry.
	box(Vector3(-9.86, 1.9, 0), Vector3(0.05, 1.25, 1.6), dark)
	for z in [-0.8, 0, 0.8]: box(Vector3(-9.82, 1.9, z), Vector3(0.06, 1.3, 0.045), wood)
	# Storage side aisles; central navigation left free.
	_shelf(Vector3(-8.3, 0, -17.2))
	_shelf(Vector3(-8.3, 0, -14.8))
	box(Vector3(-6.6, 0.55, -17), Vector3(0.85, 1.1, 0.85), wood)
	box(Vector3(-6.6, 1.16, -17), Vector3(1, 0.13, 1), cloth, Vector3(0.03, 0.08, 0.07))
	# Workshop machines: press, motor housing, tools and short hanging chain.
	box(Vector3(8.7, 0.65, -6.8), Vector3(1.1, 1.3, 0.65), rust)
	box(Vector3(8.7, 1.45, -6.8), Vector3(0.16, 0.6, 0.4), rust)
	box(Vector3(8.7, 1.8, -6.8), Vector3(1, 0.12, 0.65), rust)
	for i in 9:
		var link := TorusMesh.new()
		link.inner_radius = 0.035
		link.outer_radius = 0.055
		link.rings = 8
		link.ring_segments = 4
		piece(link, Vector3(6.5, 2.9 - i * 0.085, -9.4), rust, Vector3(PI / 2, (i % 2) * PI / 2, 0))
	for i in 4:
		pipe(Vector3(7.2 + i * 0.2, 1.5, -9.85), Vector3(7.2 + i * 0.2, 1.85, -9.85), 0.018, rust, 6)
	# Security analogue consoles and dangling cables.
	for x in [6.3, 7.5]:
		box(Vector3(x, 1.25, -25.5), Vector3(0.65, 0.45, 0.42), rust)
		box(Vector3(x, 1.27, -25.26), Vector3(0.52, 0.33, 0.025), dark)
	for i in 6:
		box(Vector3(8.8, 1.7 + i * 0.07, -25.78), Vector3(0.6, 0.025, 0.025), dark)
	# Power room: tanks and warm industrial indicators.
	for x in [-8.8, -7.8]:
		pipe(Vector3(x, 0.1, -33.3), Vector3(x, 2.4, -33.3), 0.24, rust, 14)
		pipe(Vector3(x, 2.4, -33.3), Vector3(x, 2.65, -33.3), 0.07, rust)
	light_at(Vector3(-7.3, 2.4, -31.4), Color("b19a64"), 0.45, 4)
	# End passage: collapsed edge timbers leave >2 m central clearance.
	for side in [-1, 1]:
		box(Vector3(side * 1.65, 0.65, -39), Vector3(0.18, 1.7, 0.16), wood, Vector3(0.12, 0, side * 0.2))
		box(Vector3(side * 1.5, 0.12, -40), Vector3(0.6, 0.16, 1.2), wood, Vector3(0, side * 0.25, 0))
	light_at(Vector3(0, 2.5, -40.7), Color(0.46, 0.51, 0.45), 0.7, 4.5)

func _story_sign(id: String, text: String, pos: Vector3, angle: float, size: Vector2, type: String = "paper") -> void:
	var sign := WorldSign3D.new()
	sign.sign_id = id
	sign.text = text
	sign.position = pos
	sign.rotation.y = angle
	sign.dimensions = size
	sign.sign_type = type
	add_child(sign)

func _room_stories() -> void:
	var rust := HorrorArt.surface("rusted_iron")
	var wood := HorrorArt.surface("rotten_wood")
	var cloth := HorrorArt.surface("torn_fabric")
	# Leave all objective approaches, doorways and hide exits free.
	_story_sign("ward", "ENFERMARIA 01\nNÃO REMOVA OS PROTETORES AURICULARES", Vector3(-9.76, 2.1, 0), PI / 2, Vector2(1.5, 0.55))
	_story_sign("patient", "LEITO 04 / TRANSFERIDO\nNENHUM SINAL DE RESPOSTA À VOZ", Vector3(-8, 1.45, -1.83), 0, Vector2(1.25, 0.42))
	# Medical trolley and folded linen remain against the west wall.
	for y in [0.3, 0.8]: box(Vector3(-9.45, y, 1.1), Vector3(0.65, 0.045, 0.7), rust)
	for z in [0.82, 1.38]: pipe(Vector3(-9.6, 0.1, z), Vector3(-9.6, 1.1, z), 0.025, rust, 6)
	box(Vector3(-9.45, 0.92, 1.1), Vector3(0.48, 0.2, 0.5), cloth)
	_story_sign("maintenance_warning", "MANUTENÇÃO / 02\nDESLIGUE O CIRCUITO ANTES DE OPERAR", Vector3(9.76, 2.0, -8), -PI / 2, Vector2(1.6, 0.55), "danger")
	box(Vector3(7.7, 1.95, -9.80), Vector3(1.5, 0.75, 0.035), wood)
	for i in 6:
		pipe(Vector3(7.13 + i * 0.22, 1.7, -9.74), Vector3(7.13 + i * 0.22, 2.18 - (i % 2) * 0.1, -9.74), 0.022, rust, 6)
	_story_sign("storage_tags", "DEPÓSITO / 03\nCAIXAS DEVOLVIDAS: NÃO ABRIR", Vector3(-9.76, 2.0, -16), PI / 2, Vector2(1.5, 0.5))
	for index in 3:
		box(Vector3(-9.45, 0.3 + index * 0.5, -17.3), Vector3(0.6, 0.45, 0.65), wood, Vector3(0, index * 0.04, 0))
	_story_sign("physical_map", "INSTALAÇÃO 04 / PLANTA DE SERVIÇO\nENFERMARIA → CORREDOR\nMANUTENÇÃO → GALERIA → SEGURANÇA\nDEPÓSITO → OFICINA [CHAVE]\nENERGIA → SAÍDA DE SERVIÇO", Vector3(9.76, 1.9, -24), -PI / 2, Vector2(1.8, 1.05), "map")
	_story_sign("security_log", "SEGURANÇA / 04\nCÂMERAS SEM SINAL DESDE 03:17", Vector3(7, 2.2, -25.76), 0, Vector2(1.55, 0.4))
	_story_sign("electrical_warning", "PERIGO / ALTA TENSÃO\nFUSÍVEL → PAINEL → GERADOR\nEM FALHA: REARME O GERADOR", Vector3(-9.76, 1.8, -32), PI / 2, Vector2(1.6, 0.7), "danger")
	for i in 4:
		box(Vector3(-3.1 + i * 0.22, 1.45, -33.78), Vector3(0.16, 0.5, 0.12), rust)
		pipe(Vector3(-3.1 + i * 0.22, 1.2, -33.8), Vector3(-3.1 + i * 0.22, 0.25, -33.8), 0.012, rust, 6)
	light_at(Vector3(-9, 2.5, 0), Color("8b9b80"), 0.22, 3)
	light_at(Vector3(9, 2.5, -24), Color("829b9c"), 0.2, 3)

func _exterior() -> void:
	var wood := HorrorArt.surface("rotten_wood")
	var rust := HorrorArt.surface("rusted_iron")
	var concrete := HorrorArt.surface("aged_concrete")
	var mud := HorrorArt.surface("mud_leaves")
	# Roof silhouette and facade stay outside existing interior walls.
	box(Vector3(-4, 3.12, 0), Vector3(12.2, 0.15, 4.5), rust, Vector3(0, 0, 0.035))
	for x in [-9.8, -2.1, 2.1]: box(Vector3(x, 1.55, 2.16), Vector3(0.17, 3.1, 0.24), wood)
	box(Vector3(0, 2.7, 2.13), Vector3(4.6, 0.6, 0.14), wood)
	# Gravel ruts: layered opaque patches, not a costly transparent decal stack.
	for x in [-0.72, 0.72]: box(Vector3(x, -0.012, 12), Vector3(0.34, 0.018, 17), HorrorArt.surface("organic_residue"))
	for z in range(4, 22, 2):
		for side in [-1, 1]:
			var x: float = side * 10.8
			box(Vector3(x, 0.7, z), Vector3(0.12, 1.4, 0.13), wood, Vector3(0, 0, side * rng.randf_range(-0.09, 0.09)))
			for y in [0.45, 1.05]: box(Vector3(x, y, z + 0.8), Vector3(0.09, 0.12, 1.9), wood)
	for x in range(-10, 11, 2):
		box(Vector3(x, 0.65, 21), Vector3(0.12, 1.3, 0.12), wood)
		for y in [0.4, 1.0]: box(Vector3(x + 0.8, y, 21), Vector3(1.9, 0.12, 0.1), wood)
	# Rusted locked gate and leaning utility pole.
	for x in [-1.3, 1.3]: pipe(Vector3(x, 0, 19.8), Vector3(x, 2.0, 19.8), 0.06, rust)
	for i in 10: pipe(Vector3(-1.2 + i * 0.26, 0.25, 19.8), Vector3(-1.2 + i * 0.26, 1.75, 19.8), 0.018, rust, 6)
	for y in [0.3, 1.7]: pipe(Vector3(-1.3, y, 19.8), Vector3(1.3, y, 19.8), 0.025, rust)
	pipe(Vector3(-3, 0, 9), Vector3(-3.3, 4.5, 9), 0.09, wood)
	pipe(Vector3(-3.3, 4.5, 9), Vector3(-2.3, 4.5, 9), 0.04, rust)
	box(Vector3(-2.3, 4.4, 9), Vector3(0.45, 0.12, 0.25), rust)
	light_at(Vector3(-2.3, 4.2, 9), Color("b19a64"), 1.25, 8)
	light_at(Vector3(3, 5, 16), Color(0.44, 0.49, 0.53), 0.6, 16)
	# Withered vegetation is batched into a single MultiMesh draw.
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertices := [Vector3(-0.018, 0, 0), Vector3(0.018, 0, 0), Vector3(0.01, 1.1, 0), Vector3(-0.018, 0, 0), Vector3(0.01, 1.1, 0), Vector3(-0.025, 0.8, 0)]
	for v in vertices: tool.add_vertex(v)
	for side in [-1, 1]:
		for y in [0.35, 0.6, 0.8]:
			for v in [Vector3(0, y, 0), Vector3(side * 0.32, y + 0.14, 0.06), Vector3(side * 0.26, y - 0.10, 0.025)]: tool.add_vertex(v)
	tool.generate_normals()
	var plant := tool.commit()
	grass = MultiMeshInstance3D.new()
	grass.name = "DeadVegetation"
	grass.material_override = HorrorArt.surface("rotten_wood")
	grass.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = plant
	multi.instance_count = 220
	for i in multi.instance_count:
		var side: float = -1 if i % 2 else 1
		var p := Vector3(side * rng.randf_range(2.2, 10), 0, rng.randf_range(4, 20))
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * rng.randf_range(0.65, 1.5))
		multi.set_instance_transform(i, Transform3D(basis, p))
	grass.multimesh = multi
	add_child(grass)
	for i in 12:
		box(Vector3(rng.randf_range(-9, 9), 0.025, rng.randf_range(5, 20)), Vector3(0.4, 0.04, 0.3), mud, Vector3(0, rng.randf() * TAU, 0))
	# Bare trees beyond the fence break the skyline without adding walkable routes.
	for i in 14:
		var p := Vector3((-1 if i % 2 else 1) * rng.randf_range(12, 17), 0, rng.randf_range(7, 27))
		var top := p + Vector3(rng.randf_range(-0.5, 0.5), rng.randf_range(4, 6), 0)
		pipe(p, top, 0.12, wood, 7)
		for branch in 3:
			var origin := p.lerp(top, 0.45 + branch * 0.16)
			pipe(origin, origin + Vector3(rng.randf_range(-1.6, 1.6), rng.randf_range(0.7, 1.8), rng.randf_range(-1.2, 1.2)), 0.04, wood, 6)

func _basement() -> void:
	var rust := HorrorArt.surface("rusted_iron")
	var organic := HorrorArt.surface("organic_residue")
	for z in [-35, -34.7, -29.1]: pipe(Vector3(-21.8, -0.2, z), Vector3(-16.1, -0.2, z), 0.085, rust)
	for x in [-21, -19, -17]:
		_puddle(Vector3(x, -1.785, -32.5), Vector2(1.3, 1.6))
		box(Vector3(x, -1.15, -35.85), Vector3(1.2, 0.9, 0.014), organic)
	light_at(Vector3(-20, 0.65, -31), Color("b19a64"), 0.45, 5.2)
	# Simple guardrail follows the ramp; no extra physics simulation.
	for side in [-1, 1]: pipe(Vector3(-10.2, 0.85, -32 + side * 0.95), Vector3(-15.7, -0.85, -32 + side * 0.95), 0.025, rust)

func apply_quality() -> void:
	HorrorArt.set_quality(int(Game.settings.quality))
	if grass: grass.multimesh.visible_instance_count = [80, 160, 220][int(Game.settings.quality)]

func _process(delta: float) -> void:
	age += delta
	if lamps.size() > 2:
		# One slow isolated dip every 13 s; no strobing.
		var cycle := fmod(age, 13.0)
		lamps[2].light_energy = 1.25 * (0.65 if cycle > 12.5 else 1.0)
