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
var events: Node
var nav_update_pending := false
var nav_rebuilds := 0
var nav_gates: Dictionary = {}
var horror: Node
var horror_light_multiplier := 1.0

func _ready() -> void:
	HorrorArt.set_quality(int(Game.settings.quality))
	wall_material = HorrorArt.surface("aged_concrete")
	floor_material = HorrorArt.surface("cracked_floor")
	metal = HorrorArt.surface("rusted_iron")
	region = NavigationRegion3D.new()
	var nav := NavigationMesh.new()
	nav.agent_radius = 0.45
	nav.agent_height = 2.5
	nav.agent_max_climb = 0.2
	nav.cell_size = 0.15
	nav.cell_height = 0.1
	nav.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav.geometry_collision_mask = 1 | 32
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
	# A slower industrial loop connects maintenance, workshop and security.
	for z in range(2, 7): cells[Vector2i(3, z)] = "GALERIA LATERAL"
	for x in [1, 2]: cells[Vector2i(x, 4)] = "OFICINA"
	for cell in cells: _tile(cell)
	_environment()
	_props()
	_annex_geometry()
	_items()
	# Bake with closed doors excluded: their colliders are added after baking.
	region.bake_navigation_mesh(false)
	nav_ready = true
	_doors()
	_expansion_objects()
	_navigation_furniture()
	_sync_accessibility()
	Game.updated.connect(_sync_accessibility)
	_search_points()
	events = Node.new()
	events.set_script(preload("res://scripts/world/events.gd"))
	add_child(events)
	horror = Node.new()
	horror.set_script(preload("res://scripts/horror/horror_director.gd"))
	add_child(horror)
	var metrics := Node.new()
	metrics.set_script(preload("res://scripts/world/metrics.gd"))
	add_child(metrics)
	var art := Node3D.new()
	art.set_script(preload("res://scripts/systems/facility_art.gd"))
	add_child(art)
	# Keep geometry collision bodies for navigation/occlusion, batch their rendering.
	var batches := Node3D.new()
	batches.name = "ArchitectureBatches"
	add_child(batches)
	HorrorArt.merge_static(geometry, batches)
	Game.updated.connect(_quality)
	_quality()
	var physics := Node.new()
	physics.set_script(preload("res://scripts/physics/world_physics.gd"))
	add_child(physics)

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
		PhysicsSurfaces.attach(node, PhysicsSurfaces.identify(mat))
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		node.add_child(collision)
	return node

func _tile(cell: Vector2i) -> void:
	var center := Vector3(cell.x * 4, 0, -cell.y * 4)
	box(center + Vector3(0, -0.15, 0), Vector3(4, 0.3, 4), floor_material)
	box(center + Vector3(0, 3.1, 0), Vector3(4, 0.2, 4), HorrorArt.surface("peeling_plaster"))
	for direction in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var neighbor: Vector2i = cell + direction
		var edge := center + Vector3(direction.x * 2, 1.5, -direction.y * 2)
		var along_x: bool = direction.x == 0
		if not cells.has(neighbor):
			var entrance: bool = cell == Vector2i.ZERO and direction == Vector2i(0, -1)
			var basement: bool = cell == Vector2i(-2, 8) and direction == Vector2i(-1, 0)
			if entrance or basement:
				for offset in [-1.52, 1.52]:
					box(edge + (Vector3(offset, 0, 0) if entrance else Vector3(0, 0, offset)), Vector3(0.95, 3, 0.18) if entrance else Vector3(0.18, 3, 0.95), wall_material)
				box(edge + Vector3.UP * 1.35, Vector3(2.1, 0.3, 0.18) if entrance else Vector3(0.18, 0.3, 2.1), wall_material)
				continue
			box(edge, Vector3(4.1, 3, 0.18) if along_x else Vector3(0.18, 3, 4.1), wall_material)
		elif cell.x == 0 and direction.x != 0:
			# Doorways 1.8 m wide; same opening serves navigation and physics.
			for z_offset in [-1.48, 1.48]: box(edge + Vector3(0, 0, z_offset), Vector3(0.18, 3, 1.05), wall_material)
			box(edge + Vector3(0, 1.32, 0), Vector3(0.18, 0.36, 1.9), wall_material)
			var label_pos := edge + Vector3(-direction.x * 0.16, 1.12, 0)
			_label(cells[neighbor], label_pos, PI / 2 if direction.x < 0 else -PI / 2, 24)
	if cell.x == 0:
		box(center + Vector3(-1.85, 2.72, 0), Vector3(0.1, 0.1, 4), metal, false)
		box(center + Vector3(1.82, 0.18, 0), Vector3(0.08, 0.08, 4), metal, false)
		# Broken strips and floor seams, cheap unlit details.
		box(center + Vector3(0, 0.008, 1.8), Vector3(3.7, 0.008, 0.025), metal, false)
	if cell.y % 2 == 0 and cell.x == 0 or abs(cell.x) == 2:
		var light := OmniLight3D.new()
		light.position = center + Vector3(0, 2.65, 0)
		light.omni_range = 5.6
		light.light_energy = 1.15 if cell.x == 0 else 1.35
		light.light_color = Color("b19a64") if cell.x == 0 else Color(0.64, 0.55, 0.39)
		light.shadow_enabled = false
		add_child(light)
		lights.append(light)
		box(center + Vector3(0, 2.98, 0), Vector3(0.52, 0.04, 0.12), HorrorArt.solid(light.light_color, 0.5), false)

