extends CharacterBody3D
signal tutorial_action(action: String, data: Dictionary)
var camera: Camera3D
var lamp: SpotLight3D
var shape: CollisionShape3D
var touch_move := Vector2.ZERO
var touch_run := false
var crouched := false
var hidden := false
var hide_spot: Node3D
var exit_position := Vector3.ZERO
var exit_look := Vector2.ZERO
var focus: Node3D
var pitch := 0.0
var step_clock := 0.0
var head_clock := 0.0
var lamp_on := false
var prompt := ""
var throw_selected := true
var lamp_fault := 0.0
var breathing_age := 0.0
var manipulator: Node

func _ready() -> void:
	Game.player = self
	collision_layer = 2
	collision_mask = 1 | 4 | 16
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
	manipulator = Node.new()
	manipulator.set_script(preload("res://scripts/physics/manipulator.gd"))
	add_child(manipulator)

func apply_settings() -> void:
	camera.fov = Game.settings.fov
	lamp.visible = lamp_on and Game.inventory.has("lanterna") and lamp_fault <= 0
	lamp.shadow_enabled = Graphics.shadow_tier>=1

func _unhandled_input(event: InputEvent) -> void:
	if not Game.playing or Game.paused or Game.capture_in_progress: return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED: look(event.relative)
	if event.is_action_pressed("interact"): interact()
	if event.is_action_pressed("flashlight"): toggle_lamp()
	if event.is_action_pressed("crouch"): toggle_crouch()
	if event.is_action_pressed("throw"): throw_object()
	if event.is_action_pressed("hold"): begin_hold()
	if event.is_action_released("hold"): manipulator.release()
	# Touch-generated mouse events must not request browser pointer lock.
	if event is InputEventMouseButton and event.pressed and event.device != -1 and not Game.testing: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func look(relative: Vector2) -> void:
	if not Game.playing or Game.paused or Game.capture_in_progress: return
	rotate_y(-relative.x * Game.settings.sensitivity)
	pitch = clampf(pitch - relative.y * Game.settings.sensitivity, -1.35, 1.35)
	camera.rotation.x = pitch

func toggle_crouch() -> void:
	if hidden or Game.capture_in_progress: return
	if crouched:
		var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.8, global_position + Vector3.UP * 1.75, 1)
		if not get_world_3d().direct_space_state.intersect_ray(query).is_empty(): return
	crouched = not crouched
	shape.shape.height = 1.0 if crouched else 1.7
	shape.position.y = 0.5 if crouched else 0.85

func toggle_lamp() -> void:
	if Game.capture_in_progress: return
	if not Game.inventory.has("lanterna"): return
	lamp_on = not lamp_on
	apply_settings()
	Sound.at("switch", global_position, -22)

func _physics_process(delta: float) -> void:
	if not Game.playing: return
	if Game.capture_in_progress:
		velocity = Vector3.ZERO
		return
	breathing_age += delta
	lamp_fault = maxf(0, lamp_fault - delta)
	lamp.visible = lamp_on and Game.inventory.has("lanterna") and lamp_fault <= 0
	if not hidden:
		var input := Input.get_vector("left", "right", "forward", "back") + touch_move
		input = input.limit_length()
		var running := (Input.is_action_pressed("run") or touch_run) and not crouched
		var speed := 1.25 if crouched else (4.0 if running else 2.45)
		var direction := global_basis * Vector3(input.x, 0, input.y)
		var before_move := global_position
		velocity.x = move_toward(velocity.x, direction.x * speed, 12 * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, 12 * delta)
		velocity += get_gravity() * delta
		# A low forward probe permits 18 cm steps; overhead and landing are checked.
		if is_on_floor() and input.length() > 0.1 and test_move(global_transform, direction * 0.12):
			var raised := global_transform
			raised.origin.y += 0.18
			if not test_move(global_transform, Vector3.UP * 0.18) and not test_move(raised, direction * 0.2): global_position.y += 0.18
		move_and_slide()
		if Game.in_tutorial:
			var travelled := Vector2(global_position.x-before_move.x,global_position.z-before_move.z).length()
			if travelled > 0.001: tutorial_action.emit("move", {"distance":travelled,"running":running,"crouched":crouched})
		CharacterPhysicsPush.apply(self)
		if Vector2(velocity.x, velocity.z).length() > 0.4 and is_on_floor():
			step_clock -= delta
			head_clock += delta * (11 if running else 7)
			if step_clock <= 0:
				step_clock = 0.32 if running else 0.55
				NoiseBus.emit_noise(self, 0.08 if crouched else (0.65 if running else 0.25), "passos", 3.0 if crouched else (18.0 if running else 8.0))
				Sound.at("step", global_position, -26 if crouched else (-13 if running else -21))
		var height := 0.9 if crouched else 1.56
		var motion: float = Game.settings.get("camera_motion", 0.5)
		camera.position.y = lerpf(camera.position.y, height + (sin(head_clock) * 0.014 + sin(breathing_age * 1.4) * 0.004) * motion, minf(1, delta * 12))
		camera.rotation.z = sin(breathing_age * 1.1) * 0.003 * motion
		camera.fov = lerpf(camera.fov, float(Game.settings.fov) + (2.0 * motion if running and input.length() > 0.1 else 0.0), minf(1, delta * 3))
	_detect_interaction()

