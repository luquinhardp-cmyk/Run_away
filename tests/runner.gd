extends Node
var passed := 0
var failed := 0
var main: Node
var last_noise: Dictionary

func check(condition: bool, title: String) -> void:
	if condition:
		passed += 1
		print("PASS ", title)
	else:
		failed += 1
		push_error("FAIL " + title)

func frames(count: int = 3) -> void:
	for i in count: await get_tree().physics_frame

func find_item(id: String) -> Node3D:
	for child in main.level.get_children():
		if child.get("item_id") == id: return child
	return null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()

func _run() -> void:
	var checkpoint_backup := Game.checkpoint.duplicate(true)
	var saved_exists := FileAccess.file_exists("user://checkpoint.json")
	var saved_content := FileAccess.get_file_as_string("user://checkpoint.json") if saved_exists else ""
	main = preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	await frames()
	check(main.screen == "menu", "menu inicial conectado")
	check(not Mic.active and not Mic.consent, "sem captura antes do consentimento")
	main.start(false, false)
	await frames(12)
	var player = Game.player
	var enemy = Game.enemy
	enemy.set_physics_process(false)
	check(Game.playing and is_instance_valid(player) and is_instance_valid(enemy), "cenas jogador / criatura / fase conectadas")
	check(main.level.cells.size() == 21, "planta: corredor e cinco salas duplas")
	check(main.level.nav_ready, "navigation mesh construída")
	var path := NavigationServer3D.map_get_path(enemy.agent.get_navigation_map(), Vector3(-7, 0.1, 0), Vector3(0, 0.1, -39), true)
	check(path.size() > 2, "caminho navegável entre enfermaria e saída")
	player.global_position = Vector3(0, 0.1, 0)
	player.rotation.y = 0
	var origin: Vector3 = player.global_position
	Input.action_press("forward")
	await frames(30)
	Input.action_release("forward")
	var walking_distance: float = player.global_position.distance_to(origin)
	check(walking_distance > 0.3, "movimento físico do jogador")
	player.global_position = origin
	player.velocity = Vector3.ZERO
	Input.action_press("forward")
	Input.action_press("run")
	await frames(30)
	Input.action_release("run")
	Input.action_release("forward")
	check(player.global_position.distance_to(origin) > walking_distance, "corrida mais rápida que caminhada")
	player.global_position = origin
	player.toggle_crouch()
	check(player.crouched and player.shape.shape.height == 1.0, "agachamento reduz cápsula")
	player.toggle_crouch()
	var old_rotation: float = player.rotation.y
	player.look(Vector2(80, 10))
	check(player.rotation.y != old_rotation and player.pitch != 0, "câmera FPS")
	player.rotation = Vector3.ZERO
	player.pitch = 0
	player.global_position = Vector3(-7, 0.1, 1.3)
	player.velocity = Vector3.ZERO
	Input.action_press("back")
	await frames(60)
	Input.action_release("back")
	check(player.global_position.z < 1.8, "parede bloqueia cápsula")
	var input_touch := InputEventScreenTouch.new()
	input_touch.index = 0
	input_touch.position = Vector2(150, 500)
	input_touch.pressed = true
	main.hud._input(input_touch)
	var second := InputEventScreenTouch.new()
	second.index = 1
	second.position = Vector2(700, 300)
	second.pressed = true
	main.hud._input(second)
	check(main.hud.stick_id == 0 and main.hud.look_id == 1, "multitouch: dedos independentes")
	input_touch.pressed = false
	second.pressed = false
	main.hud._input(input_touch)
	main.hud._input(second)
	NoiseBus.emitted.connect(func(event: Dictionary): last_noise = event)
	NoiseBus.emit_noise(player, 0.6, "teste", 20)
	check(last_noise.has_all(["origin", "position", "intensity", "kind", "radius", "duration", "time"]), "contrato unificado de ruídos")
	var lamp = find_item("lanterna")
	lamp.interact(player)
	check(Game.inventory.has("lanterna") and player.lamp.visible, "coleta e lanterna real")
	player.toggle_lamp()
	check(not player.lamp.visible, "interruptor da lanterna")
	var door = find_item("security")
	door.interact(player)
	check(not door.open, "segurança bloqueada sem energia")
	var generator = find_item("generator")
	generator.interact(player)
	check(not Game.power, "gerador exige fusível")
	find_item("fusivel").interact(player)
	generator.interact(player)
	check(Game.power, "fusível restaura energia")
	check(FileAccess.file_exists("user://checkpoint.json"), "checkpoint persistido")
	door.interact(player)
	await frames()
	check(door.open and door.collider.disabled, "porta desbloqueada e colisão liberada")
	find_item("cartao").interact(player)
	check(Game.inventory.has("cartao"), "inventário recebe cartão")
	var hide: Node3D
	for child in main.level.get_children():
		if child.get("kind") == "hide":
			hide = child
			break
	hide.interact(player)
	check(player.hidden, "entrada em esconderijo")
	check(not enemy.sees_player(), "esconderijo bloqueia visão")
	player.interact()
	check(not player.hidden, "saída do esconderijo")
	check(player.camera.global_position.y < 2.0, "câmera do armário permanece na altura dos olhos")
	player.global_position = Vector3(0, 0.1, -20)
	enemy.global_position = Vector3(0, 0.1, -24)
	enemy.rotation.y = PI
	await frames()
	check(enemy.sees_player(), "visão com linha livre")
	player.global_position = Vector3(4, 0.1, -20)
	await frames()
	check(not enemy.sees_player(), "parede impede detecção visual")
	enemy.age = 10
	enemy.transition(enemy.State.PATROL)
	player.global_position = Vector3(0, 0.1, -20)
	NoiseBus.emit_noise(player, 0.8, "microfone", 25)
	check(enemy.state == enemy.State.ALERT or enemy.state == enemy.State.INVESTIGATE, "IA reage a ruído espacial")
	var unobstructed := NoiseBus.perceived(last_noise, enemy)
	player.global_position = Vector3(4, 0.1, -20)
	NoiseBus.emit_noise(player, 0.8, "teste", 25)
	check(NoiseBus.perceived(last_noise, enemy) < unobstructed, "oclusão reduz audição através da parede")
	check(is_equal_approx(Mic.rms_db(PackedVector2Array([Vector2(0.1, 0.1)])), -20.0), "RMS conhecido: amplitude 0,1 = -20 dB")
	check(Mic.rms_db(PackedVector2Array()) == -80, "RMS vazio retorna silêncio")
	Mic.floor_db = -60
	check(Mic.classify(-58) == 0 and Mic.classify(-49) == 1 and Mic.classify(-40) == 2 and Mic.classify(-25) == 3, "noise gate e quatro níveis relativos ao piso")
	Game.set_paused(true)
	check(not Mic.active and get_tree().paused, "pausa suspende microfone e física")
	Game.set_paused(false)
	check(not Mic.active, "modo sem consentimento não retoma captura")
	Mic._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	await frames()
	check(not Mic.active and Game.paused, "segundo plano suspende captura e pausa")
	Mic._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	Game.set_paused(false)
	# Traverse a real NavigationAgent path with the live state machine.
	player.global_position = Vector3(-7, 0.1, 0)
	enemy.global_position = Vector3(0, 0.1, -30)
	enemy.transition(enemy.State.PATROL)
	enemy.patrol_index = 0
	var before: Vector3 = enemy.global_position
	enemy.set_physics_process(true)
	await frames(120)
	check(enemy.global_position.distance_to(before) > 0.5, "patrulha com NavigationAgent e física")
	enemy.set_physics_process(false)
	enemy.transition(enemy.State.ALERT)
	enemy.timer = enemy.listen_duration + 0.1
	enemy._physics_process(0.02)
	check(enemy.state == enemy.State.INVESTIGATE, "alerta transita para investigação")
	enemy.transition(enemy.State.CHASE)
	enemy.unseen = 3
	enemy.perceive_clock = 10
	enemy._physics_process(0.02)
	check(enemy.state == enemy.State.LOST, "perseguição perde alvo sem visão")
	enemy.timer = 3
	enemy._physics_process(0.02)
	check(enemy.state == enemy.State.SEARCH, "perda de alvo leva à busca")
	enemy.timer = 7
	enemy._physics_process(0.02)
	check(enemy.state == enemy.State.RETURN, "busca expira e retorna")
	# Real art assets, skeletal deformation and additional navigation routes.
	var exterior_path := NavigationServer3D.map_get_path(enemy.agent.get_navigation_map(), Vector3(0, 0.1, 0), Vector3(0, 0.1, 12), true)
	check(exterior_path.size() > 1 and exterior_path[-1].distance_to(Vector3(0, 0.1, 12)) < 1, "pátio externo conectado à navegação")
	var basement_path := NavigationServer3D.map_get_path(enemy.agent.get_navigation_map(), Vector3(-8, 0.1, -32), Vector3(-20, -1.7, -32), true)
	check(basement_path.size() > 2 and basement_path[-1].distance_to(Vector3(-20, -1.7, -32)) < 1, "rampa conecta subsolo à navegação")
	check(enemy.visual.skeleton.get_bone_count() == 29, "rig real com 29 ossos")
	check(enemy.visual.clip_names.size() == 12, "12 animações glTF importadas")
	var skinned_mesh: MeshInstance3D = enemy.visual.model.find_children("*", "MeshInstance3D", true, false)[0]
	check(skinned_mesh.skin != null, "mesh associado ao Skin e Skeleton3D")
	check(not skinned_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV].is_empty(), "UVs reais no modelo")
	check(skinned_mesh.mesh.get_aabb().size.y > 2.2 and skinned_mesh.mesh.get_aabb().size.y < 2.9, "escala da criatura cabe no corredor")
	var anim: AnimationPlayer = enemy.visual.animator
	var rig: Skeleton3D = enemy.visual.skeleton
	var head := rig.find_bone("head")
	var ear := rig.find_bone("ear_L")
	anim.play("idle", 0)
	anim.seek(0, true)
	anim.advance(0)
	var head_rest := rig.get_bone_pose_rotation(head)
	var ear_rest := rig.get_bone_pose_rotation(ear)
	var root_position: Vector3 = enemy.global_position
	anim.play("listen", 0)
	anim.seek(0.8, true)
	anim.advance(0)
	check(head_rest.angle_to(rig.get_bone_pose_rotation(head)) > 0.2, "escuta inclina o osso da cabeça")
	check(ear_rest.angle_to(rig.get_bone_pose_rotation(ear)) > 0.15, "escuta articula a cartilagem auditiva")
	check(enemy.global_position == root_position, "animação não teletransporta a criatura")
	enemy.hearing_cooldown = 0
	enemy.transition(enemy.State.PATROL)
	player.global_position = enemy.global_position + Vector3(0, 0, 2)
	NoiseBus.emit_noise(player, 0.8, "microfone", 25)
	check(enemy.state == enemy.State.ALERT and enemy.visual.active_clip == "listen", "ruído percebido dispara apresentação de escuta")
	enemy.timer = 0.5
	NoiseBus.emit_noise(player, 0.8, "microfone", 25)
	check(enemy.timer == 0.5, "ruídos repetidos não reiniciam a animação de escuta")
	for name in HorrorArt.NAMES:
		var mat := HorrorArt.surface(name)
		check(mat.albedo_texture != null and mat.normal_texture != null and mat.roughness_texture != null, "PBR carregado: " + name)
	var previous_quality: float = Game.settings.quality
	Game.settings.quality = 0.0
	Game.updated.emit()
	check(enemy.visual.low and enemy.visual.skeleton.get_bone_count() == 29, "LOD baixo preserva rig e animações")
	check(HorrorArt.surface("aged_concrete").albedo_texture.get_width() == 256 and not HorrorArt.surface("aged_concrete").normal_enabled, "perfil baixo usa mapas 256 e simplifica material")
	Game.settings.quality = previous_quality
	Game.updated.emit()
	check(not enemy.visual.low and HorrorArt.surface("aged_concrete").albedo_texture.get_width() == 512, "perfil médio restaura modelo e texturas 512")
	var outcome: Array[bool] = []
	Game.ended.connect(func(won: bool): outcome.append(won))
	find_item("exit").interact(player)
	check(outcome == [true] and not Game.playing, "objetivo completo termina em vitória")
	main.start(true, false)
	await frames(6)
	check(Game.power and Game.inventory.has("fusivel"), "checkpoint restaura progresso sem perder itens")
	Game.enemy.set_physics_process(false)
	Game.enemy.ready_navigation = true
	Game.enemy.age = 10
	Game.enemy.transition(Game.enemy.State.ATTACK)
	Game.enemy.timer = 1
	Game.enemy._physics_process(0.01)
	check(outcome == [true, false], "ataque termina em derrota")
	main.to_menu()
	check(main.screen == "menu" and not Game.playing and not get_tree().paused, "retorno ao menu limpa a sessão")
	# Restore user data after the integration suite.
	Game.checkpoint = checkpoint_backup
	if saved_exists:
		var file := FileAccess.open("user://checkpoint.json", FileAccess.WRITE)
		file.store_string(saved_content)
		file.close()
	else: DirAccess.remove_absolute("user://checkpoint.json")
	main.free()
	await get_tree().create_timer(0.2).timeout
	print("RESULT ", passed, " passed; ", failed, " failed. Hardware microphone/Android not exercised.")
	get_tree().quit(1 if failed else 0)
