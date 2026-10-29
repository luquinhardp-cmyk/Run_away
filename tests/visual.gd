extends Node

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var main := preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/menu.png")
	main.start(false, false)
	Game.collect("lanterna")
	Game.player.lamp_on = true
	Game.player.apply_settings()
	Game.player.position = Vector3(0, 0.1, 0)
	for i in 45: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/gameplay.png")
	main.to_menu()
	main.free()
	get_tree().quit()
