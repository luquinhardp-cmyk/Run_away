extends Node
signal tension_changed(level: int)
signal scare_started(id: String)
var facility: Node3D
var definitions: Array[HorrorScare] = []
var tension := 0
var clock := 0.0
var evaluation := 0.0
var since_chase := 1000.0
var since_scare := 0.0
var active_until := 0.0
var cooldown := 16.0
var last_times: Dictionary = {}
var counts: Dictionary = {}
var history: Array = []
var rng := RandomNumberGenerator.new()
var enabled := true
var overlay: ColorRect
var dip_remaining := 0.0
var rim: OmniLight3D
var active_tween: Tween
var tween_source: Node3D
var cosmetic_tweens: Array[Tween] = []

func _ready() -> void:
	facility = get_parent()
	rng.seed = int(Game.world.get("seed", 1)) + 3501
	var saved: Dictionary = Game.world.get("horror", {})
	counts = saved.get("counts", {}).duplicate()
	history = saved.get("history", []).duplicate()
	cooldown = maxf(8, float(saved.get("cooldown_remaining", 16)))
	if saved.has("rng_state"): rng.state = int(saved.rng_state)
	for id in ["knock", "door_slow", "door_slam", "light_dip", "lamp_fault", "object_slide", "radio_start", "real_presence", "creature_scratch"]:
		definitions.append(load("res://resources/horror/events/" + id + ".tres"))
	NoiseBus.emitted.connect(_noise)
	var layer := CanvasLayer.new()
	layer.layer = 9
	add_child(layer)
	overlay = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; uniform float amount = 0.0; void fragment(){ float edge=smoothstep(0.24,0.72,length(UV-vec2(0.5))); COLOR=vec4(0.025,0.015,0.008,edge*amount); }"
	var material := ShaderMaterial.new()
	material.shader = shader
	overlay.material = material
	layer.add_child(overlay)

func _noise(event: Dictionary) -> void:
	# A microphone event raises attention, never directly schedules a jumpscare.
	if event.kind == "microfone" and event.intensity > 0.5 and not Game.capture_in_progress:
		_set_tension(maxi(tension, 1))

func _set_tension(value: int) -> void:
	if value != tension:
		tension = value
		tension_changed.emit(tension)

func _process(delta: float) -> void:
	if not Game.playing or not is_instance_valid(Game.player) or not is_instance_valid(Game.enemy):
		overlay.hide()
		return
	overlay.visible = not Game.paused and Game.settings.get("visual_scares", true)
	if Game.paused: return
	clock += delta
	since_scare += delta
	cooldown = maxf(0, cooldown - delta)
	dip_remaining = maxf(0, dip_remaining - delta)
	facility.horror_light_multiplier = 0.35 + 0.65 * (1.0 - sin(dip_remaining / 1.8 * PI)) if dip_remaining > 0 else 1.0
	var enemy := Game.enemy
	var danger := Game.player.global_position.distance_to(enemy.global_position)
	if Game.capture_in_progress:
		_set_tension(5)
		for tween in cosmetic_tweens:
			if is_instance_valid(tween): tween.kill()
		cosmetic_tweens.clear()
		dip_remaining = 0
		facility.horror_light_multiplier = 1.0
		Game.player.lamp_fault = 0
		if is_instance_valid(rim): rim.queue_free()
		if is_instance_valid(active_tween):
			active_tween.kill()
			if is_instance_valid(tween_source): tween_source.mesh.position.y = 2.8 if tween_source.open else 0
	elif enemy.state == enemy.State.CHASE:
		since_chase = 0
		_set_tension(4)
	else:
		since_chase += delta
		_set_tension(3 if danger < 7 and enemy.state in [enemy.State.INVESTIGATE, enemy.State.SEARCH] else (2 if danger < 12 else (1 if enemy.suspicion > 0.12 else 0)))
	var amount: float = minf(0.22, tension * 0.035) * Game.settings.scares if Game.settings.get("visual_scares", true) else 0.0
	(overlay.material as ShaderMaterial).set_shader_parameter("amount", amount)
	evaluation -= delta
	if evaluation > 0: return
	evaluation = 0.5
	_persist_state()
	if not enabled or Game.capture_in_progress or tension >= 4 or danger < 3 or since_chase < 14 or cooldown > 0 or clock < active_until or Game.settings.scares <= 0: return
	var choices: Array[Dictionary] = []
	var total := 0.0
	for definition in definitions:
		var source := eligible_source(definition)
		if source == null: continue
		var weight := definition.weight * (0.25 if definition.id in history.slice(-2) else 1.0)
		choices.append({"definition": definition, "source": source, "weight": weight})
		total += weight
	if choices.is_empty(): cooldown = 4; return
	var pick := rng.randf() * total
	for choice in choices:
		pick -= choice.weight
		if pick <= 0:
			trigger(choice.definition, choice.source)
			break