func _label(text: String, pos: Vector3, angle: float = 0.0, font_size: int = 36) -> void:
	var sign := WorldSign3D.new()
	sign.text = text
	sign.sign_id = "sign_" + str(get_tree().get_nodes_in_group("world_signs").size())
	sign.position = pos
	sign.rotation.y = angle
	sign.dimensions = Vector2(1.65 if font_size < 30 else 2.3, 0.38)
	sign.sign_type = "emergency" if text.contains("SAÍDA") else ("danger" if text.contains("RESTRITO") or text.contains("FUSÍVEL") else "metal")
	sign.illuminated = sign.sign_type == "emergency"
	sign.post_mounted = pos.z > 4
	add_child(sign)

func _environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("0b0d0c")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.48, 0.49, 0.43)
	environment.ambient_light_energy = 0.38
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.06, 0.07, 0.055)
	environment.fog_density = 0.017
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
	if not node.is_queued_for_deletion(): _decorate_interaction(node)
	return node

func _items() -> void:
	interaction("pickup", "lanterna", "Lanterna", Vector3(-7.8, 0.79, 0.8), Vector3(0.34, 0.12, 0.12), Color(0.65, 0.85, 0.62))
	interaction("pickup", "fusivel", "Fusível", Vector3(7.7 if Game.world.variant == 0 else 6.6, 0.76, -9), Vector3(0.18, 0.07, 0.07), Color(0.95, 0.59, 0.22))
	interaction("pickup", "cartao", "Cartão de segurança", Vector3(7.8, 0.765, -25), Vector3(0.32, 0.07, 0.24), Color(0.35, 0.78, 0.85))
	interaction("generator", "generator", "Instalar fusível / ligar gerador", Vector3(-8, 1.0, -32), Vector3(1.3, 2, 0.8), Color(0.3, 0.35, 0.2))
	interaction("exit", "exit", "Usar cartão / escapar", Vector3(0, 1.3, -41.7), Vector3(1.8, 2.6, 0.2), Color(0.18, 0.37, 0.3))
	for pos in [Vector3(-5, 1, 1.2), Vector3(-5, 1, -15), Vector3(5, 1, -7), Vector3(-5, 1, -31)]:
		var locker := interaction("hide", "locker_%d_%d" % [int(pos.x), int(pos.z)], "Esconder-se no armário", pos, Vector3(1.1, 2, 1.0), Color(0.12, 0.19, 0.21))
		locker.rotation.y = PI / 2 if pos.x < 0 else -PI / 2
	var document := interaction("document", "note", "Ler anotação", Vector3(-8.5, 1, -1.7), Vector3(0.6, 0.6, 0.08), Color(0.65, 0.59, 0.4))
	document.message = "ELE ESCUTA. Fusível: manutenção → painel e gerador: energia → cartão: segurança → saída.\nGaleria lateral conecta manutenção e segurança. Chave da oficina no depósito abre o atalho central. Q arremessa peças. Rádio e alarme atraem para sua fonte real."
	interaction("drawer", "drawer", "Abrir gaveta", Vector3(5.8, 0.4, -9.3), Vector3(1.3, 0.6, 0.65), Color(0.25, 0.2, 0.14))
	# The can is now a real body, spawned by world_physics after geometry is built.
	box(Vector3(5.8,0.1,-9.3),Vector3(1.35,0.2,0.7),HorrorArt.surface("rotten_wood"))
	box(Vector3(5.8,0.56,-9.3),Vector3(1.35,0.04,0.7),HorrorArt.surface("damp_wood"))
	for side in [-1,1]: box(Vector3(5.8+side*0.67,0.38,-9.3),Vector3(0.04,0.4,0.7),HorrorArt.surface("damp_wood"))

