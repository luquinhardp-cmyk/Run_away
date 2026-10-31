extends StaticBody3D
@export var kind := "document"
@export var item_id := ""
@export var title := "Examinar"
@export var required_key := ""
@export var requires_power := false
@export var door_profile := "rusted"
@export var visual_protection := 1.0
@export var interaction_distance := 2.7
var occupant: CharacterBody3D
var enabled := false
var device_time := 0.0
var pulse := 0.0
var device_audio: AudioStreamPlayer3D
var indicator: MeshInstance3D
var open := false
var mesh: MeshInstance3D
var collider: CollisionShape3D
var original_position := Vector3.ZERO
var message := ""
var mechanism: Node
signal notified(text: String)

func _ready() -> void:
	collision_layer = (1 | 8) if kind in ["door","generator","hide","radio","alarm","fuse_panel","pickup"] else 8
	collision_mask = 0
	if kind == "door": set_meta("door", true)
	if kind == "hide":
		add_to_group("hide_spots")
		add_to_group("search_points")
	if kind == "door" and item_id == "security": requires_power = true
	if kind == "door" and item_id == "workshop": required_key = "chave_oficina"
	mesh = get_node_or_null("Mesh")
	collider = get_node_or_null("Collision")
	original_position = position
	if kind == "door" and Game.doors.get(item_id, false): _set_open(true)
	if kind == "pickup" and Game.inventory.has(item_id): queue_free()
	if kind == "throw_pickup" and item_id in Game.world.get("collected_props", []): queue_free()
	if kind in ["fuse_panel", "generator", "exit"]:
		indicator = MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.065
		sphere.height = 0.13
		indicator.mesh = sphere
		indicator.position = Vector3(0.2, 0.2, 0.45 if kind == "generator" else 0.13)
		add_child(indicator)
		Game.updated.connect(_visual_state)
		_visual_state()
	PhysicsSurfaces.attach(self, "metal" if kind in ["door","generator","hide","alarm","fuse_panel"] else "wood")
	if kind in ["door","drawer"]:
		mechanism = Node.new()
		mechanism.set_script(preload("res://scripts/physics/mechanism.gd"))
		add_child(mechanism)

func _visual_state() -> void:
	var complete: bool = Game.world.get("fuse_installed", false) if kind == "fuse_panel" else Game.power
	indicator.material_override = HorrorArt.solid(Color("77a56d") if complete else Color("a57736"), 0.5)

func get_prompt() -> String:
	if kind in ["radio", "alarm"]: return ("Desligar " if enabled else "Ligar ") + ("rádio" if kind == "radio" else "alarme")
	if kind == "fuse_panel": return "Fusível instalado" if Game.world.get("fuse_installed", false) else "Instalar fusível no painel"
	if kind == "door": return "Fechar porta" if open else title
	if kind == "drawer": return "Fechar gaveta" if open else "Abrir gaveta"
	if kind == "generator" and Game.power: return "Energia restaurada"
	return title

func interaction_info() -> Dictionary:
	return {"name": title, "action": get_prompt(), "distance": interaction_distance, "key": required_key, "requires_power": requires_power, "state": "open" if open else ("locked" if not _door_unlocked() else "closed"), "sound": door_profile}

func _door_unlocked() -> bool:
	return (not requires_power or Game.power) and (required_key.is_empty() or Game.world.get("unlocks", {}).get(item_id, false))

func approach_position() -> Vector3:
	return global_position - Vector3.UP + global_basis.z * 1.25

func has_occupant() -> bool:
	return is_instance_valid(occupant) and occupant.hidden and occupant.hide_spot == self

func try_open_for_creature() -> bool:
	if not _door_unlocked(): return false
	if not open: Sound.at("metal", global_position, -18)
	_set_open(true)
	return true

func closing_blocked() -> bool:
	for actor in [Game.player, Game.enemy]:
		if is_instance_valid(actor) and global_position.distance_to(actor.global_position + Vector3.UP) < 1.3: return true
	return false

func set_device(value: bool) -> void:
	enabled = value
	device_time = 9.0 if kind == "alarm" else 35.0
	pulse = 0
	if not is_instance_valid(device_audio):
		device_audio = AudioStreamPlayer3D.new()
		device_audio.stream = load("res://assets/audio/" + ("alarm" if kind == "alarm" else "radio") + ".wav")
		device_audio.bus = "Effects"
		device_audio.volume_db = -14
		device_audio.max_distance = 30
		add_child(device_audio)
		device_audio.finished.connect(func():
			if enabled: device_audio.play())
	if enabled: device_audio.play()
	else: device_audio.stop()

