extends CharacterBody3D
signal state_changed(previous: int, current: int)
var profile: CreatureProfile
var memory := CreatureMemory.new()
var perception := CreaturePerception.new()
var search := CreatureSearch.new()
var visual_evidence := 0.0
var visible_now := false
var checking_hide: Node3D
var checked_hides: Array[String] = []
var hide_timer := 0.0
var captured_hide: Node3D
var ai_usec := 0
var navigation_recoveries := 0
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
var visual: Node3D
var listen_duration := 1.6
var hearing_cooldown := 0.0
var foot_clock := 0.0
var stuck_time := 0.0
var previous := Vector3.ZERO
var ready_navigation := false
var heard_hide := false

func _ready() -> void:
	Game.enemy = self
	profile = Game.difficulty_profile()
	listen_duration = profile.listen_duration
	if int(Game.world.get("variant", 0)) == 1: patrol.reverse()
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
	_build_visual()
	NoiseBus.emitted.connect(_hear)
	previous = global_position

func _build_visual() -> void:
	visual = Node3D.new()
	visual.set_script(preload("res://scripts/enemy/escutador_visual.gd"))
	add_child(visual)
	body = visual

func transition(next: State) -> void:
	if state == next: return
	var prior := state
	state = next
	timer = 0.0
	if is_instance_valid(visual): visual.set_motion(int(next))
	if next == State.ALERT:
		hearing_cooldown = 2.8
		Sound.at("listen", global_position + Vector3.UP * 2.1, -21)
	if next == State.INVESTIGATE: Sound.at("investigate", global_position, -25)
	if next == State.SEARCH:
		search.build(self, last_known, memory)
		checked_hides.clear()
		checking_hide = null
		target = last_known
	if next == State.ATTACK: Sound.at("attack", global_position, -16 - (1 - Game.settings.scares) * 12)
	if next == State.CHASE:
		unseen = 0.0
		Sound.at("chase", global_position, -10 * Game.settings.scares)
	state_changed.emit(int(prior), int(next))

func _hear(event: Dictionary) -> void:
	if age < 8 or not Game.playing or state == State.ATTACK: return
	var strength := NoiseBus.perceived(event, self) * profile.hearing_sensitivity
	suspicion = minf(1.0, suspicion + strength * 0.35)
	if strength < 0.06: return
	var previous_source := memory.sound_source
	if not memory.heard(event, strength, age): return
	if event.kind in ["microfone", "armario"]:
		for spot in get_tree().get_nodes_in_group("hide_spots"):
			if spot.global_position.distance_to(event.position) < 2.0:
				memory.hide_clues[spot.item_id] = minf(1.5, float(memory.hide_clues.get(spot.item_id, 0)) + strength)
	if state == State.CHASE: return
	last_known = memory.sound_position
	if state in [State.INVESTIGATE, State.SEARCH] and previous_source == memory.sound_source: return
	# Every audible reaction first gives the player a readable listening pose.
	# Repeated voice/footstep events update memory without restarting the pose.
	if state == State.ALERT or hearing_cooldown > 0: return
	if strength + suspicion > 0.14: transition(State.ALERT)

func sees_player() -> bool:
	return perception.visual_strength(self, Game.player, profile) > 0

func witness_hide(spot: Node3D) -> void:
	if sees_player():
		memory.hide_clues[spot.item_id] = 1.2
		last_known = spot.approach_position()

func _search_hides(delta: float) -> bool:
	if not is_instance_valid(checking_hide):
		for spot in get_tree().get_nodes_in_group("hide_spots"):
			if spot.item_id in checked_hides or spot.global_position.distance_to(last_known) > 10: continue
			if float(memory.hide_clues.get(spot.item_id, 0)) < 0.18: continue
			var path := NavigationServer3D.map_get_path(agent.get_navigation_map(), global_position, spot.approach_position(), true)
			if path.is_empty() or path[-1].distance_to(spot.approach_position()) > 1: continue
			checking_hide = spot
			hide_timer = 0
			target = spot.approach_position()
			break
	if not is_instance_valid(checking_hide): return false
	if global_position.distance_to(checking_hide.approach_position()) > 1.1: return false
	if hide_timer == 0:
		checking_hide.notified.emit("O Escutador examina o esconderijo. Saia e busque outra rota!")
		Sound.at("listen", checking_hide.global_position, -17)
		visual.set_motion(State.ALERT)
	hide_timer += delta
	if hide_timer >= profile.hide_warning:
		checked_hides.append(checking_hide.item_id)
		var found: bool = checking_hide.has_occupant()
		memory.mark_searched(checking_hide.global_position, found)
		memory.hide_clues[checking_hide.item_id] = 0.1
		if found:
			captured_hide = checking_hide
			transition(State.ATTACK)
		checking_hide = null
		if state == State.SEARCH: visual.set_motion(State.SEARCH)
	return true