func _doors() -> void:
	for info in [[2, -8, "maintenance"], [-2, -16, "storage"], [2, -24, "security"], [-2, -32, "power"]]:
		var door := interaction("door", info[2], "Abrir porta", Vector3(info[0], 1.3, info[1]), Vector3(0.15, 2.6, 1.8), Color(0.22, 0.27, 0.24))
		door.add_to_group("doors")

func _quality() -> void:
	HorrorArt.set_quality(int(Game.settings.quality))
	for light in lights: light.omni_range = 4.8 if Game.settings.quality < 1 else 5.6
	get_viewport().scaling_3d_scale = [0.65, 0.85, 1.0][int(Game.settings.quality)]

func _process(delta: float) -> void:
	if not Game.playing: return
	age += delta
	for light in lights:
		light.light_energy = (1.15 if Game.power else (0.12 if Game.world.get("blackout", false) else 0.55)) * horror_light_multiplier
	if Game.settings.get("light_variation", true) and lights.size() > 2 and fmod(age, 17.0) > 16.8: lights[2].light_energy *= 0.75

func find_interaction(id: String) -> Node3D:
	for child in get_children():
		if child.get("item_id") == id: return child
	return null

func request_navigation_update() -> void:
	if nav_update_pending: return
	nav_update_pending = true
	_rebuild_navigation.call_deferred()

func _navigation_furniture() -> void:
	# Interactions live outside the region for stable IDs. Mirror only anchored
	# hulls into its bake input; layer 32 is invisible to gameplay collisions.
	for item in get_children():
		if item.get("kind") not in ["hide","generator","radio","alarm","fuse_panel"]: continue
		var proxy := StaticBody3D.new()
		proxy.name = "NavFixed_" + item.item_id
		proxy.collision_layer = 32
		proxy.collision_mask = 0
		proxy.transform = item.transform
		var shape := CollisionShape3D.new()
		shape.shape = item.collider.shape
		proxy.add_child(shape)
		geometry.add_child(proxy)
	request_navigation_update()

func _rebuild_navigation() -> void:
	await get_tree().process_frame
	region.bake_navigation_mesh(false)
	nav_rebuilds += 1
	nav_update_pending = false

func _sync_accessibility() -> void:
	var changed := false
	for door in get_tree().get_nodes_in_group("doors"):
		if not is_ancestor_of(door): continue
		var blocked: bool = not door.open and not door._door_unlocked()
		if blocked and not nav_gates.has(door.item_id):
			var gate := box(door.position, Vector3(0.15, 2.6, 1.8), metal)
			gate.visible = false
			nav_gates[door.item_id] = gate
			changed = true
		elif not blocked and nav_gates.has(door.item_id):
			nav_gates[door.item_id].queue_free()
			nav_gates.erase(door.item_id)
			changed = true
	if changed: request_navigation_update()

func _search_points() -> void:
	for cell in cells:
		var point := Marker3D.new()
		point.position = Vector3(cell.x * 4, 0.1, -cell.y * 4)
		add_child(point)
		point.add_to_group("search_points")

