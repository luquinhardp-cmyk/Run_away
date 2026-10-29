extends Node3D
signal message(text: String)
var region: NavigationRegion3D
var geometry: Node3D
var cells: Dictionary = {}
var lights: Array[OmniLight3D] = []
var age := 0.0
var scare_done := false
var wall_material: StandardMaterial3D
var floor_material: StandardMaterial3D
var metal: StandardMaterial3D
var interact_script = preload("res://scripts/interactions/interactable.gd")
var nav_ready := false

func _ready() -> void:
	wall_material = material(Color(0.18, 0.23, 0.23))
	floor_material = material(Color(0.105, 0.135, 0.14))
	metal = material(Color(0.23, 0.19, 0.14))
	var noise := FastNoiseLite.new()
	noise.frequency = 0.13
	var texture := NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.noise = noise
	wall_material.albedo_texture = texture
	wall_material.uv1_scale = Vector3(2, 2, 2)
	region = NavigationRegion3D.new()
	var nav := NavigationMesh.new()
	nav.agent_radius = 0.45
	nav.agent_height = 2.5
	nav.agent_max_climb = 0.2
	nav.cell_size = 0.15
	nav.cell_height = 0.1
	nav.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav.geometry_collision_mask = 1
	region.navigation_mesh = nav
	add_child(region)
	NavigationServer3D.map_set_cell_size(get_world_3d().navigation_map, 0.15)
	NavigationServer3D.map_set_cell_height(get_world_3d().navigation_map, 0.1)
	geometry = Node3D.new()
	region.add_child(geometry)
	# Logical tile plan. z decreases toward the final escape.
	for z in range(0, 11): cells[Vector2i(0, z)] = "CORREDOR"
	for entry in [[-1, 0, "ENFERMARIA"], [-2, 0, "ENFERMARIA"], [1, 2, "MANUTENÇÃO"], [2, 2, "MANUTENÇÃO"], [-1, 4, "DEPÓSITO"], [-2, 4, "DEPÓSITO"], [1, 6, "SEGURANÇA"], [2, 6, "SEGURANÇA"], [-1, 8, "ENERGIA"], [-2, 8, "ENERGIA"]]:
		cells[Vector2i(entry[0], entry[1])] = entry[2]
	for cell in cells: _tile(cell)
	_environment()
	_props()
	_items()
	# Bake with closed doors excluded: their colliders are added after baking.
	region.bake_navigation_mesh(false)
	nav_ready = true
	_doors()
	Game.updated.connect(_quality)
	_quality()

func material(color: Color, emission: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	if emission:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.6
	return mat

func box(pos: Vector3, size: Vector3, mat: Material, solid: bool = true, parent: Node3D = null) -> Node3D:
	if parent == null: parent = geometry
	var node: Node3D = StaticBody3D.new() if solid else Node3D.new()
	parent.add_child(node)
	node.position = pos
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	mesh.material_override = mat
	node.add_child(mesh)
	if solid:
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		node.add_child(collision)
	return node

func _tile(cell: Vector2i) -> void:
	var center := Vector3(cell.x * 4, 0, -cell.y * 4)
	box(center + Vector3(0, -0.15, 0), Vector3(4, 0.3, 4), floor_material)
	box(center + Vector3(0, 3.1, 0), Vector3(4, 0.2, 4), wall_material)
	for direction in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var neighbor: Vector2i = cell + direction
		var edge := center + Vector3(direction.x * 2, 1.5, -direction.y * 2)
		var along_x: bool = direction.x == 0
		if not cells.has(neighbor):
			box(edge, Vector3(4.1, 3, 0.18) if along_x else Vector3(0.18, 3, 4.1), wall_material)
		elif cell.x == 0 and direction.x != 0:
			# Doorways 1.8 m wide; same opening serves navigation and physics.
			for z_offset in [-1.48, 1.48]: box(edge + Vector3(0, 0, z_offset), Vector3(0.18, 3, 1.05), wall_material)
			box(edge + Vector3(0, 1.32, 0), Vector3(0.18, 0.36, 1.9), wall_material)
			var label_pos := edge + Vector3(-direction.x * 0.16, 1.12, 0)
			_label(cells[neighbor], label_pos, -PI / 2 if direction.x < 0 else PI / 2, 24)
	if cell.x == 0:
		box(center + Vector3(-1.85, 2.72, 0), Vector3(0.1, 0.1, 4), metal, false)
		box(center + Vector3(1.82, 0.18, 0), Vector3(0.08, 0.08, 4), metal, false)
		# Broken strips and floor seams, cheap unlit details.
		box(center + Vector3(0, 0.008, 1.8), Vector3(3.7, 0.008, 0.025), metal, false)
	if cell.y % 2 == 0 and cell.x == 0 or abs(cell.x) == 2:
		var light := OmniLight3D.new()
		light.position = center + Vector3(0, 2.65, 0)
		light.omni_range = 5.6
		light.light_energy = 0.75
		light.light_color = Color(0.52, 0.75, 0.68) if cell.x == 0 else Color(0.87, 0.62, 0.36)
		light.shadow_enabled = false
		add_child(light)
		lights.append(light)
		box(center + Vector3(0, 2.98, 0), Vector3(0.9, 0.04, 0.16), material(light.light_color, true), false)

func _label(text: String, pos: Vector3, angle: float = 0.0, font_size: int = 36) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = pos
	label.rotation.y = angle
	label.font_size = font_size
	label.pixel_size = 0.007
	label.modulate = Color(0.72, 0.9, 0.8)
	label.no_depth_test = false
	add_child(label)

func _environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.008, 0.014, 0.018)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.27, 0.4, 0.44)
	environment.ambient_light_energy = 0.24
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.04, 0.075, 0.08)
	environment.fog_density = 0.012
	world.environment = environment
	add_child(world)
	_label("SAÍDA / 40 m   →", Vector3(0, 2.4, 1.86), PI, 32)
	_label("SETOR 04  /  ACESSO RESTRITO", Vector3(0, 2.6, -41.85), 0, 30)
	var ambient := AudioStreamPlayer3D.new()
	ambient.stream = load("res://assets/audio/ambient.wav")
	ambient.bus = "Effects"
	ambient.volume_db = -23
	ambient.position = Vector3(0, 2, -18)
	ambient.max_distance = 60
	add_child(ambient)
	ambient.finished.connect(ambient.play)
	ambient.play()
	var music := AudioStreamPlayer.new()
	music.stream = load("res://assets/audio/drone.wav")
	music.bus = "Music"
	music.volume_db = -28
	add_child(music)
	music.finished.connect(music.play)
	music.play()

