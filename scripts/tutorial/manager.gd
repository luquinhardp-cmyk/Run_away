extends "res://scripts/tutorial/room.gd"
signal changed
signal exit_requested
signal transition_requested
var step := 0
var flags: Dictionary = {}
var restore_data: Dictionary = {}
var demo_active := false
var demo_time := 0.0
var silence := 0.0
var hidden_seconds := 0.0
var idle_seconds := 0.0
var age := 0.0
var accepted := false
var departing := false
var departed := false
var player: CharacterBody3D
var hud: CanvasLayer
var sensor: Timer
func _ready() -> void:
	if restore_data.get("stage") == "tutorial":
		step = clampi(int(restore_data.get("step",0)),0,8)
		if restore_data.get("flags") is Dictionary: flags = restore_data.flags.duplicate(true)
		for id in restore_data.get("inventory",[]):
			if id in ["tutorial_key","lanterna","tutorial_mark","fusivel"]: Game.inventory.append(id)
		if restore_data.get("cabinet_open",false):
			Game.doors["tutorial_cabinet"] = true
			Game.world.unlocks["tutorial_cabinet"] = true
		Game.world.fuse_installed = bool(restore_data.get("fuse_installed",false))
		Game.world.throwables = clampi(int(restore_data.get("throwables",0)),0,8)
		if Game.world.throwables>0: Game.world.collected_props.append("tutorial_can")
	build_room()
	Game.updated.connect(check_objectives)
	Game.tutorial_save_requested.connect(save_progress)
	NoiseBus.emitted.connect(_noise)
	sensor = Timer.new()
	sensor.wait_time = .1
	sensor.timeout.connect(_observe)
	add_child(sensor)
	sensor.start()
func spawn_position() -> Vector3:
	return [Vector3(0,.1,3),Vector3(-1,.1,-3),Vector3(2,.1,-9),Vector3(0,.1,-13),Vector3(0,.1,-17),Vector3(-1,.1,-21),Vector3(1,.1,-23),Vector3(0,.1,-28),Vector3(0,.1,-29)][step]
func attach_player(value: CharacterBody3D, overlay: CanvasLayer) -> void:
	player = value
	hud = overlay
	player.tutorial_action.connect(_action)
	hud.inventory_viewed.connect(_inventory_viewed)
	if not Game.inventory.has("lanterna"): player.lamp_on = false
	player.apply_settings()
	save_progress()
func _inventory_viewed() -> void:
	if step == 1: flags["inventory_viewed"] = true
	check_objectives()
func _action(action: String, data: Dictionary) -> void:
	if departing or departed: return
	if action == "move":
		var distance: float = data.get("distance",0.0)
		if step == 0: flags["walk_distance"] = float(flags.get("walk_distance",0)) + distance
		if step == 3 and data.crouched: flags["crouch_distance"] = float(flags.get("crouch_distance",0)) + distance
		if step == 4 and data.running and player.velocity.length() > 3: flags["run_distance"] = float(flags.get("run_distance",0)) + distance
	elif step == 5 and action == "hide_enter":
		hidden_seconds = 0
		flags["hide_entered"] = true
		Sound.creature_cue("patrol",Vector3(-5.5,1,-23),-29)
	elif step == 5 and action == "hide_exit":
		if flags.get("hide_waited",false): advance()
		else: feedback.emit("Entre novamente e permaneça escondido por 2 segundos antes de sair.")
func check_objectives() -> void:
	if departed or not Game.in_tutorial: return
	if step == 1 and Game.inventory.has("tutorial_key") and items.tutorial_cabinet.open and flags.get("inventory_viewed",false): advance()
	elif step == 2 and flags.get("light_seen",false) and Game.inventory.has("tutorial_mark"): advance()
	elif step == 7 and flags.get("mission_read",false) and flags.get("objectives_viewed",false) and Game.world.get("fuse_installed",false): advance()
	save_progress()
func advance() -> void:
	if step >= 8 or departed: return
	step += 1
	idle_seconds = 0
	Sound.at("switch",player.global_position if is_instance_valid(player) else Vector3.ZERO,-29)
	changed.emit()
	save_progress()
