extends Node
func _ready(): run.call_deferred()
func run():
	Game.testing=true
	Game.record_results=false
	Game.settings.quality=1
	var main=preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	main.start(false,false)
	Game.player.set_physics_process(false)
	Game.player.set_process_unhandled_input(false)
	Game.enemy.set_physics_process(false)
	main.level.events.enabled=false
	main.level.horror.enabled=false
	main.hud.set_process(false)
	main.hud.root.hide()
	Game.collect("lanterna")
	Game.player.lamp_on=true
	Game.player.apply_settings()
	Game.player.global_position=Vector3(-6.2,.1,-30.8)
	Game.player.camera.look_at(Vector3(-8,1.1,-32))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps=0
	var results: Array=[]
	for scale in [.85,1.0,1.7]:
		get_viewport().scaling_3d_scale=scale
		await get_tree().create_timer(.7).timeout
		var start:=Time.get_ticks_usec()
		var frames:=0
		while Time.get_ticks_usec()-start<2000000:
			await get_tree().process_frame
			frames+=1
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://docs/review/performance/sharpness_"+str(scale)+".png")
		results.append({"scale":scale,"fps":frames*1000000.0/(Time.get_ticks_usec()-start),"viewport":str(get_viewport().get_visible_rect().size),"android":false})
	Game.write_json("res://docs/review/performance/sharpness.json",{"method":"same camera, current mipmaps and 2x MSAA; requested 0.85 to 1.7 doubles linear sampling, quadruples pixels","results":results})
	main.to_menu()
	main.free()
	Sound.stop_all()
	get_tree().quit()
