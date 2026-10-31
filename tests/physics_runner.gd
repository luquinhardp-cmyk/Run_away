extends Node
var passed := 0
var failed := 0
var main: Node
var events: Array = []
func check(ok: bool, title: String) -> void:
	if ok: passed += 1
	else: failed += 1; push_error("FAIL " + title)
	print("PASS " if ok else "FAIL ",title)
func frames(count: int) -> void:
	for i in count: await get_tree().physics_frame
func prop(type: String, pos: Vector3) -> PhysicalProp3D:
	var object := PhysicalProp3D.new()
	object.profile = load("res://resources/physics/objects/" + type + ".tres")
	object.position = pos
	object.persistent = false
	main.level.add_child(object)
	return object
func _ready() -> void: run.call_deferred()
func run() -> void:
	var old_settings := Game.settings.duplicate(true)
	var backup := Game.checkpoint.duplicate(true)
	Game.testing = true
	Game.record_results = false
	Game.settings.seed = 70421
	main = preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	main.start(false,false)
	main.level.events.enabled = false
	main.level.horror.enabled = false
	Game.enemy.set_physics_process(false)
	Game.player.set_physics_process(false)
	Game.player.set_process_unhandled_input(false)
	NoiseBus.emitted.connect(func(event: Dictionary): events.append(event))
	await frames(15)
	var manager: Node = get_tree().get_first_node_in_group("physics_managers")
	check(manager.props.size() == 12,"twelve authored dynamic props; structures stay static")
	var coordinates := [0.0,0.13,-17.2]
	check(Cloud.decode_fields({"p":Cloud.encode(coordinates)}).p == coordinates,"cloud codec preserves floating-point transform arrays")
	check(main.level.find_interaction("generator") is StaticBody3D,"generator stays anchored")
	check(main.level.find_interaction("fusivel") is StaticBody3D,"mission pickup keeps original gameplay")
	check(Game.player.collision_mask & 16 and Game.enemy.collision_mask & 16,"both characters collide with props")
	for id in PhysicsSurfaces.VALUES:
		var physical := PhysicsSurfaces.material(id)
		check(physical.friction > 0 and physical.bounce >= 0,"physical surface " + id)
	var floor_body: StaticBody3D = main.level.box(Vector3(30,-0.15,0),Vector3(16,0.3,16),HorrorArt.surface("cracked_floor"),true,main.level)
	var wall: StaticBody3D = main.level.box(Vector3(35,2,0),Vector3(0.2,4,10),HorrorArt.surface("aged_concrete"),true,main.level)
	var can := prop("can",Vector3(30,2,0))
	var bottle := prop("bottle",Vector3(31,2.8,0))
	var ball := prop("rubber_ball",Vector3(32,1,0))
	await frames(40)
	check(can.position.y < 1.5,"unsupported body falls under native gravity")
	await frames(160)
	check(can.position.y > 0.05 and can.position.y < 0.3,"can rests on floor without tunneling")
	check(can.sleeping,"stationary body sleeps")
	check(can.impact_audio.count > 0,"actual floor contact produces impact")
	check(bottle.broken and bottle.collision_layer == 0,"glass breaks at tested fall speed and clears collision")
	check(get_tree().get_nodes_in_group("physics_fragments").size() <= 12,"fragment cleanup budget bounded")
	check(ball.impact_audio.count >= 1 and ball.position.y > 0,"rubber uses bouncy physical material")
	var at_floor := false
	for event in events:
		if event.kind == "impacto_fisico" and event.position.distance_to(Vector3(30,0,0)) < 0.4: at_floor = true
	check(at_floor,"noise originates at true contact, not player")
	var before_count := can.impact_audio.count
	can.impact_audio.advance(2)
	can.impact_audio.report(can.position,floor_body,0.2,can.mass)
	check(can.impact_audio.count == before_count,"tiny contacts stay silent")
	can.impact_audio.report(can.position,floor_body,3,can.mass)
	can.impact_audio.report(can.position,floor_body,3,can.mass)
	check(can.impact_audio.count == before_count + 1,"per-body cooldown prevents repeated contact spam")
	var pair := prop("can",Vector3(30,0.3,2))
	can.impact_audio.last_impact = -1000
	pair.impact_audio.last_impact = -1000
	var pair_reports := int(can.impact_audio.report(can.position,pair,3,can.mass)) + int(pair.impact_audio.report(pair.position,can,3,pair.mass))
	check(pair_reports == 1,"dynamic collision pair reports exactly once")
	var wood := prop("small_crate",Vector3(27,0.17,-3))
	var metal := prop("small_crate",Vector3(27,0.17,-4))
	metal.physics_material_override = PhysicsSurfaces.material("glass")
	wood.linear_damp = 0
	metal.linear_damp = 0
	wood.linear_velocity = Vector3(2,0,0)
	metal.linear_velocity = Vector3(2,0,0)
	await frames(100)
	check(metal.position.x > wood.position.x + 0.03,"lower-friction surface slides farther in identical setup")
	can.sleeping = false
	can.apply_central_impulse(Vector3(0.2,0,0))
	can.apply_torque_impulse(Vector3(0,0,0.05))
	var initial_x := can.position.x
	await frames(30)
	check(absf(can.position.x-initial_x) > 0.05,"can responds to push and rolling impulse")
	var held := prop("small_crate",Vector3(30,0.2,4))
	Game.player.global_position = Vector3(30,0.1,5.5)
	Game.player.rotation = Vector3.ZERO
	Game.player.camera.rotation = Vector3.ZERO
	await frames(3)
	check(Game.player.manipulator.begin(held),"nearby light object can be held")
	await frames(50)
	check(held.position.y > 0.5,"force-limited spring lifts object without teleport")
	var launched: PhysicalProp3D = Game.player.manipulator.release(true)
	await frames(3)
	check(launched == held and held.linear_velocity.length() > 1 and held.linear_velocity.length() < 12,"throw applies bounded mass-aware impulse")
	var heavy := prop("crate",Vector3(30,0.35,4))
	check(not Game.player.manipulator.begin(heavy),"mass limit rejects heavy furniture")
	check(Game.player.manipulator.begin_drag(heavy),"medium furniture permits horizontal drag")
	await frames(30)
	check(heavy.position.y < 0.6,"drag mode never lifts medium furniture")
	Game.player.manipulator.release()
	var behind := prop("can",Vector3(35.6,1.6,0))
	Game.player.global_position = Vector3(34.5,0.1,0)
	check(not Game.player.manipulator.begin(behind),"wall blocks acquisition")
	behind.linear_velocity = Vector3(-12,0,0)
	await frames(35)
	check(behind.position.x > 35.1,"CCD prevents fast object crossing wall")
	var wall_held := prop("can",Vector3(34.2,1.2,2))
	Game.player.global_position = Vector3(33.7,0.1,2)
	Game.player.rotation.y = -PI/2
	await frames(2)
	check(Game.player.manipulator.begin(wall_held),"spring acquires body on near side of wall")
	await frames(70)
	check(wall_held.position.x < 34.85,"held body remains on near side of wall")
	Game.player.manipulator.release()
	var drawer: Node = main.level.find_interaction("drawer")
	Game.player.global_position = Vector3(30,0.1,5)
	drawer.interact(Game.player)
	await frames(55)
	check(drawer.open and absf(drawer.mechanism.leaf.position.z-0.36) < 0.02,"drawer uses bounded linear collision body")
	manager.snapshot()
	check(Game.world.physics.drawer.open,"drawer state included in snapshot")
	var chain: Node = main.level.get_node("HangingMaintenanceChain")
	chain.kick(1)
	await frames(15)
	check(absf(chain.angle) > 0.02 and absf(chain.angle) <= 0.45,"suspended element swings within limits")
	var start_angle: float = absf(chain.angle)+absf(chain.angular_speed)
	await frames(180)
	check(absf(chain.angle)+absf(chain.angular_speed) < start_angle,"pendulum motion decays")
	Game.enemy.global_position = Vector3(32,0.1,1)
	Game.enemy.age = 20
	Game.enemy.hearing_cooldown = 0
	Game.enemy.transition(Game.enemy.State.PATROL)
	can.impact_audio.advance(2)
	can.impact_audio.report(Vector3(30,0,0),floor_body,8,3)
	check(Game.enemy.state == Game.enemy.State.ALERT and Game.enemy.last_known.distance_to(Vector3(30,0,0)) < 0.5,"creature listens to physical impact at its actual source")
	var stress: Array = []
	for i in 12: stress.append(prop("can",Vector3(26+(i%4)*0.4,2+int(i/4)*0.4,2)))
	await frames(150)
	var stable := true
	for object in stress: stable = stable and object.position.y > -0.1 and object.linear_velocity.length() < 3
	check(stable,"twelve simultaneous falling objects settle above floor")
	var obstacle := prop("can",Vector3(0,0.15,-20))
	Game.enemy.global_position = Vector3(0,0.1,-18)
	Game.enemy.transition(Game.enemy.State.INVESTIGATE)
	Game.enemy.target = Vector3(0,0.1,-22)
	Game.enemy.last_known = Vector3(0,0.1,-22)
	Game.enemy.set_physics_process(true)
	await frames(130)
	Game.enemy.set_physics_process(false)
	check(Game.enemy.global_position.z < -20.0,"creature navigates through a light physical obstruction")
	check(obstacle.position.y > -0.1,"creature push leaves obstacle on physical floor")
	check(manager.spawn("optional_extra","can",Vector3.ZERO) != null,"manager admits body within fixed cap")
	for i in 8: manager.spawn("optional_extra"+str(i),"can",Vector3(13,1,-19))
	check(manager.props.size() <= 16,"world prop creation budget enforced")
	# Only the authored IDs are persisted in a real checkpoint; fixtures stay disposable.
	for object in manager.props:
		if object.item_id.begins_with("optional_extra"): object.persistent = false
	manager.snapshot()
	Game.world.physics.erase("optional_extra")
	for i in 8: Game.world.physics.erase("optional_extra"+str(i))
	var expected: Dictionary = main.level.find_interaction("can").snapshot()
	Game.checkpoint = {"version":2,"items":[],"power":false,"doors":{},"elapsed_ms":0,"world":Game.world.duplicate(true)}
	main.to_menu()
	main.start(true,false)
	Game.enemy.set_physics_process(false)
	await frames(3)
	check(main.level.find_interaction("can").position.distance_to(PhysicalProp3D.decode_snapshot(expected).position) < 0.06,"resume restores moved prop transform")
	check(main.level.find_interaction("drawer").open,"resume restores drawer state")
	print("PHYSICS RESULT ",passed," passed; ",failed," failed")
	main.to_menu()
	main.free()
	Sound.stop_all()
	Game.settings = old_settings
	Game.checkpoint = backup
	await get_tree().create_timer(0.3).timeout
	get_tree().quit(0 if failed == 0 else 1)
