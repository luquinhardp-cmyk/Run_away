extends "res://tests/tutorial_runner.gd"
func run() -> void:
	Game.testing=true
	Game.record_results=false
	var profile_before: String=Game.profile
	var checkpoint_before: Dictionary=Game.checkpoint.duplicate(true)
	Game.profile="tutorial_test_"+str(Time.get_ticks_usec())
	var path: String=Game.tutorial_path()
	main=preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	main.start_tutorial(false,false)
	main.level.step=6
	main.level.flags["mic_done"]=true
	Game.collect("tutorial_key")
	Game.collect("lanterna")
	Game.world.throwables=2
	Game.doors["tutorial_cabinet"]=true
	Game.world.unlocks["tutorial_cabinet"]=true
	Game.write_json(path,main.level.progress_data())
	main.to_menu()
	main.start_tutorial(true,false)
	await frames()
	check(main.level.step==6 and main.level.flags.get("mic_done",false),"JSON persistence restores the active lesson and completed actions")
	check(Game.inventory.has("tutorial_key") and Game.world.throwables==2,"resume restores training inventory and quantities")
	check(main.level.items.tutorial_cabinet.open,"resume restores the real unlocked training cabinet")
	check(Game.checkpoint==checkpoint_before,"tutorial persistence stays separate from the gameplay checkpoint")
	main.hud.toggle_inventory()
	main.hud.inventory_window.root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	for size in [Vector2(1280,720),Vector2(960,540),Vector2(720,1280)]:
		main.hud.inventory_window.root.size=size
		main.hud.inventory_window.layout()
		for i in 12: await get_tree().process_frame
		check(main.hud.inventory_window.panel.size.y<=size.y-40,"backpack remains within viewport height "+str(size))
	main.hud.close_inventory()
	main.level.step=7
	Game.collect("fusivel")
	Game.world.fuse_installed=true
	main.level.flags["mission_read"]=true
	main.level.flags["objectives_viewed"]=true
	Game.write_json(path,main.level.progress_data())
	main.to_menu()
	main.start_tutorial(true,false)
	check(not Game.power and main.level.step==7,"save before activation preserves unpowered puzzle")
	main.level.start_generator(Game.player)
	Game.write_json(path,main.level.progress_data())
	main.to_menu()
	main.start_tutorial(true,false)
	check(main.level.power_ready() and main.level.step==8,"save after activation restores power and completed objective")
	check(main.level.items.tutorial_generator.motor.playing and not main.level.items.tutorial_exit.open,"resume restores motor but requires deliberate entry confirmation")
	var legacy: Dictionary=main.level.progress_data()
	legacy.erase("generator_powered")
	legacy.version=1
	Game.write_json(path,legacy)
	main.to_menu()
	main.start_tutorial(true,false)
	check(main.level.step==7 and not Game.power,"old saves without a generator return to energy lesson without bypass")
	main.level.start_generator(Game.player)
	main.level.step=8
	main.level.accept_exit()
	main.level._airlock_entered(Game.player)
	check(main.level.progress_data().stage=="entered","crossing becomes irreversible before door closure finishes")
	Game.set_paused(true)
	var can_restart_training := false
	for child in main.column.get_children():
		if child is Button and child.text=="REINICIAR PREPARAÇÃO": can_restart_training=true
	check(not can_restart_training,"pause cannot restart preparation after crossing")
	Game.set_paused(false)
	Game.write_json(path,{"version":1,"stage":"entered","completed":true})
	main.to_menu()
	var resume_training := false
	for child in main.column.get_children():
		if child is Button and child.text=="RETOMAR PREPARAÇÃO": resume_training=true
	check(not resume_training,"entered boundary removes preparation resume from menu")
	main.start(false,false)
	check(not Game.in_tutorial and is_instance_valid(Game.enemy),"skip starts the normal creature and objectives")
	main.start_tutorial(false,false)
	check(main.level.step==0 and Game.inventory.is_empty(),"an explicit new game can replay tutorial from a clean state")
	main.to_menu()
	main.free()
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(path.get_base_dir())
	Game.profile=profile_before
	Game.checkpoint=checkpoint_before
	Sound.stop_all()
	await get_tree().create_timer(.3).timeout
	print("TUTORIAL PERSISTENCE RESULT ",passed," passed; ",failed," failed")
	get_tree().quit(1 if failed else 0)