func _physics_process(delta: float) -> void:
	if not Game.playing: return
	var started := Time.get_ticks_usec()
	age += delta
	hearing_cooldown = maxf(0, hearing_cooldown - delta)
	foot_clock -= delta
	timer += delta
	perceive_clock -= delta
	sound_clock -= delta
	suspicion = maxf(0, suspicion - delta * 0.035)
	memory.decay(delta)
	if not ready_navigation:
		ready_navigation = NavigationServer3D.map_get_iteration_id(agent.get_navigation_map()) > 0
		return
	if age < 8: return
	if perceive_clock <= 0:
		perceive_clock = 0.18
		var strength := perception.visual_strength(self, Game.player, profile)
		visible_now = strength > 0
		if visible_now:
			last_known = Game.player.global_position
			memory.saw(last_known, age)
			unseen = 0
			visual_evidence = minf(1.5, visual_evidence + strength * 0.18 / profile.reaction_time)
			if visual_evidence > 0.75 and state not in [State.CHASE, State.ATTACK]: transition(State.CHASE)
		else:
			unseen += 0.18
			visual_evidence = maxf(0, visual_evidence - 0.22)
	if sound_clock <= 0:
		Sound.at("breath", global_position, -12)
		sound_clock = 3.8 if state != State.CHASE else 1.4
	var speed := profile.patrol_speed
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
			if timer > listen_duration: transition(State.INVESTIGATE)
		State.INVESTIGATE:
			speed = profile.investigate_speed
			target = last_known
			if global_position.distance_to(target) < 1.1 or timer > 14: transition(State.SEARCH)
		State.SEARCH:
			speed = profile.investigate_speed * 0.75
			if _search_hides(delta): speed = 0
			elif global_position.distance_to(target) < 0.9 or agent.is_navigation_finished():
				memory.mark_searched(target, false)
				if search.has_next(): target = search.next_point()
				else: transition(State.RETURN)
			if timer > profile.search_duration: transition(State.RETURN)
		State.CHASE:
			speed = profile.chase_speed
			target = memory.visual_position
			if visible_now and memory.direction.length() > 0.2:
				var projected := NavigationServer3D.map_get_closest_point(agent.get_navigation_map(), target + memory.direction * 0.6)
				if projected.distance_to(target) < 0.8: target = projected
			if unseen > profile.lost_after:
				last_known = memory.visual_position
				transition(State.LOST)
			if global_position.distance_to(Game.player.global_position) < profile.attack_distance and sees_player():
				captured_hide = null
				transition(State.ATTACK)
		State.ATTACK:
			speed = 0
			var valid_hide: bool = is_instance_valid(captured_hide) and captured_hide.has_occupant() and global_position.distance_to(captured_hide.approach_position()) < 1.6
			if not valid_hide and (not sees_player() or global_position.distance_to(Game.player.global_position) > profile.attack_distance + 0.5):
				transition(State.LOST)
				return
			_capture_focus(delta)
			if timer > 0.3 and visual.active_clip != "capture":
				visual.play_capture()
				Sound.at("capture", global_position, -15 - (1 - Game.settings.scares) * 18)
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
		if foot_clock <= 0:
			Sound.at("creature_step", global_position, -17 if state == State.CHASE else -23)
			foot_clock = 0.36 if state == State.CHASE else 0.67
	visual.advance_motion(Vector2(velocity.x, velocity.z).length())
	if global_position.distance_to(previous) < 0.006 and speed > 0 and direction.length() > 0.1: stuck_time += delta
	else: stuck_time = 0
	if stuck_time > 1.2:
		# Doors block vision and sound, but the creature can physically open them.
		for door in get_tree().get_nodes_in_group("doors"):
				if door.global_position.distance_to(global_position) < 2.3: door.try_open_for_creature()
		agent.target_position = target
		if stuck_time > 5:
			navigation_recoveries += 1
			patrol_index = (patrol_index + 1) % patrol.size()
			transition(State.RETURN)
			stuck_time = 0
	previous = global_position
	ai_usec = Time.get_ticks_usec() - started

func _face(point: Vector3, delta: float) -> void:
	var direction := point - global_position
	if Vector2(direction.x, direction.z).length() > 0.05:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(1, delta * 5))

func _capture_focus(delta: float) -> void:
	if not is_instance_valid(Game.player) or Game.settings.scares <= 0: return
	var camera: Camera3D = Game.player.camera
	var direction: Vector3 = visual.head_position() - camera.global_position
	if direction.length() < 0.05: return
	var desired := Basis.looking_at(direction.normalized(), Vector3.UP).get_rotation_quaternion()
	camera.global_basis = Basis(camera.global_basis.get_rotation_quaternion().slerp(desired, minf(1, delta * 4 * Game.settings.scares)))
