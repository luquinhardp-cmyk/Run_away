extends Node
signal updated
signal tutorial_save_requested
signal ended(won: bool)
var playing := false
var in_tutorial := false
var inventory_open := false
var paused := false
var player: CharacterBody3D
var enemy: CharacterBody3D
var inventory: Array[String] = []
var power := false
var doors: Dictionary = {}
var settings := {"sensitivity": 0.003, "fov": 78.0, "master": 0.8, "effects": 0.8, "music": 0.5, "mic_sensitivity": 1.0, "scares": 0.6, "quality": 1.0, "controls": 1.0, "opacity": 0.58, "control_x": 0.0, "control_y": 0.0}
var checkpoint: Dictionary = {}
var profile := ""
var elapsed_ms := 0
var last_score := 0
var run_id := ""
var record_results := true
var testing := false
var capture_in_progress := false
var last_capture_id := ""
var last_flight_pattern := ""
var history: Dictionary = {}
var _tick := 0
var _autosave := 0.0
var world: Dictionary = {}
var objectives := HorrorObjectives.new()

func difficulty_profile() -> CreatureProfile:
	return load("res://resources/ai/" + ["easy", "normal", "hard"][clampi(int(world.get("difficulty", settings.get("difficulty", 1))), 0, 2)] + ".tres")

func new_world(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return {"seed": seed_value, "variant": rng.randi_range(0, 1), "difficulty": int(settings.get("difficulty", 1)), "unlocks": {}, "events": {}, "fuse_installed": false, "generator_started": false, "blackout": false, "throwables": 0, "collected_props": [], "escaped": false}

func _process(delta: float) -> void:
	update_clock()
	if playing and not paused and record_results:
		_autosave += delta
		if _autosave >= 15:
			_autosave = 0
			save_checkpoint()

func update_clock() -> void:
	var now := Time.get_ticks_msec()
	if playing and not paused and not in_tutorial and _tick > 0: elapsed_ms += now - _tick
	_tick = now

func checkpoint_path() -> String:
	return "user://checkpoint.json" if profile.is_empty() else "user://accounts/" + profile + "/checkpoint.json"

func history_path() -> String:
	return "user://history.json" if profile.is_empty() else "user://accounts/" + profile + "/history.json"

func tutorial_path() -> String:
	return "user://tutorial.json" if profile.is_empty() else "user://accounts/" + profile + "/tutorial.json"

func tutorial_progress() -> Dictionary:
	if not FileAccess.file_exists(tutorial_path()): return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(tutorial_path()))
	if not data is Dictionary or data.get("version") != 1.0: return {}
	return data if data.get("stage") in ["tutorial", "entered"] else {}

static func supported_checkpoint(data: Variant) -> bool:
	if not data is Dictionary: return false
	var version = data.get("version")
	# JSON numbers are floats. Array.has uses strict types and rejects 2.0 in [1, 2].
	return (version is int or version is float) and (version == 1.0 or version == 2.0)

func select_profile(value: String) -> void:
	profile = value
	checkpoint = {}
	history = {}
	if FileAccess.file_exists(checkpoint_path()):
		var data = JSON.parse_string(FileAccess.get_file_as_string(checkpoint_path()))
		if supported_checkpoint(data): checkpoint = data
	if FileAccess.file_exists(history_path()):
		var data = JSON.parse_string(FileAccess.get_file_as_string(history_path()))
		if data is Dictionary: history = data
	updated.emit()