func looking_at(point: Vector3, maximum_distance := 7.0) -> bool:
	var camera: Camera3D = player.camera
	var delta := point - camera.global_position
	if delta.length() > maximum_distance or delta.length() < .01: return false
	if -camera.global_basis.z.dot(delta.normalized()) < .97: return false
	var query := PhysicsRayQueryParameters3D.create(camera.global_position,point,1,[player.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.position.distance_to(point) < .3
func _observe() -> void:
	if not is_instance_valid(player) or not Game.playing or Game.paused or departed: return
	age += .1
	if departing:
		if items.tutorial_exit.mechanism.progress <= .01: _finish_departure()
		return
	idle_seconds += .1
	if idle_seconds >= 25:
		feedback.emit(TutorialLesson.STEPS[step][2])
		idle_seconds = 0
	# Slow, low contrast variation; disabled with the existing accessibility setting.
	if Game.settings.get("light_variation",true): lamps[0].light_energy = .78 + sin(age*.7)*.035
	if player.position.y < -3 or absf(player.position.x)>5.5 or player.position.z>6.5:
		player.manipulator.release()
		player.position = spawn_position()
		player.velocity = Vector3.ZERO
		feedback.emit("Você voltou ao ponto seguro da estação. Nenhum progresso foi perdido.")
	match step:
		0:
			if looking_at(move_target): flags["looked"] = true
			if flags.get("looked",false) and float(flags.get("walk_distance",0)) >= 1.8 and Vector2(player.position.x,player.position.z).length() < .85: advance()
		2:
			if player.lamp.visible and looking_at(light_target): flags["light_seen"] = true; check_objectives()
		3:
			if player.crouched and player.position.z < -16 and float(flags.get("crouch_distance",0)) > .7: advance()
		4:
			if float(flags.get("run_distance",0)) >= 2.5 and player.position.z < -19.5: advance()
		5:
			if player.hidden and flags.get("hide_entered",false):
				hidden_seconds += .1
				if hidden_seconds >= 2 and not flags.get("hide_waited",false):
					flags["hide_waited"] = true
					feedback.emit("Os passos se afastaram. Use E / INTERAGIR para sair.")
		6: _observe_sound()
func simulate_microphone() -> void:
	if step != 6: feedback.emit("O exercício de som será liberado na estação 07."); return
	demo_active = true
	demo_time = 0
	feedback.emit("SIMULAÇÃO — indicador de intensidade; nenhum áudio está sendo capturado por esta demonstração. Som moderado, depois silêncio.")
func _observe_sound() -> void:
	if demo_active:
		demo_time += .1
		if demo_time >= 3:
			demo_active = false
			flags["mic_done"] = true
			feedback.emit("SIMULAÇÃO concluída. Sons reais também podem atrair a criatura se você autorizar o microfone. Agora arremesse a lata no alvo.")
	elif Mic.active and Mic.calibrated:
		if Mic.level > 0: flags["mic_heard"] = true; silence = 0
		elif flags.get("mic_heard",false):
			silence += .1
			if silence >= 2: flags["mic_done"] = true
	if flags.get("mic_done",false) and flags.get("can_impacted",false): advance()
func _noise(event: Dictionary) -> void:
	if step != 6 or departed: return
	if event.kind != "objeto_arremessado": return
	var origin: Node = event.origin
	if not is_instance_valid(origin) or not origin.get_parent() is PhysicalProp3D: return
	if origin.get_parent().get_parent() != self: return
	if event.position.distance_to(Vector3(3,0,-26)) > 3.5: return
	flags["can_impacted"] = true
	feedback.emit("IMPACTO DETECTADO — o ruído nasceu onde a lata bateu. Na fase, a criatura investiga essa posição.")
	_observe_sound()
	save_progress()
func recover_can() -> void:
	if step != 6: feedback.emit("A recuperação fica disponível no exercício de som."); return
	for body in get_tree().get_nodes_in_group("throwables"):
		if body.get_parent() == self: body.queue_free()
	Game.world.collected_props.erase("tutorial_can")
	Game.world.throwables = 0
	spawn_can_pickup()
	feedback.emit("Lata reposta sobre a bancada. Colete, mire no alvo e use Q / ARREMESSAR.")
func request_exit() -> void:
	if step < 8: feedback.emit("Conclua a estação atual antes de entrar no complexo."); return
	if accepted: feedback.emit("A porta está liberada. Atravesse para entrar no complexo."); return
	exit_requested.emit()
func accept_exit() -> void:
	if step != 8 or departed: return
	accepted = true
	items.tutorial_exit._set_open(true,.9)
	Sound.at("metal",items.tutorial_exit.position,-22)
	feedback.emit("Entrada liberada. Atravesse a porta. Você ainda pode permanecer na sala até atravessá-la.")
func _airlock_entered(body: Node3D) -> void:
	if body != player or not accepted or departing or step != 8: return
	departing = true
	# Crossing is the irreversible boundary, including a pause/quit mid-close.
	Game.settings["tutorial_completed"] = true
	save_progress()
	if Game.record_results and not Game.testing:
		Game.checkpoint = {"version":2,"items":[],"power":false,"doors":{},"elapsed_ms":0,"world":Game.new_world(int(Game.world.seed))}
		Game.write_json(Game.checkpoint_path(),Game.checkpoint)
		Cloud.queue_checkpoint(Game.checkpoint)
	Game.save_settings()
	player.manipulator.release()
	player.velocity = Vector3.ZERO
	player.position = Vector3(0,.1,-34)
	player.set_physics_process(false)
	player.camera.look_at(Vector3(0,1.4,-32))
	items.tutorial_exit._set_open(false,.9)
	feedback.emit("A porta se fecha atrás de você. Carregando o complexo…")
func _finish_departure() -> void:
	if departed: return
	departed = true
	Game.settings["tutorial_completed"] = true
	Game.save_settings()
	if not Game.testing: Game.write_json(Game.tutorial_path(),{"version":1,"stage":"entered","completed":true})
	Sound.at("metal",items.tutorial_exit.position,-24)
	transition_requested.emit.call_deferred()
func progress_data() -> Dictionary:
	if departing or departed: return {"version":1,"stage":"entered","completed":true}
	return {"version":1,"stage":"tutorial","step":step,"flags":flags.duplicate(true),"inventory":Game.inventory.duplicate(),"cabinet_open":bool(Game.doors.get("tutorial_cabinet",false)),"fuse_installed":Game.world.get("fuse_installed",false),"throwables":int(Game.world.get("throwables",0))}
func save_progress() -> void:
	if not departed and not Game.testing and Game.in_tutorial: Game.write_json(Game.tutorial_path(),progress_data())
func _exit_tree() -> void:
	save_progress()
