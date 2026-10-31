extends Node
signal triggered(id: String)
var facility: Node3D
var clock := 0.0
var power_age := 0.0
var last_trigger: Dictionary = {}
var definitions: Array[HorrorEvent] = []
var pipe_installed := false
var enabled := true

func _ready() -> void:
	facility = get_parent()
	for id in ["blackout", "pipe", "impact"]: definitions.append(load("res://resources/world/" + id + ".tres"))
	definitions.sort_custom(func(a: HorrorEvent, b: HorrorEvent): return a.priority > b.priority)
	if Game.world.get("events", {}).has("pipe"): _fallen_pipe()

func _process(delta: float) -> void:
	if not Game.playing or not enabled: return
	clock += delta
	if Game.power: power_age += delta
	if not is_instance_valid(Game.player): return
	for definition in definitions:
		var eligible := false
		match definition.id:
			"impact": eligible = Game.player.global_position.z < -12
			"pipe": eligible = clock > Game.difficulty_profile().event_interval and Game.player.global_position.z < -16
			"blackout": eligible = power_age > Game.difficulty_profile().event_interval and not Game.world.get("escaped", false)
		if eligible and trigger(definition.id): break

func trigger(id: String) -> bool:
	var definition: HorrorEvent
	for candidate in definitions:
		if candidate.id == id: definition = candidate; break
	if definition == null: return false
	if definition.persistent and Game.world.events.has(id): return false
	if clock - float(last_trigger.get(id, -1000)) < definition.cooldown: return false
	if id == "blackout" and not Game.power: return false
	last_trigger[id] = clock
	var rng := RandomNumberGenerator.new()
	rng.seed = int(Game.world.seed) + id.hash() + int(clock / maxf(1, definition.cooldown))
	if rng.randf() > definition.probability: return false
	if definition.persistent: Game.world.events[id] = true
	match id:
		"blackout":
			Game.world.blackout = true
			Game.power = false
			facility.message.emit("FALHA ELÉTRICA · o fusível continua instalado. Reative o gerador; rotas manuais continuam abertas.")
			var alarm: Node3D = facility.find_interaction("alarm")
			if is_instance_valid(alarm): alarm.set_device(true)
		"pipe":
			_fallen_pipe()
			facility.message.emit("Uma tubulação caiu. A lateral do corredor permanece livre.")
		"impact":
			var source: Node3D = facility.find_interaction("can")
			if is_instance_valid(source):
				if source is PhysicalProp3D: source.nudge(Vector3(1,0.2,0),0.6)
	if Game.record_results: Game.save_checkpoint()
	Game.updated.emit()
	triggered.emit(id)
	return true

func _fallen_pipe() -> void:
	if pipe_installed: return
	pipe_installed = true
	facility.box(Vector3(-1.05, 0.25, -20), Vector3(1.25, 0.5, 1.3), HorrorArt.surface("rusted_iron"))
	var source := Node3D.new()
	facility.add_child(source)
	source.position = Vector3(-1.05, 0.4, -20)
	NoiseBus.emit_noise(source, 0.85, "tubulacao", 28)
	Sound.at("metal", source.global_position, -10)
	facility.request_navigation_update()