func _expansion_objects() -> void:
	interaction("fuse_panel", "fuse_panel", "Instalar fusível", Vector3(-5.3, 1.4, -33.7), Vector3(0.7, 0.9, 0.2), Color(0.25, 0.3, 0.2))
	_label("PAINEL / FUSÍVEL", Vector3(-5.3, 2.2, -33.7), 0, 22)
	interaction("radio", "radio", "Ligar rádio", Vector3(12, 0.9, -12), Vector3(0.5, 0.4, 0.25), Color(0.3, 0.25, 0.2))
	interaction("alarm", "alarm", "Ligar alarme", Vector3(13.7, 1.4, -22), Vector3(0.35, 0.4, 0.25), Color(0.7, 0.2, 0.12))
	box(Vector3(12, 0.35, -12), Vector3(0.8, 0.7, 0.55), metal)
	for z in [-8, -16, -24]:
		var light := OmniLight3D.new()
		light.position = Vector3(12, 2.6, z)
		light.omni_range = 5
		light.light_color = Color("ad9565")
		light.shadow_enabled = false
		add_child(light)
		lights.append(light)
	interaction("pickup", "chave_oficina", "Chave da oficina", Vector3(-7.5, 0.9, -14.8), Vector3(0.22, 0.12, 0.12), Color(0.8, 0.6, 0.2))
	box(Vector3(-7.5,0.81,-14.8),Vector3(0.5,0.06,0.35),HorrorArt.surface("damp_wood"),true,self)
	box(Vector3(-7.5,0.39,-14.8),Vector3(0.3,0.78,0.25),HorrorArt.surface("rotten_wood"))
	var door := interaction("door", "workshop", "Destrancar oficina", Vector3(2, 1.3, -16), Vector3(0.15, 2.6, 1.8), Color(0.3, 0.25, 0.2))
	door.add_to_group("doors")
	# Gate only the short central connector; the long loop remains usable without a key.
	_label("OFICINA / ROTA LATERAL", Vector3(10.15, 2.4, -16), PI / 2, 24)
	_label("MANUTENÇÃO ←    SEGURANÇA →", Vector3(13.85, 2.1, -16), -PI / 2, 22)
	var profile := Game.difficulty_profile()
	for index in profile.throwable_supply:
		var pos := Vector3(6 + (index % 2) * 1.2, 0.1, -8 - int(index / 2) * 4)
		interaction("throw_pickup", "metal_" + str(index), "Coletar peça metálica", pos, Vector3(0.2, 0.18, 0.2), Color(0.4, 0.3, 0.2))
	var bed := interaction("hide", "under_table", "Esconder-se sob a bancada", Vector3(11.6, 0.5, -18), Vector3(1.8, 1.0, 0.9), Color(0.2, 0.2, 0.18))
	bed.visual_protection = 0.55

func _annex_geometry() -> void:
	# Connected additions leave all original objectives/rooms and chase widths intact.
	box(Vector3(0, -0.16, 12), Vector3(22, 0.3, 20), HorrorArt.surface("mud_leaves"))
	for side in [-1, 1]: box(Vector3(side * 11.1, 1.0, 12), Vector3(0.18, 2.0, 20), metal, true).visible = false
	box(Vector3(0, 1.0, 21.2), Vector3(22, 2, 0.18), metal, true).visible = false
	_label("INSTALAÇÃO 04 / ACESSO INTERDITADO", Vector3(0, 2.72, 2.25), 0, 23)
	_label("PORTÃO SEM ACESSO · USE A SAÍDA DE SERVIÇO", Vector3(0, 1.6, 19.7), 0, 18)
	var wet := HorrorArt.surface("damp_concrete")
	var ramp := box(Vector3(-13, -1.0, -32), Vector3(6.35, 0.2, 2.0), wet)
	ramp.rotation.z = atan(1.8 / 6.0)
	for side in [-1, 1]:
		var ramp_wall := box(Vector3(-13, 0.5, -32 + side * 1.1), Vector3(6.35, 3, 0.16), wet)
		ramp_wall.rotation.z = atan(1.8 / 6.0)
	box(Vector3(-19, -1.95, -32), Vector3(6, 0.3, 8), wet)
	box(Vector3(-19, 1.3, -32), Vector3(6, 0.2, 8), wet)
	for z in [-28, -36]: box(Vector3(-19, -0.3, z), Vector3(6.1, 3, 0.18), wet)
	box(Vector3(-22, -0.3, -32), Vector3(0.18, 3, 8), wet)
	for z in [-34.6, -29.4]: box(Vector3(-16, -0.3, z), Vector3(0.18, 3, 2.8), wet)
	_label("SUBSOLO / DRENAGEM", Vector3(-9.86, 2.4, -32), PI / 2, 22)

