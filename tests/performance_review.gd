extends Node
var main: Node
var results: Array = []
var synthetic := PackedVector2Array()
var label := "before"
var quality := 1
func report(data: Dictionary) -> void:
	if OS.has_feature("web"):
		print("WEB_AUDIT_JSON ", JSON.stringify(data))
	else:
		Game.write_json("res://docs/review/performance/"+label+"_q"+str(quality)+".json",data)
func _ready():
	process_mode=Node.PROCESS_MODE_ALWAYS
	run.call_deferred()
func _process(_delta: float):
	# A benchmark must not stop when its native window loses focus. Production still pauses.
	if Game.playing and Game.paused:
		Game.paused=false
		get_tree().paused=false
func argument(key: String, fallback: String) -> String:
	var args := OS.get_cmdline_user_args()
	var i := args.find(key)
	return args[i+1] if i>=0 and i+1<args.size() else fallback
func camera_at(pos: Vector3,target: Vector3):
	Input.action_release("forward")
	Game.player.set_physics_process(false)
	Game.enemy.set_physics_process(false)
	Game.player.global_position = pos
	Game.player.rotation = Vector3.ZERO
	Game.player.camera.look_at(target)
func sample(id: String,seconds: float, moving := false, simulated_mic := false) -> Dictionary:
	var times: Array[float] = []
	var cpu: Array[float] = []
	var gpu: Array[float] = []
	var ai: Array[float] = []
	var physics: Array[float] = []
	var night = main.level.get_node("BloodMoonNight")
	var roof_start: int = night.get("roof_rays") if night.get("roof_rays")!=null else 0
	var vision_start: int = Game.enemy.perception.ray_count
	var started := Time.get_ticks_usec()
	var last := started
	var mic_cost := 0.0
	while (Time.get_ticks_usec()-started)/1000000.0<seconds:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		times.append((now-last)/1000.0)
		last = now
		cpu.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
		physics.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000)
		ai.append(float(Game.enemy.ai_usec))
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()))
		if simulated_mic:
			var mark := Time.get_ticks_usec()
			Mic.rms_db(synthetic)
			mic_cost += Time.get_ticks_usec()-mark
		if id=="steady_exploration" and times.size()%180==0:
			var t := times.size()/180%3
			camera_at([Vector3(0,.1,12),Vector3(-6.2,.1,-30.8),Vector3(0,.1,-3)][t],[Vector3(0,5,25),Vector3(-8,1.1,-32),Vector3(0,1.6,-15)][t])
	var elapsed := (Time.get_ticks_usec()-started)/1000000.0
	times.sort()
	var total := 0.0
	for value in times: total+=value
	var cpu_total := 0.0
	for value in cpu: cpu_total+=value
	var gpu_total := 0.0
	for value in gpu: gpu_total+=value
	var physics_total := 0.0
	for value in physics: physics_total+=value
	var ai_total := 0.0
	for value in ai: ai_total+=value
	var snapshot := {"scenario":id,"seconds":elapsed,"frames":times.size(),"fps":1000/(total/maxi(1,times.size())),"mean_frame_ms":total/maxi(1,times.size()),"p95_frame_ms":times[mini(times.size()-1,int(times.size()*.95))],"max_frame_ms":times[-1],"cpu_process_ms":cpu_total/maxi(1,cpu.size()),"physics_ms":physics_total/maxi(1,physics.size()),"ai_last_mean_usec":ai_total/maxi(1,ai.size()),"gpu_ms":gpu_total/maxi(1,gpu.size()),"gpu_timing_available":gpu_total>0,"mic_synthetic_mean_usec":mic_cost/maxi(1,times.size()),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"memory_static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"texture_memory_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"resources":Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),"vision_rays_per_s":(Game.enemy.perception.ray_count-vision_start)/elapsed,"roof_rays_per_s":(int(night.get("roof_rays"))-roof_start)/elapsed if night.get("roof_rays")!=null else -1,"mic_hardware":false,"moving":moving,"scale_requested":get_viewport().scaling_3d_scale,"msaa":get_viewport().msaa_3d}
	results.append(snapshot)
	report({"label":label,"quality":quality,"complete":false,"results":results})
	print("BENCH ",id," ",snapshot.fps," fps p95=",snapshot.p95_frame_ms," roof/s=",snapshot.roof_rays_per_s)
	return snapshot
