extends Node3D
signal feedback(text: String)
var geometry: Node3D
var items: Dictionary = {}
var lamps: Array[OmniLight3D] = []
var exit_latch: Node3D
var exit_lens: MeshInstance3D
var move_target := Vector3(-4.83, 1.6, -1)
var light_target := Vector3(3, 1.5, -12.6)
func box(at: Vector3, size: Vector3, surface: String, solid := true, parent: Node3D = null) -> Node3D:
	if parent == null: parent = geometry
	var body: Node3D = StaticBody3D.new() if solid else Node3D.new()
	body.position = at
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = HorrorArt.surface(surface)
	body.add_child(mesh)
	if solid:
		var collider := CollisionShape3D.new()
		var hull := BoxShape3D.new()
		hull.size = size
		collider.shape = hull
		body.add_child(collider)
		PhysicsSurfaces.attach(body, "metal" if surface == "weathered_iron" else "concrete")
	parent.add_child(body)
	return body
func sign_text(text: String, at: Vector3, angle := 0.0, font_size := 32) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.rotation.y = angle
	label.font_size = font_size
	label.pixel_size = 0.008
	label.modulate = Color("c2b797")
	label.outline_size = 4
	add_child(label)
	return label
func mark(at: Vector3, number: String) -> void:
	var disk := MeshInstance3D.new()
	var circle := CylinderMesh.new()
	circle.top_radius = 0.65
	circle.bottom_radius = 0.65
	circle.height = 0.006
	circle.radial_segments = 24
	disk.mesh = circle
	disk.material_override = HorrorArt.solid(Color("756b3f"),0.9)
	disk.position = at + Vector3.UP * 0.012
	geometry.add_child(disk)
	sign_text(number,at+Vector3.UP*.022,0,35).rotation.x = -PI/2
func item(kind: String, id: String, title: String, at: Vector3, size: Vector3, action := "", angle := 0.0) -> StaticBody3D:
	var node := StaticBody3D.new()
	node.set_script(preload("res://scripts/tutorial/interaction.gd"))
	node.kind = kind
	node.item_id = id
	node.title = title
	node.tutorial_action = action
	node.manager = self
	node.position = at
	node.rotation.y = angle
	if id == "tutorial_cabinet": node.required_key = "tutorial_key"
	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	mesh.material_override = HorrorArt.surface("weathered_iron")
	node.add_child(mesh)
	var collider := CollisionShape3D.new()
	collider.name = "Collision"
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	node.add_child(collider)
	add_child(node)
	if not node.is_queued_for_deletion():
		if id == "tutorial_key":
			mesh.mesh = null
			ModelLibrary.fit("key",Vector3(.22,.025,.12),mesh)
		elif id == "tutorial_mark":
			mesh.mesh = null
			ModelLibrary.fit("security_card",Vector3(.22,.012,.13),mesh)
		else: ModelLibrary.replace_interaction(node)
		node.notified.connect(func(text: String): feedback.emit(text))
	items[id] = node
	return node
