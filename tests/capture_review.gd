extends Node
func _ready():
	run.call_deferred()
func run():
	process_mode=Node.PROCESS_MODE_ALWAYS
	Game.testing=true
	Game.record_results=false
	Game.settings.camera_motion=.5
	Game.settings.visual_scares=true
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
	Game.player.global_position=Vector3(0,.1,-7)
	Game.enemy.global_position=Vector3(0,.1,-8)
	Game.enemy.rotation.y=PI
	Game.player.camera.look_at(Vector3(0,1.8,-8))
	for i in 3: await get_tree().physics_frame
	var capture=Game.enemy.capture_sequence
	if not capture.begin(): push_error("capture failed");get_tree().quit(1);return
	capture.set_process(false)
	Game.enemy.visual.animator.seek(.4,true)
	Game.enemy.visual.animator.pause()
	capture._process(capture.selected.duration*.4)
	for i in 4: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var args := OS.get_cmdline_user_args()
	var output := "res://docs/review/performance/capture_closeup.png"
	var option := args.find("--output")
	if option >= 0 and option+1 < args.size(): output = args[option+1]
	get_viewport().get_texture().get_image().save_png(output)
	capture._release()
	main.to_menu()
	main.free()
	Sound.stop_all()
	get_tree().quit()
