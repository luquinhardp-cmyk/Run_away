extends Node
## Deterministic visual review; scene repositioning is confined to this test.
var main: Node
var report: Array[Dictionary] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()

func shot(name: String) -> void:
	for i in 5: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://docs/review/" + name + ".png")
	report.append({"view": name, "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "triangles": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), "objects": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)})
	print("CAPTURE ", name)

func view(pos: Vector3, target: Vector3) -> void:
	Game.player.global_position = pos
	Game.player.camera.look_at(target)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://docs/review")
	main = preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	await shot("01_menu")
	main.start(false, false)
	Game.enemy.set_physics_process(false)
	Game.player.set_physics_process(false)
	Game.collect("lanterna")
	Game.player.lamp_on = true
	Game.player.apply_settings()
	main.hud.root.hide()
	main.hud.set_process(false)
	Game.enemy.global_position = Vector3(0, 0.1, -37)
	view(Vector3(0, 0.1, -4), Vector3(0, 1.5, -20))
	await shot("02_corridor")
	view(Vector3(-3, 0.1, -16), Vector3(-8, 1.3, -16))
	await shot("03_storage")
	view(Vector3(3, 0.1, -8), Vector3(8.4, 1.3, -8))
	await shot("04_workshop")
	view(Vector3(-3, 0.1, -32), Vector3(-8.5, 1.3, -32))
	await shot("05_power")
	view(Vector3(-17, -1.7, -30), Vector3(-21, -0.7, -34))
	await shot("06_basement")
	view(Vector3(0, 0.1, 15), Vector3(-2, 1.6, 2))
	await shot("07_exterior")
	Game.enemy.global_position = Vector3(0, 0.1, -10)
	Game.enemy.rotation.y = PI
	view(Vector3(1.2, 0.15, -6), Vector3(0, 1.4, -10))
	var rim := OmniLight3D.new()
	rim.position = Vector3(-1.2, 2.5, -11)
	rim.omni_range = 5
	rim.light_energy = 1.4
	rim.light_color = Color(0.5, 0.52, 0.44)
	main.level.add_child(rim)
	Game.enemy.visual.animator.pause()
	await shot("08_escutador")
	Game.enemy.transition(Game.enemy.State.ALERT)
	Game.enemy.visual.animator.play("listen", 0)
	Game.enemy.visual.animator.seek(0.85, true)
	Game.enemy.visual.animator.advance(0)
	Game.enemy.visual.animator.pause()
	await shot("09_listen")
	# Stand in an actual slatted locker and watch the listening creature.
	var locker: Node3D
	for child in main.level.get_children():
		if child.get("kind") == "hide" and child.position.z < -30: locker = child
	Game.enemy.global_position = Vector3(-2.9, 0.1, -32)
	Game.enemy.rotation.y = PI / 2
	Game.player.enter_hide(locker)
	Game.player.camera.look_at(Game.enemy.global_position + Vector3.UP * 1.8)
	await shot("10_locker")
	Game.player.interact()
	var file := FileAccess.open("res://docs/review/render_metrics.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	main.to_menu()
	main.free()
	Sound.stop_all()
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()