func _decor_box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	mesh.material_override = mat
	mesh.position = pos
	parent.add_child(mesh)
	return mesh

func _decorate_interaction(node: StaticBody3D) -> void:
	var mesh: MeshInstance3D = node.mesh
	var rust := HorrorArt.surface("rusted_iron")
	var dark := HorrorArt.solid(Color("191d1b"))
	mesh.material_override = rust
	match node.kind:
		"pickup":
			mesh.material_override = HorrorArt.surface("brushed_metal" if node.item_id == "chave_oficina" else "aged_plastic")
			if node.item_id in ["lanterna", "fusivel"]:
				var cylinder := CylinderMesh.new()
				cylinder.height = 0.32 if node.item_id == "lanterna" else 0.18
				cylinder.top_radius = 0.06 if node.item_id == "lanterna" else 0.035
				cylinder.bottom_radius = cylinder.top_radius * 0.85
				cylinder.radial_segments = 12
				mesh.mesh = cylinder
				mesh.rotation.z = PI / 2
				mesh.material_override = rust
				_decor_box(mesh, Vector3(0, 0.15, 0), Vector3(0.08, 0.014, 0.08), HorrorArt.solid(Color("b19a64"), 0.2))
		"hide":
			if node.item_id == "under_table":
				mesh.mesh = null
				_decor_box(mesh, Vector3(0, 0.5, 0), Vector3(1.8, 0.1, 0.9), rust)
				for x in [-0.8, 0.8]: _decor_box(mesh, Vector3(x, 0, 0), Vector3(0.07, 1.0, 0.8), rust)
				HorrorArt.merge_static(mesh, mesh)
				return
			# Opaque sides + real gaps in the louvers let the player watch the corridor.
			mesh.mesh = null
			for x in [-0.54, 0.54]: _decor_box(mesh, Vector3(x, 0, 0), Vector3(0.04, 2, 1), rust)
			for y in [-0.98, 0.98]: _decor_box(mesh, Vector3(0, y, 0), Vector3(1.1, 0.04, 1), rust)
			_decor_box(mesh, Vector3(0, 0, -0.48), Vector3(1.1, 2, 0.04), rust)
			_decor_box(mesh, Vector3(0, -0.4, 0.48), Vector3(1.1, 1.15, 0.04), rust)
			_decor_box(mesh, Vector3(0, 0.88, 0.48), Vector3(1.1, 0.2, 0.04), rust)
			for y in [0.22, 0.36, 0.50, 0.64, 0.78]:
				var louver := _decor_box(mesh, Vector3(0, y, 0.48), Vector3(1.05, 0.065, 0.045), rust)
				louver.rotation.x = -0.35
			_decor_box(mesh, Vector3(0.4, -0.1, 0.52), Vector3(0.035, 0.17, 0.045), dark)
		"door", "exit":
			mesh.material_override = HorrorArt.surface("industrial_sheet")
			var x_axis: bool = node.kind == "door"
			for sign_value in [-1, 1]:
				_decor_box(mesh, Vector3(sign_value * 0.09, 0, 0) if x_axis else Vector3(0, 0, sign_value * 0.12), Vector3(0.03, 2.2, 0.055) if x_axis else Vector3(0.06, 2.3, 0.03), dark)
			_decor_box(mesh, Vector3(0.12, 0, 0.55) if x_axis else Vector3(0.55, 0, 0.15), Vector3(0.08, 0.22, 0.045), dark)
		"generator":
			mesh.material_override = HorrorArt.surface("wet_steel")
			for y in [-0.65, -0.4, -0.15, 0.10]: _decor_box(mesh, Vector3(0, y, 0.42), Vector3(1.1, 0.035, 0.035), dark)
			_decor_box(mesh, Vector3(0.25, 0.55, 0.43), Vector3(0.4, 0.5, 0.04), dark)
		"document": mesh.material_override = HorrorArt.surface("torn_fabric")
		"drawer": mesh.material_override = HorrorArt.surface("damp_wood")
		"radio", "alarm": mesh.material_override = HorrorArt.surface("aged_plastic")
	if mesh.get_child_count() > 0: HorrorArt.merge_static(mesh, mesh)