func eligible_source(definition: HorrorScare) -> Node3D:
	if definition.weight <= 0 or definition.intensity > maxi(1, tension + 1): return null
	if int(counts.get(definition.id, 0)) >= definition.maximum or clock - float(last_times.get(definition.id, -1000)) < definition.cooldown: return null
	if definition.requires_power and not Game.power: return null
	if definition.category == "visual" and not Game.settings.get("visual_scares", true): return null
	if definition.id in ["light_dip", "lamp_fault"] and not Game.settings.get("light_variation", true): return null
	var player := Game.player
	if definition.area == "main" and absf(player.global_position.x) > 2: return null
	if definition.area == "maintenance" and not (player.global_position.x > 3 and player.global_position.z > -12): return null
	if definition.id in ["real_presence", "creature_scratch"]:
		if player.global_position.distance_to(Game.enemy.global_position) > definition.max_distance: return null
		if definition.id == "creature_scratch" and Game.enemy.state not in [Game.enemy.State.SEARCH, Game.enemy.State.INVESTIGATE]: return null
		var ray := PhysicsRayQueryParameters3D.create(player.camera.global_position, Game.enemy.visual.head_position(), 1 | 4, [player.get_rid()])
		var hit := player.get_world_3d().direct_space_state.intersect_ray(ray)
		if definition.id == "real_presence" and (hit.is_empty() or hit.collider != Game.enemy): return null
		return Game.enemy
	if definition.id == "lamp_fault": return player if player.lamp_on and not player.hidden else null
	if definition.id == "light_dip": return player
	if definition.id in ["object_slide", "radio_start"]:
		var source: Node3D = facility.find_interaction("can" if definition.id == "object_slide" else "radio")
		if source == null: return null
		if source.global_position.distance_to(player.global_position) > definition.max_distance: return null
		if definition.id == "radio_start" and source.enabled: return null
		return source
	for door in get_tree().get_nodes_in_group("doors"):
		var distance: float = door.global_position.distance_to(player.global_position)
		if distance < definition.min_distance or distance > definition.max_distance: continue
		if definition.id == "door_slam" and (not door.open or door.closing_blocked()): continue
		if definition.id in ["knock", "door_slow"] and door.open: continue
		if definition.id == "door_slow" and not door._door_unlocked(): continue
		return door
	return null

func trigger(definition: HorrorScare, source: Node3D) -> bool:
	if not enabled or cooldown > 0 or Game.paused or Game.capture_in_progress or not Game.playing or clock < active_until or not is_instance_valid(source): return false
	if eligible_source(definition) != source: return false
	counts[definition.id] = int(counts.get(definition.id, 0)) + 1
	last_times[definition.id] = clock
	history.append(definition.id)
	if history.size() > 6: history.pop_front()
	cooldown = rng.randf_range(22, 38) / maxf(0.3, Game.settings.scares)
	cooldown = minf(cooldown, 110)
	active_until = clock + 2.5
	match definition.id:
		"knock": Sound.creature_cue("knock", source.global_position, -24)
		"door_slow":
			Sound.creature_cue("creak", source.global_position, -23)
			active_tween = source.create_tween()
			tween_source = source
			active_tween.tween_property(source.mesh, "position:y", 2.8, 1.6)
			active_tween.tween_callback(func():
				if not Game.capture_in_progress:
					source._set_open(true)
					Game.doors[source.item_id] = true
					Game.updated.emit())
		"door_slam":
			if source.closing_blocked(): return false
			source._set_open(false)
			Game.doors[source.item_id] = false
			Sound.at("metal", source.global_position, -20)
			NoiseBus.emit_noise(source, 0.35, "porta", 14)
		"light_dip": dip_remaining = 1.8
		"lamp_fault": Game.player.lamp_fault = 0.65
		"object_slide":
			var tween := source.create_tween()
			cosmetic_tweens = cosmetic_tweens.filter(func(item: Tween): return item.is_running())
			cosmetic_tweens.append(tween)
			tween.tween_property(source.mesh, "position:x", 0.2, 0.6)
			NoiseBus.emit_noise(source, 0.4, "objeto", 16)
			Sound.at("metal", source.global_position, -24)
		"radio_start": source.set_device(true)
		"creature_scratch": Sound.creature_cue("drag", Game.enemy.global_position, -24)
		"real_presence":
			Sound.creature_cue("sniff", Game.enemy.visual.head_position(), -22)
			if Game.settings.quality > 0:
				rim = OmniLight3D.new()
				rim.light_color = Color("a7a38e")
				rim.light_energy = 0.45
				rim.omni_range = 3
				rim.shadow_enabled = false
				source.add_child(rim)
				rim.position = Vector3(0.5, 2, 0)
				var tween := rim.create_tween()
				tween.tween_property(rim, "light_energy", 0.0, 1.6)
				tween.tween_callback(rim.queue_free)
	since_scare = 0
	_persist_state()
	if Game.record_results: Game.save_checkpoint()
	Game.updated.emit()
	scare_started.emit(definition.id)
	return true

func _persist_state() -> void:
	var saved_counts := {}
	for definition in definitions:
		if definition.persistent and counts.has(definition.id): saved_counts[definition.id] = counts[definition.id]
	Game.world.horror = {"counts": saved_counts, "history": history.duplicate(), "cooldown_remaining": cooldown, "rng_state": str(rng.state)}

func _exit_tree() -> void:
	if is_instance_valid(facility): facility.horror_light_multiplier = 1.0
	if is_instance_valid(rim): rim.queue_free()