func _props() -> void:
	# Furniture stays clear of the navigation route.
	for pos in [Vector3(-8, 0.65, 0.8), Vector3(8, 0.65, -9), Vector3(8, 0.65, -25)]:
		box(pos, Vector3(2, 0.15, 0.8), metal)
		for x in [-0.8, 0.8]: box(pos + Vector3(x, -0.32, 0), Vector3(0.1, 0.65, 0.7), metal)
	for pos in [Vector3(-8.6, 0.8, -17), Vector3(-8.6, 0.8, -15), Vector3(-7, 0.45, -33)]:
		box(pos, Vector3(1, 1.6, 0.9), metal)
	for z in [-4, -12, -20, -28, -36]:
		box(Vector3(-1.86, 1.1, z), Vector3(0.05, 0.7, 0.9), material(Color(0.25, 0.29, 0.24)), false)
		for i in 3:
			box(Vector3(1.1 + i * 0.1, 0.01, z + i * 0.2), Vector3(0.3, 0.01, 0.18), material(Color(0.32, 0.32, 0.25)), false)

func interaction(kind: String, id: String, title: String, pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var node := StaticBody3D.new()
	node.set_script(interact_script)
	node.kind = kind
	node.item_id = id
	node.title = title
	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	mesh.material_override = material(color, kind == "pickup")
	node.add_child(mesh)
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	node.add_child(collision)
	node.position = pos
	node.notified.connect(func(text: String): message.emit(text))
	add_child(node)
	return node

func _items() -> void:
	interaction("pickup", "lanterna", "Lanterna", Vector3(-7.8, 0.85, 0.8), Vector3(0.45, 0.22, 0.22), Color(0.65, 0.85, 0.62))
	interaction("pickup", "fusivel", "Fusível", Vector3(7.7, 0.85, -9), Vector3(0.18, 0.3, 0.18), Color(0.95, 0.59, 0.22))
	interaction("pickup", "cartao", "Cartão de segurança", Vector3(7.8, 0.85, -25), Vector3(0.32, 0.07, 0.24), Color(0.35, 0.78, 0.85))
	interaction("generator", "generator", "Instalar fusível / ligar gerador", Vector3(-8, 1.0, -32), Vector3(1.3, 2, 0.8), Color(0.3, 0.35, 0.2))
	interaction("exit", "exit", "Usar cartão / escapar", Vector3(0, 1.3, -41.7), Vector3(1.8, 2.6, 0.2), Color(0.18, 0.37, 0.3))
	for pos in [Vector3(-5, 1, 1.2), Vector3(-5, 1, -15), Vector3(5, 1, -7), Vector3(-5, 1, -31)]:
		interaction("hide", "", "Esconder-se no armário", pos, Vector3(1.1, 2, 1.0), Color(0.12, 0.19, 0.21))
	var document := interaction("document", "note", "Ler anotação", Vector3(-8.5, 1, -1.7), Vector3(0.6, 0.6, 0.08), Color(0.65, 0.59, 0.4))
	document.message = "ELE ESCUTA. Fusível: manutenção. Gerador: energia. Cartão: segurança.\nUse os armários, mas não grite. Fones de ouvido são recomendados."
	interaction("drawer", "drawer", "Abrir gaveta", Vector3(8, 0.4, -7), Vector3(1.3, 0.6, 0.65), Color(0.25, 0.2, 0.14))
	interaction("object", "can", "Derrubar lata / distrair", Vector3(-4, 0.7, -17.2), Vector3(0.25, 0.4, 0.25), Color(0.5, 0.3, 0.2))

func _doors() -> void:
	for info in [[2, -8, "maintenance"], [-2, -16, "storage"], [2, -24, "security"], [-2, -32, "power"]]:
		var door := interaction("door", info[2], "Abrir porta", Vector3(info[0], 1.3, info[1]), Vector3(0.15, 2.6, 1.8), Color(0.22, 0.27, 0.24))
		door.add_to_group("doors")

func _quality() -> void:
	for light in lights: light.omni_range = 4.8 if Game.settings.quality < 1 else 5.6
	get_viewport().scaling_3d_scale = [0.65, 0.85, 1.0][int(Game.settings.quality)]

func _process(delta: float) -> void:
	if not Game.playing: return
	age += delta
	if lights.size() > 2:
		lights[2].light_energy = 0.65 + sin(age * 17) * sin(age * 5) * 0.18
	if not scare_done and is_instance_valid(Game.player) and Game.player.global_position.z < -12:
		scare_done = true
		Sound.at("metal", Vector3(-5, 1, -16), -10 - (1 - Game.settings.scares) * 22)
		NoiseBus.emit_noise(self, 0.5, "evento_ambiental", 20)
		message.emit("Um impacto vem do depósito. Algo se move no corredor.")
