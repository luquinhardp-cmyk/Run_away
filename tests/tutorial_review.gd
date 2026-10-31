extends Node
func _ready() -> void:
	run.call_deferred()
func shot(name: String) -> void:
	for i in 10: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/review/tutorial-ui/"+name+".png")
func run() -> void:
	Game.testing=true
	Game.record_results=false
	Game.settings.quality=1
	var main=preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	main.start_tutorial(false,false)
	await shot("preparation")
	for id in ["tutorial_key","lanterna","fusivel"]: Game.collect(id)
	Game.world.throwables=3
	main.hud.toggle_inventory()
	print("UI RECT ",main.hud.inventory_window.root.size," panel ",main.hud.inventory_window.panel.size," min ",main.hud.inventory_window.panel.get_combined_minimum_size())
	await shot("backpack")
	main.hud.inventory_window.select("lanterna")
	main.hud.inventory_window.examine_selected()
	await shot("inspection")
	main.hud.close_inventory()
	main.to_menu()
	main.new_game_screen()
	await shot("new_game")
	main.free()
	Sound.stop_all()
	await get_tree().create_timer(.3).timeout
	get_tree().quit()
