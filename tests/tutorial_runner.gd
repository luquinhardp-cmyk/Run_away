extends Node
var failed := 0
var passed := 0
var main: Node
var impact_count := 0
func frames(count := 4) -> void:
	for i in count: await get_tree().physics_frame
func aim(point: Vector3) -> void:
	var player: CharacterBody3D = Game.player
	var offset: Vector3 = point-player.camera.global_position
	var yaw := atan2(-offset.x,-offset.z)
	var pitch := asin(offset.normalized().y)
	player.look(Vector2(-angle_difference(player.rotation.y,yaw)/Game.settings.sensitivity,-(pitch-player.pitch)/Game.settings.sensitivity))
func pose(at: Vector3) -> void:
	Game.player.position=at
	Game.player.velocity=Vector3.ZERO
	main.hud.move=Vector2.ZERO
	Game.player.touch_move=Vector2.ZERO
	await frames()
func use_item(id: String) -> void:
	var target: Node3D = main.level.items[id]
	aim(target.global_position)
	await frames()
	Game.player._detect_interaction()
	check(Game.player.focus==target,"real interaction ray reaches "+id)
	Game.player.interact()
	await frames()
func travel(target: Vector3, running := false, count := 400) -> void:
	Game.player.touch_run=running
	for i in count:
		if not Game.in_tutorial: return
		var offset: Vector3 = target-Game.player.position
		offset.y=0
		if offset.length()<.2: break
		var local: Vector3 = Game.player.global_basis.inverse()*offset.normalized()
		main.hud.move=Vector2(local.x,local.z)
		Game.player.touch_move=main.hud.move
		await frames(1)
	if Game.in_tutorial:
		main.hud.move=Vector2.ZERO
		Game.player.touch_move=Vector2.ZERO
		Game.player.touch_run=false
		await frames()
func press(text: String) -> void:
	for button in main.column.get_children():
		if button is Button and button.text==text: button.pressed.emit(); return
	check(false,"button exists: "+text)
