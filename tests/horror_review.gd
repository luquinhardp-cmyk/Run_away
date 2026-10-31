extends Node
var main: Node
var report: Array = []
func _ready() -> void:
	run.call_deferred()
func shot(id: String, pos: Vector3, target: Vector3) -> void:
	Game.player.global_position = pos
	Game.player.rotation = Vector3.ZERO
	Game.player.camera.look_at(target)
	for i in 12: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/review/horror/" + id + ".png")
	report.append({"view": id, "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), "memory_static_bytes": Performance.get_monitor(Performance.MEMORY_STATIC)})
	print("REVIEW ", id)
func run() -> void:
	Game.testing = true
	Game.record_results = false
	Game.settings.seed = 70421
	DirAccess.make_dir_recursive_absolute("res://docs/review/horror")
	main = preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	main.start(false, false)
	Game.player.set_physics_process(false)
	Game.player.set_process_unhandled_input(false)
	Game.enemy.set_physics_process(false)
	main.level.events.enabled = false
	main.level.horror.enabled = false
	Game.collect("lanterna")
	Game.player.lamp_on = true
	Game.player.apply_settings()
	Game.power = true
	main.hud.set_process(false)
	main.hud.root.hide()
	await shot("01_corridor_signs", Vector3(0, 0.1, -4), Vector3(-3, 2, -8))
	await shot("02_maintenance", Vector3(7, 0.1, -7.2), Vector3(9.3, 1.8, -8.5))
	await shot("03_power", Vector3(-4.4, 0.1, -32.3), Vector3(-5.3, 1.4, -33.7))
	await shot("04_security_map", Vector3(6.8, 0.1, -24), Vector3(9.5, 1.8, -25.7))
	Game.enemy.global_position = Vector3(0, 0.1, -10)
	Game.enemy.rotation.y = PI
	var rim := OmniLight3D.new()
	rim.light_energy = 1.1
	rim.omni_range = 7
	rim.light_color = Color("a0b6b2")
	main.level.add_child(rim)
	rim.global_position = Vector3(-1, 2.8, -9)
	Game.enemy.visual.animator.pause()
	await shot("05_creature_front", Vector3(0.7, 0.1, -6.7), Vector3(0, 1.5, -10))
	Game.enemy.visual.animator.play("listen", 0)
	Game.enemy.visual.animator.seek(0.85, true)
	Game.enemy.visual.animator.pause()
	await shot("06_creature_listen", Vector3(1.5, 0.1, -7), Vector3(0, 1.8, -10))
	for id in ["front", "side", "rear", "hide", "corridor", "chase", "silent", "dark"]:
		Game.enemy.visual.play_capture("capture_" + id)
		Game.enemy.visual.animator.seek(0.6, true)
		Game.enemy.visual.animator.pause()
		await shot("capture_" + id, Vector3(0, 0.1, -7), Vector3(0, 1.6, -10))
	Game.write_json("res://docs/review/horror/render_metrics.json", {"views": report, "note": "Desktop Compatibility; not Android FPS"})
	main.to_menu()
	main.free()
	Sound.stop_all()
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()
