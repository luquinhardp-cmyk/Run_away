extends CharacterBody3D
enum State { PATROL, IDLE, ALERT, INVESTIGATE, SEARCH, CHASE, ATTACK, LOST, RETURN }
var state := State.PATROL
var agent: NavigationAgent3D
var target := Vector3.ZERO
var last_known := Vector3.ZERO
var patrol: Array[Vector3] = [Vector3(0, 0.1, -16), Vector3(0, 0.1, -32), Vector3(-4, 0.1, -24), Vector3(0, 0.1, -8)]
var patrol_index := 0
var timer := 0.0
var perceive_clock := 0.0
var unseen := 0.0
var age := 0.0
var suspicion := 0.0
var sound_clock := 0.0
var body: Node3D
var arms: Array[MeshInstance3D] = []
var stuck_time := 0.0
var previous := Vector3.ZERO
var ready_navigation := false
var heard_hide := false

func _ready() -> void:
	Game.enemy = self
	collision_layer = 4
	collision_mask = 1 | 2
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.height = 2.4
	capsule.radius = 0.32
	collision.shape = capsule
	collision.position.y = 1.2
	add_child(collision)
	agent = NavigationAgent3D.new()
	agent.path_desired_distance = 0.35
	agent.target_desired_distance = 0.45
	agent.radius = 0.35
	add_child(agent)
	_build_placeholder()
	NoiseBus.emitted.connect(_hear)
	previous = global_position

func _build_placeholder() -> void:
	# Original procedural 3D placeholder, animated in code; replaceable by a rig.
	body = Node3D.new()
	add_child(body)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.13, 0.16, 0.15)
	material.roughness = 0.95
	for part in [[Vector3(0, 1.4, 0), Vector3(0.52, 1.2, 0.35)], [Vector3(0, 2.18, -0.08), Vector3(0.33, 0.5, 0.32)], [Vector3(-0.2, 0.5, 0), Vector3(0.16, 1.0, 0.18)], [Vector3(0.2, 0.5, 0), Vector3(0.16, 1.0, 0.18)], [Vector3(-0.43, 1.15, 0), Vector3(0.12, 1.4, 0.12)], [Vector3(0.43, 1.15, 0), Vector3(0.12, 1.4, 0.12)]]:
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = part[1]
		mesh.mesh = box
		mesh.material_override = material
		mesh.position = part[0]
		body.add_child(mesh)
		arms.append(mesh)
	var eye_material := StandardMaterial3D.new()
	eye_material.albedo_color = Color(0.7, 0.55, 0.3)
	eye_material.emission_enabled = true
	eye_material.emission = Color(0.7, 0.3, 0.05)
	for x in [-0.09, 0.09]:
		var eye := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.035
		sphere.height = 0.07
		eye.mesh = sphere
		eye.material_override = eye_material
		eye.position = Vector3(x, 2.25, -0.25)
		body.add_child(eye)

func transition(next: State) -> void:
	state = next
	timer = 0.0
	if next == State.CHASE:
		unseen = 0.0
		Sound.at("chase", global_position, -10 * Game.settings.scares)

func _hear(event: Dictionary) -> void:
	if age < 8 or not Game.playing or state == State.ATTACK: return
	var strength := NoiseBus.perceived(event, self)
	suspicion = minf(1.0, suspicion + strength * 0.35)
	if strength < 0.06: return
	last_known = event.position
	heard_hide = is_instance_valid(Game.player) and Game.player.hidden and strength > 0.32
	if state == State.CHASE: return
	if strength > 0.5 and global_position.distance_to(last_known) < 12 and not Game.player.hidden:
		transition(State.INVESTIGATE)
	elif strength + suspicion > 0.18: transition(State.ALERT)

func sees_player() -> bool:
	if not is_instance_valid(Game.player) or Game.player.hidden: return false
	var player := Game.player
	var offset: Vector3 = player.global_position - global_position
	var range_limit := 15.0 if player.lamp_on else (5.5 if player.crouched else 9.0)
	if offset.length() > range_limit: return false
	if offset.length() > 1.8 and -global_basis.z.dot(offset.normalized()) < cos(deg_to_rad(55)): return false
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 2.1, player.camera.global_position, 1 | 2, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.collider == player

