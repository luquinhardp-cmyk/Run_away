extends Node
## One reproducible full run: normal player physics and live creature, no warps.
var main: Node
var transitions: Array[int] = []
var success := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run.call_deferred()

func travel(destination: Vector3, limit: float = 35) -> bool:
	var player := Game.player
	var elapsed := 0.0
	var refresh := 0.0
	var points := PackedVector3Array()
	var index := 0
	while Game.playing and elapsed < limit:
		if player.global_position.distance_to(destination) < 0.55:
			player.touch_move = Vector2.ZERO
			player.touch_run = false
			return true
		if refresh <= 0:
			points = NavigationServer3D.map_get_path(Game.enemy.agent.get_navigation_map(), player.global_position, destination, true)
			index = 1 if points.size() > 1 else 0
			refresh = 0.8
		if points.is_empty(): return false
		if index < points.size() - 1 and player.global_position.distance_to(points[index]) < 0.5: index += 1
		var direction := points[index] - player.global_position
		direction.y = 0
		player.rotation.y = atan2(-direction.x, -direction.z)
		player.camera.rotation = Vector3.ZERO
		player.touch_move = Vector2(0, -1)
		player.touch_run = true
		for door in get_tree().get_nodes_in_group("doors"):
			if not door.open and door._door_unlocked() and door.global_position.distance_to(player.global_position + Vector3.UP) < 2.2: door.interact(player)
		await get_tree().physics_frame
		var delta := get_physics_process_delta_time()
		elapsed += delta
		refresh -= delta
	print("TRAVEL FAILED ", destination, " player=", player.global_position, " creature=", Game.enemy.global_position, " state=", Game.enemy.state)
	return false

func use(id: String) -> bool:
	var object: Node3D = main.level.find_interaction(id)
	if object == null: return false
	if id == "radio" and object.enabled: return true
	var player := Game.player
	player.touch_move = Vector2.ZERO
	player.touch_run = false
	for i in 8: await get_tree().physics_frame
	var direction: Vector3 = object.global_position - player.camera.global_position
	player.rotation.y = atan2(-direction.x, -direction.z)
	player.pitch = atan2(direction.y, Vector2(direction.x, direction.z).length())
	player.camera.rotation = Vector3(player.pitch, 0, 0)
	await get_tree().physics_frame
	player._detect_interaction()
	if player.focus != object:
		print("INTERACTION BLOCKED ", id, " focus=", player.focus, " player=", player.global_position)
		return false
	player.interact()
	return true

func run() -> void:
	var backup := Game.checkpoint.duplicate(true)
	var preferences := Game.settings.duplicate(true)
	var existed := FileAccess.file_exists(Game.checkpoint_path())
	var content := FileAccess.get_file_as_string(Game.checkpoint_path()) if existed else ""
	Game.record_results = false
	Game.testing = true
	Game.settings.seed = 70421
	Game.settings.difficulty = int(OS.get_environment("ECOS_TEST_DIFFICULTY")) if OS.has_environment("ECOS_TEST_DIFFICULTY") else 0
	Engine.time_scale = 4
	main = preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	main.start(false, false)
	Game.enemy.state_changed.connect(func(_old: int, next: int): transitions.append(next))
	for i in 15: await get_tree().physics_frame
	# Visit each actual source/object using capsule movement, actual colliders and aim.
	for stage in [[Vector3(-7, 0.1, 0), "lanterna"], [Vector3(7, 0.1, -8), "fusivel"], [Vector3(12, 0.1, -10.7), "radio"], [Vector3(12, 0.1, -23), ""], [Vector3(-5.3, 0.1, -32.2), "fuse_panel"], [Vector3(-6.8, 0.1, -32), "generator"], [Vector3(7, 0.1, -24), "cartao"], [Vector3(12, 0.1, -23), ""], [Vector3(12, 0.1, -10.7), "radio"], [Vector3(0, 0.1, -8), ""], [Vector3(0, 0.1, -40), "exit"]]:
		if not await travel(stage[0]): success = false; break
		if stage[1] != "" and not await use(stage[1]): success = false; break
		print("STAGE ", stage[1], " creature_state=", Game.enemy.state)
	success = success and not Game.playing and main.screen == "ended" and Game.world.escaped
	print("PHYSICAL PLAYTHROUGH ", "PASS" if success else "FAIL", " transitions=", transitions, " points=", Game.last_score)
	main.to_menu()
	main.free()
	Engine.time_scale = 1
	Game.settings = preferences
	Game.checkpoint = backup
	if existed:
		var file := FileAccess.open(Game.checkpoint_path(), FileAccess.WRITE)
		file.store_string(content)
		file.close()
	else: DirAccess.remove_absolute(Game.checkpoint_path())
	await get_tree().create_timer(0.2).timeout
	get_tree().quit(0 if success else 1)
