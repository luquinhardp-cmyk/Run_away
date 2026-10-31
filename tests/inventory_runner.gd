extends "res://tests/tutorial_runner.gd"
func run() -> void:
	Game.testing=true
	Game.record_results=false
	main=preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	main.start_tutorial(false,false)
	await frames()
	for id in ["lanterna","tutorial_key","fusivel"]: Game.collect(id)
	Game.world.throwables=3
	main.hud.toggle_inventory()
	await frames()
	var bag: CanvasLayer = main.hud.inventory_window
	check(Game.paused and Game.inventory_open and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"backpack pauses the world and releases pointer lock")
	check(InventoryCatalog.owned().size()==4,"slots reflect actual owned IDs and stack")
	var all_images := true
	for id in InventoryCatalog.owned(): all_images=all_images and InventoryCatalog.image(id)!=null
	check(all_images,"all owned items have model-rendered thumbnails")
	check(InventoryCatalog.data("throwables").quantity==3,"stack quantity reflects real supplies")
	bag.select("tutorial_key")
	check(bag.drop_button.disabled and bag.use_button.disabled,"mission item discard and incompatible use are disabled")
	bag.drop_selected()
	check(Game.inventory.has("tutorial_key"),"discard callback cannot delete essential items")
	bag.select("lanterna")
	bag.examine_selected()
	check(bag.inspecting and is_instance_valid(bag.preview_container),"inspect creates one lightweight 3D viewport")
	var before_rotation: Vector3 = bag.preview_model.rotation
	var event := InputEventScreenDrag.new()
	event.relative=Vector2(40,20)
	bag._inspect_input(event)
	check(bag.preview_model.rotation!=before_rotation,"touch drag rotates the inspected model")
	var before_zoom: float = bag.preview_camera.position.length()
	bag.zoom_inspection(-.2)
	check(bag.preview_camera.position.length()<before_zoom,"inspection zoom moves the actual camera")
	bag.stop_inspection()
	check(not bag.inspecting and not is_instance_valid(bag.preview_container),"back removes the inspection viewport")
	var rebuilds: int = bag.rebuild_count
	for i in 12: await get_tree().process_frame
	check(bag.rebuild_count==rebuilds,"inventory does not rebuild every frame")
	bag.select("lanterna")
	bag.equip_selected()
	await frames()
	check(Game.player.lamp_on and not Game.paused and not Game.inventory_open,"equip operates the real flashlight and restores controls")
	main.hud.toggle_inventory()
	bag=main.hud.inventory_window
	bag.select("throwables")
	var before_count := get_tree().get_nodes_in_group("throwables").size()
	bag.drop_selected()
	await frames()
	check(int(Game.world.throwables)==2 and get_tree().get_nodes_in_group("throwables").size()==before_count+1,"discard decrements supply and creates a real physical object")
	await pose(Vector3(-3.5,.1,-5))
	aim(main.level.items.tutorial_cabinet.position)
	await frames()
	Game.player._detect_interaction()
	main.hud.toggle_inventory()
	bag=main.hud.inventory_window
	bag.select("tutorial_key")
	check(not bag.use_button.disabled,"key use becomes available near the matching lock")
	bag.use_selected()
	await frames()
	check(main.level.items.tutorial_cabinet.open,"inventory use invokes the real lock interaction")
	main.hud.toggle_inventory()
	bag=main.hud.inventory_window
	Game.settings.quality=0
	bag.select("fusivel")
	bag.examine_selected()
	check(bag.inspecting and not is_instance_valid(bag.preview_container) and bag.image.custom_minimum_size.y>=260,"low profile inspects enlarged 2D image without a viewport")
	var escape := InputEventAction.new()
	escape.action="pause"
	escape.pressed=true
	main.hud._input(escape)
	check(not Game.inventory_open and not Game.paused,"Escape closes the backpack without opening pause menu")
	var before_noise: int = NoiseBus.emitted_count
	Sound.ui_click()
	await frames()
	check(NoiseBus.emitted_count==before_noise,"interface sound does not create a gameplay noise")
	main.hud.actions[1].pressed.emit()
	await frames()
	check(Game.player.crouched and main.hud.actions[1].button_pressed,"crouch button reflects the real stance")
	main.hud.actions[1].pressed.emit()
	var touch := InputEventScreenTouch.new()
	touch.index=7; touch.pressed=true; touch.position=Vector2(100,600)
	main.hud._input(touch)
	var drag := InputEventScreenDrag.new()
	drag.index=7; drag.position=Vector2(150,600); drag.relative=Vector2(50,0)
	main.hud._input(drag)
	check(main.hud.stick_id==7 and main.hud.move.length()>0,"touch drag drives the existing joystick")
	touch=InputEventScreenTouch.new()
	touch.index=8; touch.pressed=true; touch.position=Vector2(900,250)
	main.hud._input(touch)
	var yaw: float = Game.player.rotation.y
	drag=InputEventScreenDrag.new()
	drag.index=8; drag.position=Vector2(920,260); drag.relative=Vector2(20,10)
	main.hud._input(drag)
	check(main.hud.look_id==8 and Game.player.rotation.y!=yaw,"second touch independently controls the real camera")
	touch=InputEventScreenTouch.new()
	touch.index=7; touch.pressed=false
	main.hud._input(touch)
	check(main.hud.move==Vector2.ZERO and main.hud.look_id==8,"releasing joystick preserves the independent look touch")
	Game.set_paused(true)
	main.hud._process(.01)
	check(main.hud.stick_id==-1 and main.hud.look_id==-1,"pause clears both touches")
	Game.set_paused(false)
	main.to_menu()
	main.free()
	Sound.stop_all()
	await get_tree().create_timer(.3).timeout
	print("INVENTORY RESULT ",passed," passed; ",failed," failed")
	get_tree().quit(1 if failed else 0)
