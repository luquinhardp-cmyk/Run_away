extends Node
var passed := 0
var failed := 0
var main: Node
var noises: Array[Dictionary] = []

func check(ok: bool, title: String) -> void:
	if ok: passed += 1
	else: failed += 1; push_error("FAIL " + title)
	print("PASS " if ok else "FAIL ", title)

func frames(count: int = 3) -> void:
	for i in count: await get_tree().physics_frame

func item(id: String) -> Node3D:
	return main.level.find_interaction(id)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run.call_deferred()

func run() -> void:
	var backup := Game.checkpoint.duplicate(true)
	var settings := Game.settings.duplicate(true)
	var saved_exists := FileAccess.file_exists(Game.checkpoint_path())
	var saved := FileAccess.get_file_as_string(Game.checkpoint_path()) if saved_exists else ""
	Game.record_results = false
	Game.testing = true
	Game.settings.seed = 70421
	Game.settings.difficulty = 1
	main = preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	main.start(false, false)
	await frames(15)
	main.level.events.enabled = false
	main.level.horror.enabled = false
	var player := Game.player
	var enemy := Game.enemy
	enemy.set_physics_process(false)
	player.set_physics_process(false)
	NoiseBus.emitted.connect(func(event: Dictionary): noises.append(event))
	check(Game.new_world(70421) == Game.new_world(70421), "seed reproduces world configuration")
	check(Game.difficulty_profile().search_duration == 16, "normal Resource loaded")
	var normal: CreatureProfile = load("res://resources/ai/normal.tres")
	var hard: CreatureProfile = load("res://resources/ai/hard.tres")
	check(hard.search_duration > normal.search_duration and hard.throwable_supply < normal.throwable_supply, "difficulty changes persistence and resources, not only speed")
	var map: RID = enemy.agent.get_navigation_map()
	var loop := NavigationServer3D.map_get_path(map, Vector3(8, 0.1, -8), Vector3(8, 0.1, -24), true)
	check(loop.size() > 2 and loop[-1].distance_to(Vector3(8, 0.1, -24)) < 0.8, "maintenance and security connected by lateral loop")
	var uses_gallery := false
	for point in loop:
		if point.x > 10: uses_gallery = true
	check(uses_gallery, "locked security door makes path use real alternative route")
	item("workshop").interact(player)
	check(not item("workshop").open, "shortcut refuses wrong or missing key")
	item("chave_oficina").interact(player)
	item("workshop").interact(player)
	await frames(8)
	check(item("workshop").open and Game.world.unlocks.workshop and not main.level.nav_gates.has("workshop"), "matching key permanently unlocks shortcut and navigation")
	player.global_position = Vector3(2, 0.1, -16)
	item("workshop").interact(player)
	check(item("workshop").open, "door refuses to close onto actor")
	player.global_position = Vector3(-7, 0.1, 0)
	item("lanterna").interact(player)
	item("fusivel").interact(player)
	item("generator").interact(player)
	check(not Game.power, "generator requires actual fuse installation")
	item("fuse_panel").interact(player)
	item("generator").interact(player)
	check(Game.power and Game.world.fuse_installed and Game.world.generator_started, "panel and generator complete electrical puzzle")
	check(main.level.events.trigger("blackout") and not Game.power and Game.world.blackout, "blackout changes real power state")
	check(not main.level.events.trigger("blackout"), "persistent event never repeats on the same run")
	item("generator").interact(player)
	check(Game.power and not Game.world.blackout, "blackout recoverable without losing fuse")
	var rebuilds: int = main.level.nav_rebuilds
	check(main.level.events.trigger("pipe"), "physical environmental event triggered")
	await frames(8)
	check(main.level.nav_rebuilds > rebuilds, "physical obstacle updates navigation on demand")
	var bypass := NavigationServer3D.map_get_path(map, Vector3(0.8, 0.1, -18), Vector3(0.8, 0.1, -22), true)
	check(bypass.size() > 1 and bypass[-1].distance_to(Vector3(0.8, 0.1, -22)) < 0.8, "fallen pipe preserves an escape route")
	item("radio").interact(player)
	item("radio")._process(0.1)
	check(item("radio").enabled and item("radio").device_audio.playing and noises[-1].position == item("radio").global_position, "radio uses spatial audio and actual source position")
	item("radio").interact(player)
	check(not item("radio").device_audio.playing, "radio can be switched off")
	item("alarm").set_device(true)
	item("alarm")._process(10)
	check(not item("alarm").enabled, "alarm automatically ends")
	check(noises[-1].has_all(["event_id", "source_id", "world_position", "category", "loudness", "duration", "timestamp", "propagation_profile"]), "typed standard noise preserves complete contract")
	player.global_position = Vector3(12, 0.1, -10)
	player.rotation = Vector3.ZERO
	player.camera.rotation = Vector3.ZERO
	item("metal_0").interact(player)
	var prop: Node3D = player.throw_object()
	check(is_instance_valid(prop) and prop is RigidBody3D and int(Game.world.throwables) == 0, "collect and throw real rigid body consumes one resource")
	await frames(140)
	var impact := false
	for event in noises:
		if event.kind == "objeto_arremessado": impact = true
	check(impact, "physical collision produces distraction noise")
	Game.world.throwables = 10
	for i in 12: player.throw_object()
	check(get_tree().get_nodes_in_group("throwables").size() <= 8, "physics object cap enforced")
	for object in get_tree().get_nodes_in_group("throwables"): object.queue_free()
	Game.world.throwables = 0
	await frames()
	# Real movement into a closed but operable door exercises navigation recovery.
	player.global_position = Vector3(-7, 0.1, 0)
	var patrol_backup: Array[Vector3] = enemy.patrol.duplicate()
	enemy.patrol.clear()
	enemy.patrol.append(Vector3(8, 0.1, -8))
	enemy.patrol_index = 0
	enemy.global_position = Vector3(0, 0.1, -8)
	item("maintenance")._set_open(false)
	enemy.age = 10
	enemy.transition(enemy.State.PATROL)
	enemy.set_physics_process(true)
	await frames(300)
	enemy.set_physics_process(false)
	check(item("maintenance").open and enemy.global_position.x > 2.4, "navigation recovery opens an operable door without teleporting")
	enemy.patrol = patrol_backup
	enemy.global_position = Vector3(0, 0.1, -24)
	enemy.rotation.y = -PI / 2
	player.global_position = Vector3(4, 0.1, -24)
	item("security")._set_open(false)
	await frames()
	check(not enemy.sees_player(), "closed door blocks actual vision ray")
	item("security")._set_open(true)
	await frames(45) # Wait for the real hinged leaf to clear the line of sight.
	check(enemy.sees_player(), "opening same door restores actual line of sight")
	enemy.age = 10
	enemy.global_position = Vector3(0, 0.1, -10)
	enemy.rotation.y = 0
	player.global_position = Vector3(0, 0.1, -14)
	await frames()
	check(enemy.sees_player(), "visual sensor detects exposed player")
	enemy.memory.saw(player.global_position, enemy.age)
	enemy.transition(enemy.State.CHASE)
	var remembered: Vector3 = enemy.memory.visual_position
	NoiseBus.emit_noise(item("radio"), 1.0, "radio", 38)
	check(enemy.state == enemy.State.CHASE and enemy.memory.visual_position == remembered, "noise never redirects visual chase memory")
	player.global_position = Vector3(-7, 0.1, -16)
	enemy.unseen = enemy.profile.lost_after + 1
	enemy.perceive_clock = 10
	enemy._physics_process(0.02)
	check(enemy.state == enemy.State.LOST and enemy.last_known == remembered, "loss leads to last observed position, not current hidden position")
	enemy.timer = 3
	enemy._physics_process(0.02)
	check(enemy.state == enemy.State.SEARCH and enemy.search.points.size() > 1, "loss builds multiple reachable search points")
	var spot := item("locker_-5_-15")
	player.global_position = spot.approach_position() + Vector3.UP * 0.1
	enemy.global_position = Vector3(0, 0.1, -20)
	player.enter_hide(spot)
	check(player.hidden and spot.has_occupant() and not enemy.sees_player(), "opaque locker protects vision and tracks occupancy")
	enemy.memory.hide_clues.clear()
	enemy.last_known = spot.approach_position()
	enemy.transition(enemy.State.INVESTIGATE)
	enemy.transition(enemy.State.SEARCH)
	enemy._search_hides(0.1)
	check(not is_instance_valid(enemy.checking_hide), "unclued locker does not reveal player magically")
	enemy.global_position = spot.approach_position()
	NoiseBus.emit_noise(player, 1.0, "microfone", 30)
	check(float(enemy.memory.hide_clues.get(spot.item_id, 0)) > 0.18, "microphone raises local hiding-place suspicion")
	enemy.transition(enemy.State.INVESTIGATE)
	enemy.transition(enemy.State.SEARCH)
	enemy._search_hides(0.1)
	check(enemy.state == enemy.State.SEARCH and enemy.hide_timer > 0, "hide investigation warns before capture")
	player.interact()
	check(not player.hidden and not spot.has_occupant(), "player can leave while locker is being investigated")
	enemy._search_hides(enemy.profile.hide_warning + 0.1)
	check(enemy.state != enemy.State.ATTACK, "empty locker investigation does not capture escaped player")
	Mic.floor_db = -60
	Mic.gate_open = false
	check(Mic.update_gate(-50, 0.02) > 0 and Mic.update_gate(-53, 0.02) > 0 and Mic.update_gate(-56, 0.02) == 0, "microphone hysteresis prevents gate flicker")
	Mic.floor_db = -60
	for i in 600: Mic.update_gate(-43, 0.05)
	check(Mic.floor_db > -48, "steady fan noise is absorbed gradually")
	Game.save_checkpoint()
	var seed: int = Game.world.seed
	main.start(true, false)
	await frames(12)
	main.level.events.enabled = false
	Game.enemy.set_physics_process(false)
	check(Game.world.seed == seed and Game.world.unlocks.workshop and Game.world.events.pipe and Game.power, "checkpoint restores seed, shortcuts, events and puzzle progress")
	check(item("metal_0") == null, "collected distraction cannot be duplicated on resume")
	item("cartao").interact(Game.player)
	item("exit").interact(Game.player)
	check(not Game.playing and main.screen == "ended" and Game.last_score == 1100, "integrated puzzle and survival results lead to successful escape")
	main.to_menu()
	main.free()
	Sound.stop_all()
	await get_tree().create_timer(0.3).timeout
	await frames()
	Game.checkpoint = backup
	Game.settings = settings
	if saved_exists:
		var file := FileAccess.open(Game.checkpoint_path(), FileAccess.WRITE)
		file.store_string(saved)
		file.close()
	else: DirAccess.remove_absolute(Game.checkpoint_path())
	print("EXPANSION RESULT ", passed, " passed; ", failed, " failed")
	get_tree().quit(1 if failed else 0)