func run():
	Game.testing = true
	Game.record_results = false
	label = argument("--label","before")
	quality = int(argument("--quality","1"))
	Game.settings.quality = quality
	Game.settings.seed = 70421
	Game.settings["adaptive_resolution"] = false
	Game.settings["render_scale"] = 0.0
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true)
	synthetic.resize(2048)
	for i in synthetic.size(): synthetic[i]=Vector2.ONE*sin(i*.15)*.03
	var started := Time.get_ticks_usec()
	main = preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	main.start(false,false)
	var load_ms := (Time.get_ticks_usec()-started)/1000.0
	if OS.has_feature("web"): print("WEB_STARTUP_JSON ", JSON.stringify(main.level.startup_ms))
	Game.player.set_process_unhandled_input(false)
	Game.enemy.set_physics_process(false)
	main.level.events.enabled = false
	main.level.horror.enabled = false
	main.hud.set_process(false)
	main.hud.root.hide()
	Game.collect("lanterna")
	Game.player.lamp_on = true
	Game.player.apply_settings()
	Game.power = true
	Engine.max_fps = 0
	for entry in [["room",Vector3(-6.2,.1,-30.8),Vector3(-8,1.1,-32)],["corridor",Vector3(0,.1,-3),Vector3(0,1.6,-14)],["forest",Vector3(0,.1,12),Vector3(4,3,20)],["moon",Vector3(0,.1,12),Vector3(15,70,82)]]:
		camera_at(entry[1],entry[2])
		await get_tree().create_timer(.6).timeout
		if entry[0]=="corridor": Game.player.set_physics_process(true);Input.action_press("forward")
		await sample(entry[0],1.5,entry[0]=="corridor")
	Input.action_release("forward")
	Game.player.lamp_on = false
	Game.player.apply_settings()
	await sample("flashlight_off", 1.5)
	Game.player.lamp_on = true
	Game.player.apply_settings()
	await sample("flashlight_on", 1.5)
	camera_at(Vector3(0,.1,12),Vector3(15,70,82))
	await get_tree().create_timer(.5).timeout
	var flight = main.level.get_node("BloodMoonNight").flying
	flight.cooldown=0;flight.exploration=100
	main.level.horror.since_scare=100;main.level.horror.since_chase=100;main.level.horror.active_until=0;main.level.horror.tension=0
	Game.enemy.state=Game.enemy.State.PATROL
	var flying_started: bool = flight.begin(flight.patterns[0])
	await sample("flying_shadow",1.5)
	flight.finish_event()
	flight.enabled=false
	camera_at(Vector3(0,.1,-10),Vector3(0,1.6,-24))
	Game.enemy.global_position=Vector3(0,.1,-24)
	Game.enemy.age=20
	Game.enemy.memory.saw(Game.player.global_position,20)
	Game.enemy.transition(Game.enemy.State.CHASE)
	Game.enemy.set_physics_process(true)
	await sample("chase",1.5)
	Game.enemy.set_physics_process(false)
	Game.enemy.state=Game.enemy.State.PATROL
	camera_at(Vector3(5.5,.1,-5.5),Vector3(7,1,-7.2))
	var props: Array[PhysicalProp3D] = []
	for i in 4:
		var prop := PhysicalProp3D.new()
		prop.profile=load("res://resources/physics/objects/can.tres")
		prop.persistent=false
		prop.position=Vector3(6.7+i*.22,2.2,-7.2)
		main.level.add_child(prop)
		props.append(prop)
	await sample("falling_props",1.5)
	for prop in props: prop.free()
	camera_at(Vector3(0,.1,-3),Vector3(0,1.6,-14))
	Game.player.set_physics_process(true)
	Input.action_press("forward")
	await sample("microphone_simulated",1.5,true,true)
	Input.action_release("forward")
	Game.player.set_physics_process(false)
	await sample("steady_exploration",float(argument("--steady","60")))
	camera_at(Vector3(0,.1,-7),Vector3(0,1.8,-8))
	Game.enemy.global_position=Vector3(0,.1,-8)
	Game.enemy.rotation.y=PI
	Game.enemy.transition(Game.enemy.State.ATTACK)
	# Teleports must reach the physics server before the contact ray is tested.
	for i in 3: await get_tree().physics_frame
	var captured: bool = Game.enemy.capture_sequence.begin()
	await sample("capture",.8)
	report({"label":label,"quality":quality,"complete":true,"renderer":RenderingServer.get_current_rendering_method(),"load_ms":load_ms,"flying_started":flying_started,"capture_started":captured,"android_hardware":false,"mic_hardware":false,"uncapped":true,"results":results})
	main.to_menu()
	main.free()
	Sound.stop_all()
	await get_tree().create_timer(.3).timeout
	get_tree().quit()
