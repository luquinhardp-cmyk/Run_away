extends Node3D
## Original 3D title tableau; not an image standing in for gameplay geometry.
var camera: Camera3D
var lamp: OmniLight3D
var age := 0.0
var world_environment: WorldEnvironment
var sky: Environment
var ambience: AudioStreamPlayer

func _ready() -> void:
	name = "MenuStage"
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var root := Node3D.new()
	add_child(root)
	var mud := HorrorArt.surface("mud_leaves")
	var concrete := HorrorArt.surface("aged_concrete")
	var wood := HorrorArt.surface("rotten_wood")
	var rust := HorrorArt.surface("rusted_iron")
	_box(root, Vector3(0, -0.12, 0), Vector3(40, 0.2, 40), mud)
	_box(root, Vector3(3, 1.8, -5), Vector3(8, 3.6, 6), concrete)
	_box(root, Vector3(3, 3.7, -5), Vector3(8.5, 0.2, 6.5), rust, Vector3(0, 0, 0.06))
	_box(root, Vector3(3.5, 1.3, -1.97), Vector3(1.3, 2.6, 0.07), wood)
	_box(root, Vector3(1.2, 2.1, -1.94), Vector3(1.3, 0.7, 0.07), HorrorArt.solid(Color("0b0d0c")))
	for x in [0.7, 1.2, 1.7]: _box(root, Vector3(x, 2.1, -1.88), Vector3(0.05, 0.8, 0.04), rust)
	for x in range(-8, 12, 2):
		_box(root, Vector3(x, 0.65, 2.4), Vector3(0.12, 1.3, 0.12), wood, Vector3(0, 0, 0.08))
		for y in [0.4, 1.0]: _box(root, Vector3(x + 0.8, y, 2.4), Vector3(1.8, 0.12, 0.1), wood)
	var random := RandomNumberGenerator.new()
	random.seed = 48
	for i in 55:
		var pos := Vector3(random.randf_range(-8, 9), 0.4, random.randf_range(4, 11))
		if pos.x > 2 and pos.x < 5: continue
		_box(root, pos, Vector3(0.025, random.randf_range(0.5, 1.1), 0.03), wood, Vector3(0, random.randf() * TAU, 0.12))
		_box(root, pos + Vector3(0.1, 0, 0), Vector3(0.3, 0.045, 0.06), wood, Vector3(0, 0.3, 0.5))
	_box(root, Vector3(6, 2.4, 0), Vector3(0.12, 4.8, 0.12), wood, Vector3(0, 0, -0.04))
	_box(root, Vector3(5.6, 4.7, 0), Vector3(0.8, 0.08, 0.12), rust)
	HorrorArt.merge_static(root, self)
	world_environment = WorldEnvironment.new()
	sky = Environment.new()
	sky.background_mode = Environment.BG_COLOR
	sky.background_color = Color("191d1b")
	sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	sky.ambient_light_color = Color(0.42, 0.44, 0.40)
	sky.ambient_light_energy = 0.5
	sky.fog_enabled = true
	sky.fog_density = 0.035
	sky.fog_light_color = Color(0.16, 0.18, 0.15)
	world_environment.environment = sky
	add_child(world_environment)
	lamp = OmniLight3D.new()
	lamp.position = Vector3(5.3, 4.5, 0)
	lamp.light_color = Color("b19a64")
	lamp.light_energy = 2.2
	lamp.omni_range = 11
	add_child(lamp)
	camera = Camera3D.new()
	camera.position = Vector3(9.5, 1.7, 10)
	camera.fov = 65
	add_child(camera)
	camera.look_at(Vector3(2.5, 1.6, -3))
	camera.current = true
	ambience = AudioStreamPlayer.new()
	ambience.stream = load("res://assets/audio/exterior_wind.wav")
	ambience.bus = "Effects"
	ambience.volume_db = -32
	add_child(ambience)
	ambience.finished.connect(ambience.play)
	_start_ambience()

func set_active(value: bool) -> void:
	visible = value
	camera.current = value
	world_environment.environment = sky if value else null
	if value: _start_ambience()
	else: ambience.stop()

func _start_ambience() -> void:
	if visible and is_instance_valid(ambience) and not ambience.playing: ambience.play()

func _exit_tree() -> void:
	if is_instance_valid(ambience):
		ambience.stop()
		ambience.stream = null

func _box(root: Node3D, pos: Vector3, size: Vector3, mat: Material, angle: Vector3 = Vector3.ZERO) -> void:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	node.rotation = angle
	root.add_child(node)

func _process(delta: float) -> void:
	if not visible: return
	age += delta
	camera.position.y = 1.7 + sin(age * 0.25) * 0.012
	lamp.light_energy = 2.2 * (0.72 if fmod(age, 19) > 18.6 else 1.0)
