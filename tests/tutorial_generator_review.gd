extends "res://tests/tutorial_runner.gd"
func screenshot(name: String) -> void:
	for i in 10: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/review/tutorial-generator/"+name+".png")
func run() -> void:
	Game.testing=true
	Game.record_results=false
	Game.settings.quality=1
	main=preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	main.start_tutorial(false,false)
	main.level.step=7
	main.level.changed.emit()
	await pose(Vector3(1,.1,-27))
	aim(Vector3(3.3,1.2,-29.5))
	await screenshot("01-generator-off")
	Game.collect("fusivel")
	Game.world.fuse_installed=true
	main.level.flags["mission_read"]=true
	main.level.flags["objectives_viewed"]=true
	main.level.start_generator(Game.player)
	await screenshot("02-generator-running")
	await pose(Vector3(1.8,.1,-30.9))
	aim(Vector3(.6,1.6,-32))
	await screenshot("03-powered-airlock")
	main.to_menu()
	main.free()
	Sound.stop_all()
	get_tree().quit()
