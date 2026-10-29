extends Node
signal updated
signal ended(won: bool)
var playing := false
var paused := false
var player: CharacterBody3D
var enemy: CharacterBody3D
var inventory: Array[String] = []
var power := false
var doors: Dictionary = {}
var settings := {"sensitivity": 0.003, "fov": 78.0, "master": 0.8, "effects": 0.8, "music": 0.5, "mic_sensitivity": 1.0, "scares": 0.6, "quality": 1.0, "controls": 1.0, "opacity": 0.58, "control_x": 0.0, "control_y": 0.0}
var checkpoint: Dictionary = {}
var objective: String:
	get:
		if not inventory.has("lanterna"): return "01 / Encontre a lanterna na enfermaria."
		if not inventory.has("fusivel"): return "02 / Procure um fusível na manutenção."
		if not power: return "03 / Restaure a energia na sala de energia."
		if not inventory.has("cartao"): return "04 / Pegue o cartão na segurança."
		return "05 / Abra a saída no fim do corredor."

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		for key in settings: settings[key] = config.get_value("settings", key, settings[key])
	if FileAccess.file_exists("user://checkpoint.json"):
		var data = JSON.parse_string(FileAccess.get_file_as_string("user://checkpoint.json"))
		if data is Dictionary and data.get("version") == 1: checkpoint = data
	for action in ["forward", "back", "left", "right", "run", "crouch", "interact", "flashlight", "pause", "inventory"]:
		InputMap.add_action(action)
	var keys := {"forward": KEY_W, "back": KEY_S, "left": KEY_A, "right": KEY_D, "run": KEY_SHIFT, "crouch": KEY_C, "interact": KEY_E, "flashlight": KEY_F, "pause": KEY_ESCAPE, "inventory": KEY_TAB}
	for action in keys:
		var event := InputEventKey.new()
		event.physical_keycode = keys[action]
		InputMap.action_add_event(action, event)

func begin(resume: bool = false) -> void:
	inventory.clear()
	doors.clear()
	power = false
	if resume and not checkpoint.is_empty():
		for item in checkpoint.get("items", []): inventory.append(str(item))
		power = checkpoint.get("power", false)
		doors = checkpoint.get("doors", {}).duplicate()
	playing = true
	paused = false
	get_tree().paused = false
	updated.emit()

func collect(item: String) -> void:
	if not inventory.has(item): inventory.append(item)
	updated.emit()

func save_checkpoint() -> void:
	# Always resume in the safe infirmary; inventory and mechanisms persist.
	checkpoint = {"version": 1, "items": inventory.duplicate(), "power": power, "doors": doors.duplicate(true)}
	var file := FileAccess.open("user://checkpoint.json.tmp", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(checkpoint))
		file.close()
		DirAccess.rename_absolute("user://checkpoint.json.tmp", "user://checkpoint.json")
	updated.emit()

func save_settings() -> void:
	var config := ConfigFile.new()
	for key in settings: config.set_value("settings", key, settings[key])
	config.save("user://settings.cfg")
	AudioServer.set_bus_volume_db(0, linear_to_db(settings.master))
	Engine.max_fps = 30 if settings.quality < 1 else 60
	updated.emit()

func finish(won: bool) -> void:
	if not playing: return
	playing = false
	Mic.suspend()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ended.emit(won)

func set_paused(value: bool) -> void:
	paused = value
	get_tree().paused = value
	if value: Mic.suspend()
	else: Mic.resume_capture()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED
	updated.emit()