func _physics_process(delta: float) -> void:
	if not Game.playing: return
	age += delta
	timer += delta
	perceive_clock -= delta
	sound_clock -= delta
	suspicion = maxf(0, suspicion - delta * 0.035)
	if not ready_navigation:
		ready_navigation = NavigationServer3D.map_get_iteration_id(agent.get_navigation_map()) > 0
		return
	if age < 8: return
	if perceive_clock <= 0:
		perceive_clock = 0.18
		if sees_player():
			last_known = Game.player.global_position
			unseen = 0
			if state != State.CHASE and state != State.ATTACK: transition(State.CHASE)
		else: unseen += 0.18
	if sound_clock <= 0:
		Sound.at("breath", global_position, -12)
		sound_clock = 3.8 if state != State.CHASE else 1.4
	var speed := 1.55
	match state:
		State.PATROL:
			target = patrol[patrol_index]
			if global_position.distance_to(target) < 0.8:
				patrol_index = (patrol_index + 1) % patrol.size()
				transition(State.IDLE)
		State.IDLE:
			speed = 0
			if timer > 2.5: transition(State.PATROL)
		State.ALERT:
			speed = 0
			_face(last_known, delta)
			if timer > 0.7: transition(State.INVESTIGATE)
		State.INVESTIGATE:
			target = last_known
			if global_position.distance_to(target) < 1.1 or timer > 14: transition(State.SEARCH)
		State.SEARCH:
			if heard_hide and Game.player.hidden and global_position.distance_to(Game.player.global_position) < 2.2:
				transition(State.ATTACK)
			if timer < 0.1:
				var nearest := NavigationServer3D.map_get_closest_point(agent.get_navigation_map(), last_known + Vector3(sin(age) * 2.5, 0, cos(age) * 2.5))
				target = nearest
			if timer > 6.5: transition(State.RETURN)
		State.CHASE:
			speed = 3.35
			target = last_known
			if unseen > 2.4: transition(State.LOST)
			if global_position.distance_to(Game.player.global_position) < 1.25 and sees_player(): transition(State.ATTACK)
		State.ATTACK:
			speed = 0
			body.rotation.x = -0.35 * sin(minf(timer * 4, PI))
			if timer < 0.05: Sound.at("capture", global_position, -8 - (1 - Game.settings.scares) * 18)
			if timer > 0.65: Game.finish(false)
		State.LOST:
			target = last_known
			if timer > 2 or global_position.distance_to(target) < 0.8: transition(State.SEARCH)
		State.RETURN:
			target = patrol[patrol_index]
			if timer > 12 or global_position.distance_to(target) < 1: transition(State.PATROL)
	if agent.target_position.distance_to(target) > 0.3: agent.target_position = target
	var next := agent.get_next_path_position()
	var direction := next - global_position
	direction.y = 0
	if agent.is_navigation_finished(): direction = Vector3.ZERO
	velocity = direction.normalized() * speed
	velocity.y = -2.0
	move_and_slide()
	if direction.length() > 0.1 and speed > 0:
		_face(global_position + direction, delta)
		body.position.y = sin(age * (14 if state == State.CHASE else 6)) * 0.045
		for i in range(2, arms.size()): arms[i].rotation.x = sin(age * 6 + i * PI) * (0.5 if state == State.CHASE else 0.18)
	if global_position.distance_to(previous) < 0.006 and speed > 0 and direction.length() > 0.1: stuck_time += delta
	else: stuck_time = 0
	if stuck_time > 1.2:
		# Doors block vision and sound, but the creature can physically open them.
		for door in get_tree().get_nodes_in_group("doors"):
			if door.global_position.distance_to(global_position) < 2.3: door._set_open(true)
		agent.target_position = target
		if stuck_time > 5:
			patrol_index = (patrol_index + 1) % patrol.size()
			transition(State.RETURN)
			stuck_time = 0
	previous = global_position

func _face(point: Vector3, delta: float) -> void:
	var direction := point - global_position
	if Vector2(direction.x, direction.z).length() > 0.05:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(1, delta * 5))