func _process(delta: float) -> void:
	if not enabled or not Game.playing: return
	device_time -= delta
	pulse -= delta
	if pulse <= 0:
		NoiseBus.emit_noise(self, 1.15 if kind == "alarm" else 0.65, "alarme" if kind == "alarm" else "radio", 38 if kind == "alarm" else 26, 1.0)
		pulse = 1.4
	if device_time <= 0: set_device(false)

func interact(player: CharacterBody3D) -> void:
	if is_queued_for_deletion(): return
	match kind:
		"pickup":
			if item_id == "cartao" and not Game.power:
				notified.emit("O leitor do cartão está sem energia. Acione o gerador.")
				return
			Game.collect(item_id)
			Sound.at("pickup", global_position)
			if item_id == "lanterna": player.toggle_lamp()
			notified.emit("Coletado: " + title)
			queue_free()
		"door":
			if requires_power and not Game.power:
				notified.emit("Fechadura sem energia. Restaure o gerador.")
				return
			if not required_key.is_empty() and not Game.world.unlocks.get(item_id, false):
				if not Game.inventory.has(required_key):
					notified.emit("Trancada. Chave da oficina: procure no depósito.")
					return
				Game.world.unlocks[item_id] = true
			if open and closing_blocked():
				notified.emit("A passagem está ocupada. Afaste-se para fechar.")
				return
			_set_open(not open)
			Game.doors[item_id] = open
			var loudness: float = {"light": 0.2, "metal": 0.45, "heavy": 0.7, "rusted": 0.55}.get(door_profile, 0.35)
			NoiseBus.emit_noise(self, loudness, "porta", 12.0 + loudness * 10)
			Sound.at("metal", global_position)
			Game.updated.emit()
			if Game.record_results: Game.save_checkpoint()
		"hide": player.enter_hide(self)
		"fuse_panel":
			if not Game.inventory.has("fusivel"):
				notified.emit("Encaixe vazio. Procure o fusível na manutenção.")
				return
			Game.world.fuse_installed = true
			Sound.at("switch", global_position, -18)
			notified.emit("Fusível instalado. Acione o gerador ao lado.")
			if Game.record_results: Game.save_checkpoint()
			Game.updated.emit()
		"generator":
			if Game.power: return
			if not Game.inventory.has("fusivel"):
				notified.emit("Falta um fusível. Procure na manutenção.")
				return
			if not Game.world.get("fuse_installed", false):
				notified.emit("Instale o fusível no painel ao lado antes de acionar.")
				return
			Game.power = true
			Game.world.generator_started = true
			Game.world.blackout = false
			Game.save_checkpoint()
			NoiseBus.emit_noise(self, 1.0, "gerador", 36.0, 2.0)
			Sound.at("generator", global_position, -8)
			notified.emit("ENERGIA RESTAURADA · checkpoint salvo na enfermaria")
		"exit":
			if Game.power and Game.inventory.has("cartao"): Game.finish(true)
			else: notified.emit("Saída bloqueada. Precisa de energia e cartão de segurança.")
		"document": notified.emit(message)
		"radio", "alarm": set_device(not enabled)
		"throw_pickup":
			Game.world.throwables = int(Game.world.get("throwables", 0)) + 1
			Game.world.collected_props.append(item_id)
			player.throw_selected = true
			Game.updated.emit()
			if Game.record_results: Game.save_checkpoint()
			notified.emit("Peça metálica coletada. Mire e use Q / ARREMESSAR.")
			queue_free()
		"drawer":
			open = not open
			mechanism.set_state(open)
			Sound.physics_impact("slide",global_position,-26)
			NoiseBus.emit_noise(self,0.15,"gaveta",6)
			Game.world.get_or_add("physics",{})[item_id] = {"open":open}
			if Game.record_results: Game.save_checkpoint()
			notified.emit("Uma ferramenta e um bilhete: NÃO LIGUE O ALARME SE ELE ESTIVER PERTO.")
		"object":
			NoiseBus.emit_noise(self, 1.0, "objeto", 26.0)
			Sound.at("metal", global_position, -8)
			mesh.rotation.z += 0.7
			notified.emit("O metal ecoa pelo corredor. Afaste-se.")

func _set_open(value: bool, seconds := 0.65) -> void:
	open = value
	if collider: collider.set_deferred("disabled", value)
	if is_instance_valid(mechanism): mechanism.set_state(value, seconds)
	elif mesh: mesh.position.y = 0.0

func reveal_for_capture() -> void:
	# The real locker shell parts open after occupancy has been confirmed.
	if kind == "hide" and mesh:
		var tween := create_tween()
		tween.tween_property(mesh, "rotation:y", 0.65, 0.3)
