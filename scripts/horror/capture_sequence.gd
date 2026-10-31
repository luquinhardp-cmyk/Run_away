extends Node
signal started(id: String)
signal finished
var creature: CharacterBody3D
var definitions: Array[HorrorCapture] = []
var active := false
var selected: HorrorCapture
var elapsed := 0.0
var last_id := ""
var rng := RandomNumberGenerator.new()
var initial_camera := Vector3.ZERO
var sound_played := false
var initial_fov := 78.0
var initial_rotation := Vector3.ZERO
var initial_world := Vector3.ZERO
var face_light: OmniLight3D

func _ready() -> void:
	creature = get_parent()
	last_id = Game.last_capture_id
	rng.seed = int(Game.world.get("seed", 1)) + 811
	for id in ["front", "side", "rear", "hide", "corridor", "chase", "silent", "dark"]:
		definitions.append(load("res://resources/horror/captures/" + id + ".tres"))

func choose() -> HorrorCapture:
	var eligible: Array[HorrorCapture] = []
	for definition in definitions:
		if definition.weight > 0 and definition.compatible(creature, Game.player): eligible.append(definition)
	if eligible.size() > 1:
		eligible = eligible.filter(func(item: HorrorCapture): return item.id != last_id)
	if eligible.is_empty(): return definitions[0]
	var total := 0.0
	for definition in eligible: total += definition.weight
	var roll := rng.randf() * total
	for definition in eligible:
		roll -= definition.weight
		if roll <= 0: return definition
	return eligible[-1]

func valid_contact() -> bool:
	if not Game.playing or not is_instance_valid(Game.player): return false
	if is_instance_valid(creature.captured_hide) and creature.captured_hide.has_occupant():
		return creature.global_position.distance_to(creature.captured_hide.approach_position()) < 1.6
	return creature.sees_player() and creature.global_position.distance_to(Game.player.global_position) <= creature.profile.attack_distance + 0.5

func begin() -> bool:
	if active or Game.capture_in_progress or not valid_contact(): return false
	selected = choose()
	last_id = selected.id
	Game.last_capture_id = last_id
	active = true
	Game.capture_in_progress = true
	Sound._settings()
	elapsed = 0
	sound_played = false
	initial_camera = Game.player.camera.position
	initial_rotation = Game.player.camera.rotation
	initial_world = Game.player.camera.global_position
	initial_fov = Game.player.camera.fov
	if Game.settings.get("visual_scares",true):
		face_light=OmniLight3D.new()
		face_light.omni_range=2.2
		face_light.light_color=Color(.75,.82,.70)
		face_light.light_energy=0
		creature.add_child(face_light)
	Game.player.velocity = Vector3.ZERO
	Mic.suspend()
	creature.visual.play_capture(selected.clip)
	if selected.id == "hide" and is_instance_valid(creature.captured_hide):
		creature.captured_hide.reveal_for_capture()
	started.emit(selected.id)
	return true

func face_position() -> Vector3:
	return creature.visual.head_position()+Vector3.UP*.17-creature.global_basis.z*.20

func _process(delta: float) -> void:
	if not active: return
	if not Game.playing or not is_instance_valid(Game.player): _release(); return
	if Game.paused: return
	elapsed += delta
	var progress := clampf(elapsed / maxf(0.5, selected.duration), 0, 1)
	var strength := float(Game.settings.get("scares", 0.6)) * float(Game.settings.get("camera_motion", 0.5)) if Game.settings.get("visual_scares", true) else 0.0
	var camera: Camera3D = Game.player.camera
	var focus := face_position()
	var direction: Vector3 = focus - camera.global_position
	if strength > 0 and direction.length() > 0.05:
		var amount := smoothstep(.02,.27,progress)*clampf(float(Game.settings.get("camera_motion",.5))*2,0,1)
		# Approach the front of the face horizontally, rather than the underside of the skull.
		var close := focus-creature.global_basis.z*.8
		var ray := PhysicsRayQueryParameters3D.create(initial_world,close,1,[creature.get_rid(),Game.player.get_rid()])
		var hit := creature.get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty(): close=hit.position+(initial_world-hit.position).normalized()*.08
		camera.global_position=initial_world.lerp(close,amount)
		camera.fov=lerpf(initial_fov,42,amount)
		direction=focus-camera.global_position
		var desired := Basis.looking_at(direction.normalized(), Vector3.UP).get_rotation_quaternion()
		camera.global_basis = Basis(camera.global_basis.get_rotation_quaternion().slerp(desired, minf(1, delta * 22)))
		camera.rotate_object_local(Vector3.FORWARD, selected.camera_roll * sin(progress * PI) * delta * 10 * strength)
	if is_instance_valid(face_light):
		face_light.global_position=focus+(camera.global_position-focus).normalized()*.3
		face_light.light_energy=smoothstep(.02,.12,progress)*lerpf(.6,1.6,float(Game.settings.scares))
	if not sound_played and progress >= 0.18:
		sound_played = true
		Sound.creature_cue("capture", focus, -6 - (1 - Game.settings.scares) * 8)
	if elapsed >= maxf(0.5, selected.duration):
		_release()
		Game.finish(false)
		finished.emit()

func _release() -> void:
	active = false
	Game.capture_in_progress = false
	Sound._settings()
	if is_instance_valid(face_light): face_light.queue_free()
	if is_instance_valid(Game.player):
		Game.player.camera.position = initial_camera
		Game.player.camera.rotation = initial_rotation
		Game.player.camera.fov = initial_fov

func _exit_tree() -> void:
	if active: _release()