func build_room() -> void:
	geometry = Node3D.new()
	geometry.name = "StaticRoom"
	add_child(geometry)
	box(Vector3(0,-.15,-15),Vector3(10,.3,42),"cracked_floor")
	box(Vector3(0,3.35,-15),Vector3(10,.2,42),"aged_concrete")
	for x in [-5,5]: box(Vector3(x,1.6,-15),Vector3(.2,3.2,42),"aged_concrete")
	box(Vector3(0,1.6,6),Vector3(10,3.2,.2),"aged_concrete")
	box(Vector3(0,1.6,-36),Vector3(10,3.2,.2),"aged_concrete")
	for x in [-3,3]: box(Vector3(x,1.6,-32),Vector3(4.2,3.2,.2),"aged_concrete")
	box(Vector3(0,3,-32),Vector3(1.8,.6,.2),"aged_concrete")
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("080b0c")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("66776a")
	env.environment.ambient_light_energy = .22
	env.environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	add_child(env)
	for z in [1,-5,-18,-23,-29,-34]:
		var light := OmniLight3D.new()
		light.position = Vector3(0,2.8,z)
		light.light_color = Color("baa77d")
		light.light_energy = .8
		light.omni_range = 6
		light.shadow_enabled = false
		add_child(light)
		lamps.append(light)
		box(Vector3(0,3.1,z),Vector3(.8,.12,.3),"weathered_iron",false)
	# Aged pipes, fixed benches and crates reuse existing textured models.
	for x in [-4.7,4.7]:
		box(Vector3(x,2.8,-15),Vector3(.12,.12,40),"weathered_iron",false)
		for z in [-3,-11,-20,-29]: box(Vector3(x,2.8,z),Vector3(.23,.23,.12),"weathered_iron",false)
	for at in [Vector3(-3,.4,-3),Vector3(-3.5,.4,-7.7),Vector3(3,.4,-12),Vector3(3,.4,-24),Vector3(-3,.4,-29)]:
		ModelLibrary.fit("workbench",Vector3(1.5,.8,.65),geometry,at,Game.settings.quality<1)
		box(at,Vector3(1.5,.8,.65),"damp_wood",true).get_child(0).hide()
	for at in [Vector3(4.3,.4,4),Vector3(-4.3,.4,-18)]:
		ModelLibrary.fit("crate",Vector3(.7,.8,.7),geometry,at,Game.settings.quality<1)
		box(at,Vector3(.7,.8,.7),"damp_wood",true).get_child(0).hide()
	mark(Vector3(0,0,0),"01")
	sign_text("01 / ACESSO\nOLHE ANTES DE SEGUIR",move_target,PI/2)
	item("pickup","tutorial_key","Chave de treino",Vector3(-3,.9,-3),Vector3(.26,.15,.16))
	item("door","tutorial_cabinet","Abrir armário de equipamentos",Vector3(-3.5,1.3,-6.5),Vector3(.15,2.6,1.8),"",PI/2)
	for x in [-4.5,-2.5]: box(Vector3(x,1.3,-7.5),Vector3(.15,2.6,2),"aged_concrete")
	box(Vector3(-3.5,1.3,-8.5),Vector3(2,2.6,.15),"aged_concrete")
	item("pickup","lanterna","Lanterna de treino",Vector3(-3.5,.91,-7.7),Vector3(.35,.16,.16))
	sign_text("02 / CHAVE → ARMÁRIO\nE / INTERAGIR",Vector3(-3,1.8,-3.3))
	box(Vector3(1,1.6,-11),Vector3(.15,3.2,4),"aged_concrete")
	box(Vector3(3,1.6,-12.8),Vector3(2,3.2,.15),"aged_concrete")
	sign_text("03 / +",light_target,0,50)
	item("pickup","tutorial_mark","Selo de inspeção",Vector3(3,.9,-12),Vector3(.22,.12,.15))
	for x in [-3.05,3.05]: box(Vector3(x,1.6,-15),Vector3(3.9,3.2,.6),"aged_concrete")
	box(Vector3(0,2.175,-15),Vector3(2.2,2.05,.6),"weathered_iron")
	sign_text("04 / AGACHE\nPASSAGEM BAIXA",Vector3(0,2.7,-14.65))
	mark(Vector3(0,0,-20),"05")
	item("hide","tutorial_hide","Entrar no esconderijo",Vector3(-3.8,1,-22),Vector3(1.1,2,1),"",PI/2)
	sign_text("06 / ESCONDERIJO",Vector3(-4.82,2.5,-22),PI/2)
	item("document","simulation","SIMULAÇÃO de som (sem microfone)",Vector3(2.4,1.3,-23.8),Vector3(.5,.6,.12),"simulate")
	item("document","mic_enable","Ativar microfone opcional",Vector3(3.2,1.3,-23.8),Vector3(.5,.6,.12),"microphone")
	item("document","recover","Recuperar lata de treino",Vector3(4,1.3,-23.8),Vector3(.5,.6,.12),"recover")
	sign_text("07 / SIMULAÇÃO   MIC   RECUPERAR\nSom moderado → silêncio → arremesso",Vector3(3.2,2,-24))
	mark(Vector3(3,0,-26),"ALVO")
	box(Vector3(4.7,1,-26),Vector3(.2,2,3.5),"weathered_iron")
	spawn_can_pickup()
	item("pickup","fusivel","Fusível de treino",Vector3(-3,.9,-29),Vector3(.25,.13,.13))
	item("fuse_panel","tutorial_fuse_panel","Instalar fusível de treino",Vector3(-4.8,1.4,-30),Vector3(.7,.9,.2),"",PI/2)
	item("generator","tutorial_generator","GERADOR DE EMERGÊNCIA",Vector3(3.5,1,-29.5),Vector3(1.3,2,.8),"generator").prepare_switch()
	var generator_sign := sign_text("GERADOR DE EMERGÊNCIA\nFUSÍVEL → PAINEL → LIGAR",Vector3(3.4,2.6,-29.8),0,24)
	generator_sign.pixel_size = .003
	var maintenance_light := OmniLight3D.new()
	maintenance_light.position = Vector3(3.3,2.6,-28.8)
	maintenance_light.light_color = Color("b5a17a")
	maintenance_light.light_energy = .65
	maintenance_light.omni_range = 3
	maintenance_light.shadow_enabled = false
	add_child(maintenance_light)
	# Visible conduit connects the panel, generator and powered airlock.
	box(Vector3(0,.07,-30.8),Vector3(9,.10,.10),"weathered_iron",false)
	box(Vector3(3.5,.07,-30.2),Vector3(.10,.10,1.2),"weathered_iron",false)
	box(Vector3(1,.07,-31.4),Vector3(.10,.10,1.2),"weathered_iron",false)
	var board := item("document","mission","Ler SUA MISSÃO",Vector3(0,1.5,-30.5),Vector3(2,1.1,.12),"mission")
	board.message = "SUA MISSÃO\n"
	for definition in Game.objectives.definitions: board.message += definition.caption + "\n"
	var mission_sign := sign_text("08 / SUA MISSÃO\nExplore · restaure energia · escape\nE / LER",Vector3(0,1.7,-30.41))
	mission_sign.pixel_size = .0025
	item("door","tutorial_exit","Entrar no complexo — sem retorno",Vector3(0,1.3,-32),Vector3(.15,2.6,1.8),"exit",PI/2)
	exit_latch = box(Vector3(.92,1.4,-31.8),Vector3(.18,.30,.14),"weathered_iron",false,self)
	exit_lens = box(Vector3(1.1,1.8,-31.8),Vector3(.12,.12,.04),"weathered_iron",false,self).get_child(0)
	sign_text("COMPLEXO / ENTRADA DEFINITIVA",Vector3(0,2.8,-31.8)).pixel_size = .003
	var trigger := Area3D.new()
	trigger.name = "OneWayAirlock"
	trigger.collision_layer = 0
	trigger.collision_mask = 2
	var collision := CollisionShape3D.new()
	var hull := BoxShape3D.new()
	hull.size = Vector3(1.7,2.5,.7)
	collision.shape = hull
	trigger.add_child(collision)
	trigger.position = Vector3(0,1.2,-33.3)
	add_child(trigger)
	trigger.body_entered.connect(Callable(self,"_airlock_entered"))
	var batches := Node3D.new()
	batches.name = "StaticBatches"
	add_child(batches)
	HorrorArt.merge_static(geometry,batches)
func spawn_can_pickup() -> void:
	if is_instance_valid(items.get("tutorial_can")) and not items.tutorial_can.is_queued_for_deletion(): return
	var node := item("throw_pickup","tutorial_can","Coletar lata de treino",Vector3(3,.95,-24),Vector3(.2,.3,.2))
	if not node.is_queued_for_deletion():
		for child in node.mesh.get_children(): child.free()
		ModelLibrary.fit("can",Vector3(.18,.26,.18),node.mesh)
