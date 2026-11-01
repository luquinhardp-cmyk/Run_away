extends Node
var passed := 0
var failed := 0
var intentional_pause := false
func _process(_delta: float) -> void:
	# Browser test automation may focus its HTML entry button. Production pause
	# behavior is exercised separately; do not deadlock this physics fixture.
	if Game.testing and Game.playing and Game.paused and not intentional_pause:
		Game.paused=false
		get_tree().paused=false
func check(ok: bool, title: String) -> void:
	if ok: passed+=1
	else: failed+=1; push_error(title)
	print("PASS " if ok else "FAIL ",title)
func frames(n: int) -> void:
	for i in n: await get_tree().physics_frame
func _ready() -> void: run.call_deferred()
func run() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	Game.testing=true
	Game.record_results=false
	var main=preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	main.start(false,false)
	Game.enemy.set_physics_process(false)
	Game.enemy.position=Vector3(0,.1,-38)
	var player=Game.player
	var recovery=player.fall_recovery
	await frames(4)
	for x in [-10.5,2.5,3.0,6.0,10.5]:
		for z in [.15,1.0,1.8,2.05]:
			check(not recovery.ground_at(Vector3(x,.03,z)).is_empty(),"entrance shoulder support x=%s z=%s"%[x,z])
	for mode in ["walk","run","crouch"]:
		player.global_position=Vector3(3,.1,1)
		player.rotation=Vector3.ZERO
		player.velocity=Vector3.ZERO
		if player.crouched:player.toggle_crouch()
		if mode=="crouch":player.toggle_crouch()
		Input.action_press("right")
		player.touch_run=mode=="run"
		await frames(60)
		check(player.global_position.x>3.5 and player.global_position.y>-.1 and player.is_on_floor(),"real player crosses repaired apron: "+mode)
		Input.action_release("right")
		Input.action_press("left")
		await frames(30)
		check(player.global_position.y>-.1,"reverse crossing: "+mode)
		Input.action_release("left")
	player.touch_move=Vector2.ZERO
	player.touch_run=false
	if player.crouched:player.toggle_crouch()
	for target in [Vector3(12,1,1),Vector3(6,1,-1)]:
		var from := Vector3(6,1,1)
		var hit=player.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,target,1))
		check(not hit.is_empty(),"entrance flank has physical boundary "+str(target))
	var prop=PhysicalProp3D.new()
	prop.profile=load("res://resources/physics/objects/can.tres")
	prop.persistent=false
	prop.position=Vector3(6,1.5,1)
	main.level.add_child(prop)
	await frames(100)
	check(prop.global_position.y>-.1 and prop.global_position.y<.5,"real rigid body lands on repaired ground")
	prop.free()
	player.global_position=Vector3(5,.05,1)
	player.velocity=Vector3.ZERO
	await frames(35)
	check(not recovery.safe_positions.is_empty(),"safe positions recorded only on supported clear floor")
	var inventory=Game.inventory.duplicate()
	player.global_position=Vector3(7,-12,1)
	player.velocity=Vector3(0,-45,0)
	recovery.tick(.02)
	check(recovery.recovery_count==1 and player.global_position.y>-.1,"void fall recovers to verified recent position")
	check(player.velocity==Vector3.ZERO and not player.touch_run,"recovery clears incompatible velocity and controls")
	check(Game.inventory==inventory,"recovery preserves inventory and objectives")
	var incident: Dictionary=recovery.incidents.back()
	check(incident.position[1]==-12 and incident.scene=="res://scenes/levels/facility.tscn" and not incident.probable_cause.is_empty(),"diagnostic captures position scene and probable cause")
	check(not recovery.valid_position(Vector3(6,-10,1)),"unsupported fallback rejected")
	check(not recovery.valid_position(Vector3(6,0,-.08)),"obstructed fence position rejected")
	check(not recovery.valid_position(Vector3(11.1,1.35,1)),"narrow fence top cannot become a safe recovery position")
	recovery.safe_positions.clear()
	recovery.cooldown=0
	player.global_position=Vector3(6,-12,1)
	recovery.tick(.02)
	check(recovery.recovery_count==2 and player.global_position.distance_to(recovery.fallback)<.2,"verified spawn fallback works with no safe history")
	player.global_position=Vector3(-19,-1.75,-32)
	player.velocity=Vector3.ZERO
	await frames(15)
	check(player.global_position.y>-2 and recovery.recovery_count==2,"legitimate basement descent is not cancelled")
	Input.action_press("right")
	await frames(260)
	Input.action_release("right")
	check(player.global_position.x>-10.5 and player.global_position.y>-.5,"real player walks basement ramp back to the power room")
	var diagnostic_path := "user://tests/fall_recovery_incident.json"
	recovery.log_path=diagnostic_path
	Game.testing=false
	recovery.recover()
	Game.testing=true
	var stored = JSON.parse_string(FileAccess.get_file_as_string(diagnostic_path))
	check(stored is Dictionary and stored.incidents.size()>0 and stored.incidents.back().has("probable_cause"),"incident is persisted to local JSON")
	DirAccess.remove_absolute(diagnostic_path)
	var updates := HorrorArt.material_updates
	for i in 20:HorrorArt.set_quality(HorrorArt.quality)
	check(HorrorArt.material_updates==updates,"unchanged quality does not rewrite every PBR material")
	var bark_ids: Array[int]=[]
	var forest=main.level.get_node("BloodMoonNight").forest
	for batch in forest.batches:
		if batch.name.ends_with("bark") and batch.material_override.get_instance_id() not in bark_ids:bark_ids.append(batch.material_override.get_instance_id())
	check(bark_ids.size()==1,"forest bark shares one material across chunks")
	check(not main.hud.mute_button.disabled,"microphone can be enabled from no-consent HUD state")
	Mic.disable()
	var heard: Array=[]
	var listener=func(event):heard.append(event)
	NoiseBus.emitted.connect(listener)
	NoiseBus.emit_noise(player,.4,"passos",10)
	check(heard.size()==1,"microphone off does not disable game sound bus")
	NoiseBus.emitted.disconnect(listener)
	recovery.safe_positions.clear()
	recovery.fallback=Vector3(100,-20,100)
	intentional_pause=true
	print("EXPECTED_DIAGNOSTIC fall_recovery_no_verified_floor")
	recovery.recover()
	check(recovery.blocked and Game.paused,"invalid or repeated recovery pauses instead of teleport looping")
	Game.set_paused(false)
	var frozen_position: Vector3=player.global_position
	await frames(5)
	check(player.global_position.is_equal_approx(frozen_position),"resuming an unrecoverable session cannot restart infinite falling")
	main.free()
	Sound.stop_all()
	await frames(8)
	print("STABILITY RESULT ",passed," passed; ",failed," failed")
	get_tree().quit(0 if failed==0 else 1)
