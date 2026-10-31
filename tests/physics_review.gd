extends Node
var main: Node
var report: Array = []
func _ready() -> void: run.call_deferred()
func shot(id: String, pos: Vector3, target: Vector3) -> void:
	Game.player.global_position = pos
	Game.player.rotation = Vector3.ZERO
	Game.player.camera.look_at(target)
	for i in 12: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/review/physics/"+id+".png")
	var awake := 0
	for prop in get_tree().get_nodes_in_group("physical_props"):
		if not prop.sleeping and not prop.freeze: awake += 1
	report.append({"view":id,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"memory_static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"awake_props":awake,"total_props":get_tree().get_nodes_in_group("physical_props").size()})
	print("REVIEW ",id)
func run() -> void:
	Game.testing = true
	Game.record_results = false
	Game.settings.seed = 70421
	DirAccess.make_dir_recursive_absolute("res://docs/review/physics")
	main = preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	main.start(false,false)
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
	await get_tree().create_timer(2).timeout
	await shot("01_loose_props",Vector3(-6,0.1,-15.5),Vector3(-8.8,0.5,-14))
	await shot("02_maintenance_materials",Vector3(6.3,0.1,-7),Vector3(8.5,0.7,-9))
	var drawer: Node = main.level.find_interaction("drawer")
	drawer.interact(Game.player)
	await get_tree().create_timer(1).timeout
	await shot("03_open_drawer",Vector3(5.8,0.1,-8),Vector3(5.8,0.4,-8.95))
	var door: Node = main.level.find_interaction("maintenance")
	door._set_open(true)
	await get_tree().create_timer(1).timeout
	await shot("04_hinged_door",Vector3(0,0.1,-6),Vector3(3,1.2,-8.5))
	var chain: Node = main.level.get_node("HangingMaintenanceChain")
	chain.kick(1)
	await shot("05_chain",Vector3(7,0.1,-7),Vector3(8,2.2,-8))
	main.hud.root.show()
	main.hud.set_process(true)
	await shot("06_touch_controls",Vector3(-8.8,0.1,0.1),Vector3(-8.8,0.2,1.4))
	Game.write_json("res://docs/review/physics/render_metrics.json",{"views":report,"note":"Desktop Compatibility snapshots; not Android FPS or total process memory"})
	main.to_menu()
	main.free()
	Sound.stop_all()
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()
