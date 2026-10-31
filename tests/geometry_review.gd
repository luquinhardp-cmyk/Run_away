extends Node
var main: Node
var metrics: Array = []
func _ready(): run.call_deferred()
func shot(id: String,pos: Vector3,target: Vector3):
	Game.player.global_position = pos
	Game.player.rotation = Vector3.ZERO
	Game.player.camera.look_at(target)
	for i in 15: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/review/geometry/"+id+".png")
	metrics.append({"view":id,"draws":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
	print("GEOMETRY VIEW ",id)
func run():
	Game.testing = true
	Game.record_results = false
	Game.settings.quality = 1
	Game.settings.seed = 70421
	DirAccess.make_dir_recursive_absolute("res://docs/review/geometry")
	main = preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	main.start(false,false)
	Game.player.set_physics_process(false)
	Game.player.set_process_unhandled_input(false)
	Game.enemy.set_physics_process(false)
	main.level.events.enabled = false
	main.level.horror.enabled = false
	main.level.get_node("BloodMoonNight").flying.enabled = false
	main.hud.set_process(false)
	main.hud.root.hide()
	Game.collect("lanterna")
	Game.player.lamp_on = true
	Game.player.apply_settings()
	Game.power = true
	await shot("01_generator",Vector3(-6.2,.1,-30.8),Vector3(-8,1.1,-32))
	await shot("02_key",Vector3(-7.3,-.45,-14.1),Vector3(-7.5,.85,-14.8))
	await shot("03_fuse",Vector3(7,.1,-7.9),Vector3(7.7,.76,-9))
	await shot("04_panel",Vector3(-5.2,.1,-32),Vector3(-5.3,1.4,-33.7))
	await shot("05_door",Vector3(.2,.1,-9.1),Vector3(2,1.25,-8))
	await shot("06_physical_props",Vector3(5.5,.1,-5),Vector3(6.3,.6,-6.7))
	await shot("07_window",Vector3(-8.2,.1,.9),Vector3(-13,2.3,0))
	await shot("08_corridor",Vector3(0,.1,-3),Vector3(-.3,2.0,-13))
	await shot("09_storage",Vector3(-5,.1,-15.6),Vector3(-8.6,1,-17))
	await shot("10_workshop",Vector3(5,.1,-8),Vector3(8.7,1.1,-6.8))
	await shot("11_security",Vector3(6,.1,-23.5),Vector3(8,1,-25))
	await shot("12_basement",Vector3(-17,-1.65,-30.7),Vector3(-19,-1.5,-33.3))
	await shot("13_exterior",Vector3(0,.1,10),Vector3(4,3,20))
	var forest: Node3D = main.level.get_node("BloodMoonNight").forest
	for point in forest.near_positions:
		if point.x>13 and point.x<20 and point.z>5 and point.z<20:
			await shot("14_tree_roots",Vector3(point.x-2.5,.1,point.z+1.5),point+Vector3.UP*1.2)
			break
	# Separate inspection table: original asset scale, controlled neutral light.
	var stage := Node3D.new()
	main.level.add_child(stage)
	var table := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(4,4)
	table.mesh = plane
	table.position = Vector3(60,0.75,0)
	table.material_override = HorrorArt.surface("aged_concrete")
	stage.add_child(table)
	var inspection_light := OmniLight3D.new()
	inspection_light.position = Vector3(60,1.8,0.8)
	inspection_light.light_energy = 1.6
	inspection_light.omni_range = 4
	stage.add_child(inspection_light)
	Game.player.camera.fov = 40
	for entry in [["key",Vector3(0.22,0.014,0.10)],["fuse",Vector3(0.18,0.07,0.07)],["flashlight",Vector3(0.34,0.12,0.12)],["wrench",Vector3(0.08,0.06,0.42)]]:
		var model := ModelLibrary.fit(entry[0],entry[1],stage,Vector3(60,0.75+entry[1].y*0.5,0))
		await shot("detail_"+entry[0],Vector3(60,-0.45,0.55),Vector3(60,0.78,0))
		model.free()
	Game.write_json("res://docs/review/geometry/metrics.json",{"views":metrics,"platform":"Desktop Compatibility Intel UHD; not Android FPS"})
	main.to_menu()
	main.free()
	Sound.stop_all()
	await get_tree().create_timer(.3).timeout
	get_tree().quit()
