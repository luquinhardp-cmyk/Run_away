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
	Game.player.velocity = Vector3.ZERO
	Mic.suspend()
	creature.visual.play_capture(selected.clip)
	if selected.id == "hide" and is_instance_valid(creature.captured_hide):
		creature.captured_hide.reveal_for_capture()
	started.emit(selected.id)
	return true

func _process(delta: float) -> void:
	if not active: return
	if not Game.playing or not is_instance_valid(Game.player): _release(); return
	if Game.paused: return
	elapsed += delta
	var progress := clampf(elapsed / maxf(0.5, selected.duration), 0, 1)
	var strength := float(Game.settings.get("scares", 0.6)) * float(Game.settings.get("camera_motion", 0.5)) if Game.settings.get("visual_scares", true) else 0.0
	var camera: Camera3D = Game.player.camera
	var direction: Vector3 = creature.visual.head_position() - camera.global_position
	if strength > 0 and direction.length() > 0.05:
		var desired := Basis.looking_at(direction.normalized(), Vector3.UP).get_rotation_quaternion()
		camera.global_basis = Basis(camera.global_basis.get_rotation_quaternion().slerp(desired, minf(1, delta * 6 * strength)))
		camera.rotate_object_local(Vector3.FORWARD, selected.camera_roll * sin(progress * PI) * delta * 10 * strength)
		# Local visual offset only; neither body is moved or teleported.
		camera.position = initial_camera + Vector3(0, -0.02, selected.camera_pull) * sin(progress * PI) * strength
	if not sound_played and progress >= 0.18:
		sound_played = true
		Sound.creature_cue("capture", creature.visual.head_position(), -16 - (1 - Game.settings.scares) * 12)
	if elapsed >= maxf(0.5, selected.duration):
		_release()
		Game.finish(false)
		finished.emit()

func _release() -> void:
	active = false
	Game.capture_in_progress = false
	Sound._settings()
	if is_instance_valid(Game.player): Game.player.camera.position = initial_camera

func _exit_tree() -> void:
	if active: _release()
