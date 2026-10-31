extends Node
var failed := 0
var passed := 0
func check(ok: bool, caption: String) -> void:
	if ok: passed += 1
	else: failed += 1; push_error(caption)
	print("PASS " if ok else "FAIL ", caption)
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	Game.testing = true
	Game.record_results = false
	var previous_profile: String = Game.profile
	var previous_checkpoint: Dictionary = Game.checkpoint.duplicate(true)
	var previous_history: Dictionary = Game.history.duplicate(true)
	var temporary_profile := "web_audit_" + str(Time.get_ticks_usec())
	var checkpoint_file := "user://accounts/" + temporary_profile + "/checkpoint.json"
	Game.write_json(checkpoint_file, {"version":2,"items":["lanterna"],"power":false,"doors":{},"elapsed_ms":1234})
	Game.select_profile(temporary_profile)
	check(Game.checkpoint.get("elapsed_ms",0) == 1234, "checkpoint JSON roundtrip remains eligible for resume")
	check(Game.supported_checkpoint(JSON.parse_string('{"version":1}')), "original v1 checkpoints remain readable")
	check(not Game.supported_checkpoint({"version":"2"}) and not Game.supported_checkpoint({"version":2.5}) and not Game.supported_checkpoint(null), "unsupported and malformed checkpoint versions remain rejected")
	DirAccess.remove_absolute(checkpoint_file)
	DirAccess.remove_absolute(checkpoint_file.get_base_dir())
	Game.profile = previous_profile
	Game.checkpoint = previous_checkpoint
	Game.history = previous_history
	Mic.set_process(false)
	Mic.consent = true
	Mic.active = true
	Mic.calibrate()
	var silence := PackedVector2Array()
	silence.resize(1024)
	for i in 600: Mic._process_samples(silence, 1.0 / 60.0)
	check(Mic.active and Mic.consent, "ten seconds of digital silence preserve microphone consent and capture")
	check(Mic.calibrated and Mic.level == 0, "silence calibrates and never creates a noise")
	var sound := PackedVector2Array()
	sound.resize(1024)
	for i in sound.size(): sound[i] = Vector2.ONE * sin(i * 0.2) * 0.05
	for i in 20: Mic._process_samples(sound, 1.0 / 60.0)
	check(Mic.level > 0, "a sound after prolonged silence opens the hearing gate")
	Mic.disable()
	check(not Mic.active and not Mic.consent, "explicit disable revokes consent")
	var main := preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	main.start(false, false)
	for i in 8: await get_tree().physics_frame
	check(main.level.nav_ready and not main.level.nav_update_pending, "initial navigation includes proxies without a deferred duplicate bake")
	check(main.level.nav_rebuilds == 0, "initial construction requires one bake")
	var hud: CanvasLayer = main.hud
	hud.root.size = Vector2(1024, 768)
	await get_tree().process_frame
	check(is_equal_approx(hud.stick.position.y, hud.root.size.y - 24 - 150 * Game.settings.controls + Game.settings.control_y), "HUD reacts to viewport resize")
	hud.move = Vector2.ONE
	hud.stick_id = 5
	hud.look_id = 6
	Game.set_paused(true)
	hud._process(0.01)
	check(hud.move == Vector2.ZERO and hud.stick_id == -1 and hud.look_id == -1, "pause clears both touches and movement")
	main.to_menu()
	main.free()
	Sound.stop_all()
	await get_tree().create_timer(0.3).timeout
	Mic.set_process(true)
	print("WEB AUDIT RESULT ",passed," passed; ",failed," failed. Synthetic microphone; no hardware claim.")
	get_tree().quit(1 if failed else 0)