func _detect_interaction() -> void:
	focus = null
	prompt = "E / Sair do esconderijo" if hidden else ""
	if hidden: return
	var start := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(start, start - camera.global_basis.z * 2.7, 1 | 8 | 16, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider.has_meta("interaction_owner"): hit.collider = hit.collider.get_meta("interaction_owner")
	if not hit.is_empty() and hit.collider.has_method("interact"):
		focus = hit.collider
		if start.distance_to(hit.position) <= focus.interaction_distance: prompt = "E / " + focus.get_prompt()
		else: focus = null

func interact() -> void:
	if Game.capture_in_progress: return
	if is_instance_valid(manipulator.held): manipulator.release(); return
	if hidden:
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = shape.shape
		query.collision_mask = 1 | 4 | 16
		query.exclude = [get_rid()]
		var candidates: Array[Vector3] = [exit_position]
		if is_instance_valid(hide_spot):
			for side in [-1, 1]: candidates.append(hide_spot.approach_position() + hide_spot.global_basis.x * side * 1.0 + Vector3.UP * 0.1)
		var free_exit := false
		for point in candidates:
			query.transform = Transform3D(Basis.IDENTITY, point + Vector3.UP * shape.position.y)
			if get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
				exit_position = point
				free_exit = true
				break
		if not free_exit: return
		if is_instance_valid(hide_spot): hide_spot.occupant = null
		hidden = false
		global_position = exit_position
		rotation.y = exit_look.x
		pitch = exit_look.y
		camera.rotation.x = pitch
		hide_spot = null
		if Game.in_tutorial: tutorial_action.emit("hide_exit", {})
	elif is_instance_valid(focus): focus.interact(self)

func enter_hide(spot: Node3D) -> void:
	if spot.has_occupant(): return
	manipulator.release()
	if is_instance_valid(Game.enemy): Game.enemy.witness_hide(spot)
	spot.occupant = self
	exit_position = global_position
	exit_look = Vector2(rotation.y, pitch)
	hide_spot = spot
	hidden = true
	velocity = Vector3.ZERO
	# Locker origins are at body centre; camera remains at human eye height,
	# behind the real louver gaps instead of above the cabinet.
	global_position = spot.global_position - Vector3.UP * spot.collider.shape.size.y * 0.5 + spot.global_basis.z * 0.10
	rotation.y = spot.rotation.y + PI
	pitch = 0.0
	camera.rotation.x = 0.0
	camera.position.y = 0.65 if spot.item_id == "under_table" else 1.5
	NoiseBus.emit_noise(self, 0.15, "armario", 6.0)
	if Game.in_tutorial: tutorial_action.emit("hide_enter", {})

func throw_object() -> Node3D:
	if is_instance_valid(manipulator.held):
		if Game.playing and not Game.paused and not Game.capture_in_progress: return manipulator.release(true)
		return null
	if not Game.playing or Game.paused or Game.capture_in_progress or hidden or not throw_selected or int(Game.world.get("throwables", 0)) <= 0: return null
	if get_tree().get_nodes_in_group("throwables").size() >= 8: return null
	var start := camera.global_position
	var direction := -camera.global_basis.z
	var query := PhysicsRayQueryParameters3D.create(start, start + direction * 0.65, 1, [get_rid()])
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty(): return null
	var object: RigidBody3D = preload("res://scenes/interactables/throwable.tscn").instantiate()
	get_parent().add_child(object)
	object.global_position = start + direction * 0.45
	object.add_collision_exception_with(self)
	object.linear_velocity = direction * object.throw_force + Vector3.UP * 1.8
	Game.world.throwables = int(Game.world.throwables) - 1
	if Game.record_results: Game.save_checkpoint()
	Game.updated.emit()
	return object

func begin_hold() -> void:
	if is_instance_valid(focus) and focus is PhysicalProp3D:
		if focus.profile.category == "C": manipulator.begin_drag(focus)
		else: manipulator.begin(focus)

func drop_throwable() -> Node3D:
	if not Game.playing or Game.paused or Game.capture_in_progress or hidden or int(Game.world.get("throwables",0)) <= 0: return null
	if get_tree().get_nodes_in_group("throwables").size() >= 8: return null
	var direction := -camera.global_basis.z
	var query := PhysicsRayQueryParameters3D.create(camera.global_position,camera.global_position+direction*.65,1,[get_rid()])
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty(): return null
	var object := preload("res://scenes/interactables/throwable.tscn").instantiate()
	get_parent().add_child(object)
	object.global_position = camera.global_position+direction*.45
	object.add_collision_exception_with(self)
	Game.world.throwables = int(Game.world.throwables)-1
	if Game.record_results: Game.save_checkpoint()
	Game.updated.emit()
	return object
