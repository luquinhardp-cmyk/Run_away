extends Node
var main: Node
var report: Array[Dictionary] = []

func _ready() -> void:
	run.call_deferred()

func shot(id: String, position: Vector3, target: Vector3) -> void:
	Game.player.global_position = position
	Game.player.rotation = Vector3.ZERO
	Game.player.camera.look_at(target)
	for i in 12: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/review/expansion/" + id + ".png")
	report.append({"view": id, "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), "memory_static_bytes": Performance.get_monitor(Performance.MEMORY_STATIC)})
	print("REVIEW ", id)

func run() -> void:
	Game.testing = true
	Game.record_results = false
	Game.settings.seed = 70421
	DirAccess.make_dir_recursive_absolute("res://docs/review/expansion")
	main = preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	main.start(false, false)
	Game.player.set_physics_process(false)
	Game.player.set_process_unhandled_input(false)
	Game.enemy.set_physics_process(false)
	main.level.events.enabled = false
	Game.collect("lanterna")
	Game.player.lamp_on = true
	Game.player.apply_settings()
	Game.power = true
	main.hud.set_process(false)
	main.hud.root.hide()
	await shot("01_gallery", Vector3(12, 0.1, -8), Vector3(12, 1.4, -22))
	await shot("02_workshop", Vector3(9.8, 0.1, -16), Vector3(11.6, 1, -18))
	await shot("03_panel", Vector3(-4.4, 0.1, -32.3), Vector3(-5.3, 1.4, -33.7))
	main.hud.root.show()
	main.hud.set_process(true)
	Game.world.throwables = 2
	await shot("04_touch_hud", Vector3(12, 0.1, -14), Vector3(12, 1.2, -22))
	Game.write_json("res://docs/review/expansion/render_metrics.json", {"views": report, "renderer": "Compatibility", "note": "Desktop snapshots; not Android FPS benchmark"})
	main.to_menu()
	main.free()
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()