static func write_json(path: String, data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
		DirAccess.rename_absolute(path + ".tmp", path)

static func format_time(milliseconds: int) -> String:
	var seconds := milliseconds / 1000
	return "%02d:%02d" % [seconds / 60, seconds % 60]

static func score_for(items: Array, restored: bool, escaped: bool) -> int:
	var points := 0
	for item in ["lanterna", "fusivel", "cartao"]:
		if items.has(item): points += 100
	return points + (300 if restored else 0) + (500 if escaped else 0)

func local_stats() -> Dictionary:
	var result := {"totalPoints": 0, "runs": history.size(), "escapes": 0, "bestEscapeMs": 0}
	for run in history.values():
		result.totalPoints += int(run.score)
		if run.won:
			result.escapes += 1
			if result.bestEscapeMs == 0 or run.elapsed_ms < result.bestEscapeMs: result.bestEscapeMs = int(run.elapsed_ms)
	return result
var objective: String:
	get:
		return objectives.current_text()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	settings["tutorial_completed"] = false
	settings.merge({"difficulty": 1, "seed": 0, "metrics": false, "camera_motion": 0.5, "visual_scares": true, "light_variation": true,"fps_limit":0,"render_scale":0.0,"shadow_quality":-1,"vegetation_distance":0.0,"adaptive_resolution":false})
	select_profile("")
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		for key in settings: settings[key] = config.get_value("settings", key, settings[key])
	if FileAccess.file_exists("user://checkpoint.json"):
		var data = JSON.parse_string(FileAccess.get_file_as_string("user://checkpoint.json"))
		if supported_checkpoint(data): checkpoint = data
	settings["difficulty"] = config.get_value("settings", "difficulty", 1)
	settings["seed"] = config.get_value("settings", "seed", 0)
	for action in ["forward", "back", "left", "right", "run", "crouch", "interact", "flashlight", "pause", "inventory", "throw", "hold"]:
		InputMap.add_action(action)
	var keys := {"forward": KEY_W, "back": KEY_S, "left": KEY_A, "right": KEY_D, "run": KEY_SHIFT, "crouch": KEY_C, "interact": KEY_E, "flashlight": KEY_F, "pause": KEY_ESCAPE, "inventory": KEY_TAB, "throw": KEY_Q, "hold": KEY_R}
	for action in keys:
		var event := InputEventKey.new()
		event.physical_keycode = keys[action]
		InputMap.action_add_event(action, event)

func begin(resume: bool = false) -> void:
	in_tutorial = false
	inventory_open = false
	capture_in_progress = false
	_autosave = 0
	elapsed_ms = int(checkpoint.get("elapsed_ms", 0)) if resume else 0
	run_id = Crypto.new().generate_random_bytes(16).hex_encode()
	_tick = Time.get_ticks_msec()
	inventory.clear()
	doors.clear()
	power = false
	var seed_value := int(settings.get("seed", 0))
	if seed_value == 0: seed_value = randi_range(1, 2147483647)
	world = new_world(seed_value)
	if resume and not checkpoint.is_empty():
		for item in checkpoint.get("items", []): inventory.append(str(item))
		power = checkpoint.get("power", false)
		doors = checkpoint.get("doors", {}).duplicate()
		world = checkpoint.get("world", world).duplicate(true)
		# Migrate original checkpoints without resetting already restored power.
		if power:
			world.fuse_installed = true
			world.generator_started = true
	playing = true
	paused = false
	get_tree().paused = false
	updated.emit()

func collect(item: String) -> void:
	if not inventory.has(item): inventory.append(item)
	if record_results: save_checkpoint()
	updated.emit()

func save_checkpoint() -> void:
	if in_tutorial:
		tutorial_save_requested.emit()
		return
	# Always resume in the safe infirmary; inventory and mechanisms persist.
	for manager in get_tree().get_nodes_in_group("physics_managers"): manager.snapshot()
	update_clock()
	checkpoint = {"version": 2, "items": inventory.duplicate(), "power": power, "doors": doors.duplicate(true), "elapsed_ms": elapsed_ms, "world": world.duplicate(true)}
	write_json(checkpoint_path(), checkpoint)
	if record_results: Cloud.queue_checkpoint(checkpoint)
	updated.emit()

func save_settings() -> void:
	var config := ConfigFile.new()
	for key in settings: config.set_value("settings", key, settings[key])
	if not testing: config.save("user://settings.cfg")
	AudioServer.set_bus_volume_db(0, linear_to_db(settings.master))
	updated.emit()

func finish(won: bool) -> void:
	if not playing or in_tutorial: return
	update_clock()
	var restored: bool = power or world.get("generator_started", false)
	last_score = score_for(inventory, restored, won)
	world.escaped = won
	if record_results:
		var run := {"id": run_id, "won": won, "elapsed_ms": elapsed_ms, "score": last_score, "items": inventory.duplicate(), "power": restored}
		history[run_id] = run
		write_json(history_path(), history)
		Cloud.queue_run(run)
	playing = false
	capture_in_progress = false
	Mic.suspend()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ended.emit(won)

func set_paused(value: bool) -> void:
	update_clock()
	if value and playing and record_results: save_checkpoint()
	paused = value
	get_tree().paused = value
	if value: Mic.suspend()
	else: Mic.resume_capture()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value or OS.has_feature("web") or testing else Input.MOUSE_MODE_CAPTURED
	updated.emit()
