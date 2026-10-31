extends Node
var passed := 0
var failed := 0
func check(ok: bool, title: String) -> void:
	if ok: passed += 1
	else: failed += 1; push_error(title)
	print("PASS " if ok else "FAIL ", title)
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	Game.testing = true
	Game.record_results = false
	Game.settings.seed = 70421
	var main := preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	main.start(false, false)
	for i in 15: await get_tree().physics_frame
	var enemy := Game.enemy
	var player := Game.player
	enemy.set_physics_process(false)
	player.set_physics_process(false)
	main.level.events.enabled = false
	var director: Node = main.level.horror
	director.set_process(false)
	var signs := get_tree().get_nodes_in_group("world_signs")
	check(signs.size() >= 15, "physical signage replaces room labels and adds narrative")
	var signs_valid := true
	for sign in signs:
		signs_valid = signs_valid and sign.panel != null and not sign.lettering.double_sided and not sign.lettering.no_depth_test and sign.lettering.billboard == BaseMaterial3D.BILLBOARD_DISABLED
	check(signs_valid, "all signs have panels, occlusion and fixed front faces")
	check(main.hud.root != null, "HUD retained independently of signage")
	var sequence: Node = enemy.capture_sequence
	check(sequence.definitions.size() == 8, "eight resource capture definitions loaded")
	check(not sequence.begin(), "distant creature cannot seize controls")
	player.global_position = Vector3(0, 0.1, -12)
	player.rotation = Vector3.ZERO
	enemy.global_position = Vector3(0, 0.1, -13)
	enemy.rotation.y = PI
	for i in 3: await get_tree().physics_frame
	var front: HorrorCapture = load("res://resources/horror/captures/front.tres")
	var rear: HorrorCapture = load("res://resources/horror/captures/rear.tres")
	check(front.compatible(enemy, player) and not rear.compatible(enemy, player), "front and rear use actual relative orientation")
	player.rotation.y = PI
	check(rear.compatible(enemy, player) and not front.compatible(enemy, player), "rear capture follows player orientation")
	player.rotation = Vector3.ZERO
	sequence.last_id = "front"
	var repeated := false
	for i in 30:
		if sequence.choose().id == "front": repeated = true
	check(not repeated, "capture selection excludes immediate repeat with alternatives")
	check(not load("res://resources/horror/captures/hide.tres").compatible(enemy, player), "hide capture requires confirmed occupied hiding place")
	enemy.global_position = Vector3(8, 0.1, -12)
	check(not sequence.valid_contact(), "walls and distance prevent remote capture")
	var knock: HorrorScare = load("res://resources/horror/events/knock.tres")
	check(not director.trigger(knock, main.level.find_interaction("workshop")), "global director cooldown blocks event requests")
	var old_history: Array = director.history.duplicate()
	director._noise({"kind": "microfone", "intensity": 0.8})
	check(director.tension >= 1 and director.history == old_history, "microphone raises attention without forcing a scare")
	Game.settings.light_variation = false
	check(director.eligible_source(load("res://resources/horror/events/light_dip.tres")) == null, "accessibility disables light variation events")
	Game.settings.light_variation = true
	director.counts.knock = 3
	check(director.eligible_source(knock) == null, "event maximum prevents repeated knock spam")
	director._persist_state()
	check(Game.world.horror.counts.knock == 3 and Game.world.horror.rng_state is String, "director state persists counts and exact RNG state")
	var banks_ok := true
	for id in ["patrol", "joint", "drag", "alert", "investigate", "search", "sniff", "chase", "attack", "capture", "knock", "creak"]:
		var bank: Resource = load("res://resources/horror/audio/" + id + ".tres")
		banks_ok = banks_ok and bank.samples.size() >= 2 and bank.min_interval > 0
	check(banks_ok, "twelve audio banks supply variations and cooldowns")
	enemy.global_position = Vector3(0, 0.1, -13)
	Game.settings.camera_motion = 0.5
	Game.settings.visual_scares = true
	var original_fov: float = player.camera.fov
	var original_camera: Vector3 = player.camera.position
	var original_body: Vector3 = player.global_position
	check(sequence.begin(), "visible contact starts face closeup")
	sequence._process(sequence.selected.duration * 0.35)
	var face: Vector3 = sequence.face_position()
	check(is_equal_approx(player.camera.fov, 42.0) and player.camera.global_position.distance_to(face) < 0.85, "capture zoom tightly frames face")
	check((-player.camera.global_basis.z).dot((face-player.camera.global_position).normalized()) > 0.98, "capture camera points at monster face")
	check(player.global_position == original_body and sequence.face_light.light_energy > 0, "closeup lights face without moving physical player")
	var capture_audio := false
	for voice in Sound.get_children():
		if voice is AudioStreamPlayer3D and voice.bus == "Threat":
			capture_audio = voice.volume_db > -12 and voice.max_db <= -6 and voice.unit_size == 3
	check(capture_audio, "capture uses louder bounded priority sound")
	sequence._release()
	check(player.camera.position == original_camera and is_equal_approx(player.camera.fov, original_fov), "capture releases camera position and FOV")
	Game.settings.camera_motion = 0.0
	Game.settings.visual_scares = false
	var initial_pos: Vector3 = player.camera.position
	var initial_rotation: Vector3 = player.camera.rotation
	check(sequence.begin(), "confirmed nearby visible enemy starts capture")
	check(Game.capture_in_progress and not sequence.begin(), "capture has single ownership and rejects overlap")
	var before: Vector3 = player.global_position
	player.touch_move = Vector2(0, -1)
	player._physics_process(0.1)
	check(player.global_position == before, "movement remains locked during confirmed defeat")
	await get_tree().create_timer(0.4).timeout
	check(player.camera.position == initial_pos and player.camera.rotation == initial_rotation, "zero motion and visual effects preserve camera")
	check(get_tree().get_nodes_in_group("creature").size() <= 1, "director never duplicates creature")
	await get_tree().create_timer(1.1).timeout
	check(not Game.playing and not Game.capture_in_progress, "capture ends in defeat and releases lock")
	check(Game.last_capture_id != "", "capture history survives scene recreation")
	main.to_menu()
	main.free()
	Sound.stop_all()
	await get_tree().create_timer(0.3).timeout
	print("HORROR RESULT ", passed, " passed; ", failed, " failed")
	get_tree().quit(0 if failed == 0 else 1)