func check(ok: bool, text: String) -> void:
	if ok: passed+=1
	else: failed+=1; push_error(text)
	print("PASS " if ok else "FAIL ",text)
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	Game.testing = true
	Game.record_results = false
	NoiseBus.emitted.connect(func(event: Dictionary):
		if event.kind=="objeto_arremessado": impact_count+=1)
	Engine.time_scale=3
	main=preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	main.start_tutorial(false,false)
	for i in 5: await get_tree().physics_frame
	check(Game.in_tutorial and is_instance_valid(Game.player) and not is_instance_valid(Game.enemy),"preparation uses real player and no creature AI")
	check(main.level.step==0,"tutorial starts at first lesson")
	main.hud.toggle_inventory()
	check(Game.inventory_open and Game.paused,"real backpack pauses the tutorial")
	main.hud.close_inventory()
	check(not Game.inventory_open and not Game.paused,"closing backpack restores gameplay")
	var room: Node3D = main.level
	var room_reference: WeakRef = weakref(room)
	var original_checkpoint := Game.checkpoint.duplicate(true)
	room.request_exit()
	check(not Game.paused and not room.accepted,"exit stays locked before all lessons")
	Game.save_checkpoint()
	check(Game.checkpoint==original_checkpoint,"training never replaces the gameplay checkpoint")
	await frames(35)
	check(room.step==0,"waiting alone never completes movement")
	await travel(Vector3(0,.1,0))
	aim(room.move_target)
	await frames(12)
	check(room.step==1,"physical walking plus looking completes movement")
	await pose(Vector3(-3,.1,-1.5))
	await use_item("tutorial_key")
	await pose(Vector3(-3.5,.1,-5))
	await use_item("tutorial_cabinet")
	main.hud.toggle_inventory()
	check(room.step==2,"actual key, cabinet and inventory advance interaction")
	main.hud.close_inventory()
	await frames(30)
	await pose(Vector3(-3.5,.1,-7))
	await use_item("lanterna")
	await pose(Vector3(3,.1,-10.3))
	aim(room.light_target)
	await frames(12)
	await use_item("tutorial_mark")
	check(room.step==3,"real flashlight illuminates the marker and reveals collectible")
	await pose(Vector3(0,.1,-13.5))
	await travel(Vector3(0,.1,-16.7),false,55)
	check(Game.player.position.z > -14.8,"low passage collision blocks standing player")
	Game.player.toggle_crouch()
	await travel(Vector3(0,.1,-16.7))
	check(room.step==4,"actual crouched movement clears the low passage")
	Game.player.toggle_crouch()
	await travel(Vector3(0,.1,-20.5),true)
	check(room.step==5,"real running distance advances sprint lesson")
	await pose(Vector3(-2.2,.1,-22))
	await use_item("tutorial_hide")
	check(Game.player.hidden,"existing locker is functional")
	await frames(60)
	Game.player.interact()
	await frames()
	check(room.step==6 and not Game.player.hidden,"hide, listen and exit complete the hiding lesson")
	await pose(Vector3(2.4,.1,-22.5))
	await use_item("simulation")
	await frames(80)
	check(room.flags.get("mic_done",false) and not Mic.active and room.step==6,"explicit simulation permits microphone-free play but still requires a real impact")
	await pose(Vector3(1.5,.1,-24))
	await use_item("tutorial_can")
	await pose(Vector3(1,.1,-25))
	aim(Vector3(3,0,-26))
	var thrown: Node3D = Game.player.throw_object()
	check(is_instance_valid(thrown),"tutorial throws the existing rigid body")
	await frames(70)
	check(room.step==7,"actual thrown impact reaches NoiseBus and advances sound exercise")
	var resting_impacts := impact_count
	await frames(25)
	check(impact_count==resting_impacts,"resting thrown object does not keep emitting impact noises")
	await pose(Vector3(0,.1,-29))
	await pose(Vector3(3.5,.1,-27.6))
	await use_item("tutorial_generator")
	check(not Game.power and room.step==7,"generator refuses activation before fuse installation")
	await pose(Vector3(0,.1,-29))
	await use_item("mission")
	main.hud.toggle_inventory()
	for button in main.hud.inventory_window.panel.find_children("*","Button",true,false):
		if button.text=="CONSULTAR OBJETIVOS": button.pressed.emit()
	main.hud.close_inventory()
	await pose(Vector3(-3,.1,-27.5))
	await use_item("fusivel")
	await pose(Vector3(-3.4,.1,-30))
	await use_item("tutorial_fuse_panel")
	check(room.step==7 and not Game.power,"installing fuse alone does not complete energy lesson")
	room.accept_exit()
	check(not room.accepted and not room.items.tutorial_exit.open,"door cannot open without generator power")
	await travel(Vector3(-1.5,.1,-30))
	await travel(Vector3(-1.5,.1,-28))
	await travel(Vector3(3.5,.1,-27.6))
	check(Game.player.position.distance_to(Vector3(3.5,0,-27.6))<.5,"player can physically walk from fuse panel to generator")
	await use_item("tutorial_generator")
	check(room.step==8 and room.power_ready(),"real generator interaction restores energy and completes lesson")
	check(room.items.tutorial_generator.motor.playing,"generator has a running spatial motor sound")
	check(room.items.tutorial_generator.mesh.get_child_count()>0,"generator uses detailed industrial model")
	check(room.progress_data().generator_powered,"generator state is included in resume snapshot")
	check(room.exit_lens.material_override.albedo_color.g > room.exit_lens.material_override.albedo_color.r,"powered exit has a green indicator")
	await frames(15)
	check(room.exit_latch.position.x>1,"power retracts the physical latch decoration")
	var progress: Dictionary = room.progress_data()
	check(progress.step==8 and progress.inventory.has("tutorial_key"),"tutorial resume snapshot contains training progress")
	await travel(Vector3(1.6,.1,-29))
	await travel(Vector3(1.6,.1,-31))
	await travel(Vector3(0,.1,-31))
	check(Game.player.position.distance_to(Vector3(0,0,-31))<.5,"player can walk around mission board to powered door")
	await use_item("tutorial_exit")
	check(main.screen=="tutorial_confirm" and Game.paused,"exit requires an explicit confirmation")
	press("PERMANECER NA SALA")
	check(not room.accepted and not Game.paused,"cancel returns to preparation")
	await use_item("tutorial_exit")
	press("ENTRAR")
	await frames(45)
	check(room.accepted and room.items.tutorial_exit.mechanism.progress>.9,"confirmed door opens with existing hinge physics")
	await travel(Vector3(0,.1,-33.8))
	for i in 90:
		if not Game.in_tutorial: break
		await frames(1)
	check(not Game.in_tutorial and is_instance_valid(Game.enemy),"crossing closes the airlock, unloads training and activates the real creature")
	check(room_reference.get_ref()==null,"transition frees the preparation scene rather than leaving its collisions and audio behind")
	check(Game.inventory.is_empty() and not Game.power and not Game.world.unlocks.has("tutorial_cabinet"),"training items and solved training puzzle do not leak into gameplay")
	check(Game.settings.get("tutorial_completed",false),"tutorial completion preference is recorded")
	main.start(false,false)
	await frames(5)
	check(not Game.in_tutorial and is_instance_valid(Game.enemy),"restart and skip stay in the main phase without tutorial access")
	Engine.time_scale=1
	main.to_menu()
	main.free()
	Sound.stop_all()
	for i in 8: await get_tree().process_frame
	await get_tree().create_timer(.3).timeout
	print("TUTORIAL RESULT ",passed," passed; ",failed," failed")
	get_tree().quit(1 if failed else 0)
