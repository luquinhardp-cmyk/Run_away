extends CharacterBody3D
var camera: Camera3D
var lamp: SpotLight3D
var shape: CollisionShape3D
var touch_move := Vector2.ZERO
var touch_run := false
var crouched := false
var hidden := false
var hide_spot: Node3D
var exit_position := Vector3.ZERO
var focus: Node3D
var pitch := 0.0
var step_clock := 0.0
var head_clock := 0.0
var lamp_on := false
var prompt := ""

func _ready() -> void:
	Game.player = self
	collision_layer = 2
	collision_mask = 1 | 4
	floor_snap_length = 0.3
	shape = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.7
	shape.shape = capsule
	shape.position.y = 0.85
	add_child(shape)
	camera = Camera3D.new()
	camera.position.y = 1.56
	camera.current = true
	camera.near = 0.06
	add_child(camera)
	lamp = SpotLight3D.new()
	lamp.spot_range = 17.0
	lamp.spot_angle = 38
	lamp.light_color = Color(0.84, 0.91, 0.83)
	lamp.light_energy = 4.5
	lamp.position = Vector3(0.18, -0.12, -0.12)
	lamp.shadow_enabled = false
	camera.add_child(lamp)
	Game.updated.connect(apply_settings)
	apply_settings()

func apply_settings() -> void:
	camera.fov = Game.settings.fov
	lamp.visible = lamp_on and Game.inventory.has("lanterna")
	lamp.shadow_enabled = Game.settings.quality >= 2

func _unhandled_input(event: InputEvent) -> void:
	if not Game.playing or Game.paused: return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED: look(event.relative)
	if event.is_action_pressed("interact"): interact()
	if event.is_action_pressed("flashlight"): toggle_lamp()
	if event.is_action_pressed("crouch"): toggle_crouch()
	if event is InputEventMouseButton and event.pressed: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func look(relative: Vector2) -> void:
	if not Game.playing or Game.paused: return
	rotate_y(-relative.x * Game.settings.sensitivity)
	pitch = clampf(pitch - relative.y * Game.settings.sensitivity, -1.35, 1.35)
	camera.rotation.x = pitch

func toggle_crouch() -> void:
	if hidden: return
	if crouched:
		var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.8, global_position + Vector3.UP * 1.75, 1)
		if not get_world_3d().direct_space_state.intersect_ray(query).is_empty(): return
	crouched = not crouched
	shape.shape.height = 1.0 if crouched else 1.7
	shape.position.y = 0.5 if crouched else 0.85

func toggle_lamp() -> void:
	if not Game.inventory.has("lanterna"): return
	lamp_on = not lamp_on
	apply_settings()
	Sound.at("switch", global_position, -22)

func _physics_process(delta: float) -> void:
	if not Game.playing: return
	if not hidden:
		var input := Input.get_vector("left", "right", "forward", "back") + touch_move
		input = input.limit_length()
		var running := (Input.is_action_pressed("run") or touch_run) and not crouched
		var speed := 1.25 if crouched else (4.0 if running else 2.45)
		var direction := global_basis * Vector3(input.x, 0, input.y)
		velocity.x = move_toward(velocity.x, direction.x * speed, 12 * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, 12 * delta)
		velocity.y -= 18 * delta
		# A low forward probe permits 18 cm steps; overhead and landing are checked.
		if is_on_floor() and input.length() > 0.1 and test_move(global_transform, direction * 0.12):
			var raised := global_transform
			raised.origin.y += 0.18
			if not test_move(global_transform, Vector3.UP * 0.18) and not test_move(raised, direction * 0.2): global_position.y += 0.18
		move_and_slide()
		if Vector2(velocity.x, velocity.z).length() > 0.4 and is_on_floor():
			step_clock -= delta
			head_clock += delta * (11 if running else 7)
			if step_clock <= 0:
				step_clock = 0.32 if running else 0.55
				NoiseBus.emit_noise(self, 0.08 if crouched else (0.65 if running else 0.25), "passos", 3.0 if crouched else (18.0 if running else 8.0))
				Sound.at("step", global_position, -26 if crouched else (-13 if running else -21))
		var height := 0.9 if crouched else 1.56
		camera.position.y = lerpf(camera.position.y, height + sin(head_clock) * 0.014, minf(1, delta * 12))
	_detect_interaction()

func _detect_interaction() -> void:
	focus = null
	prompt = "E / Sair do esconderijo" if hidden else ""
	if hidden: return
	var start := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(start, start - camera.global_basis.z * 2.7, 1 | 8, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider.has_method("interact"):
		focus = hit.collider
		prompt = "E / " + focus.get_prompt()

func interact() -> void:
	if hidden:
		hidden = false
		global_position = exit_position
		hide_spot = null
	elif is_instance_valid(focus): focus.interact(self)

func enter_hide(spot: Node3D) -> void:
	exit_position = global_position
	hide_spot = spot
	hidden = true
	velocity = Vector3.ZERO
	global_position = spot.global_position + spot.global_basis.z * 0.15
	NoiseBus.emit_noise(self, 0.15, "armario", 6.0)
