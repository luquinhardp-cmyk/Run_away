extends Node
var last_impact_sample := -1
func physics_impact(bank: String, point: Vector3, gain: float, previous := -1) -> void:
	if get_child_count() >= 24: return
	var index := (previous + 1 + int(Time.get_ticks_msec() % 2)) % 3
	if index == previous: index = (index + 1) % 3
	last_impact_sample = index
	var key := "impact_" + bank + str(index)
	if not clips.has(key): clips[key] = load("res://assets/audio/impacts/%s_%d.wav" % [bank, index])
	var sound := AudioStreamPlayer3D.new()
	sound.stream = clips[key]
	sound.bus = "Effects"
	sound.volume_db = clampf(gain, -38, -10)
	sound.pitch_scale = 0.97 + (index * 0.03)
	sound.max_distance = 32
	add_child(sound)
	sound.global_position = point
	sound.finished.connect(sound.queue_free)
	sound.play()
	if gain > -17: Mic.output_guard = maxf(Mic.output_guard, 0.25)
var clips: Dictionary = {}
var last_spawn_usec := 0
var cue_clock: Dictionary = {}
var cue_last: Dictionary = {}
var cue_cache: Dictionary = {}
var voice_rng := RandomNumberGenerator.new()
var voice_run := ""

func creature_cue(kind: String, pos: Vector3, gain: float = -20) -> void:
	if voice_run != Game.run_id:
		voice_run = Game.run_id
		voice_rng.seed = int(Game.world.get("seed", 1)) + 615
		cue_clock.clear()
		cue_last.clear()
	if not cue_cache.has(kind):
		var path := "res://resources/horror/audio/" + kind + ".tres"
		if not ResourceLoader.exists(path): return
		cue_cache[kind] = load(path)
	var cue: CreatureCue = cue_cache[kind]
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(cue_clock.get(kind, -1000)) < cue.min_interval or cue.samples.is_empty(): return
	var index := voice_rng.randi_range(0, cue.samples.size() - 1)
	if cue.samples.size() > 1 and index == int(cue_last.get(kind, -1)): index = (index + 1) % cue.samples.size()
	if get_child_count() >= 24: return
	cue_clock[kind] = now
	cue_last[kind] = index
	var sound := AudioStreamPlayer3D.new()
	sound.stream = cue.samples[index]
	sound.bus = "Threat" if kind == "capture" else "Effects"
	sound.volume_db = gain
	sound.pitch_scale = voice_rng.randf_range(cue.pitch_min, cue.pitch_max)
	sound.max_distance = cue.max_distance
	add_child(sound)
	sound.global_position = pos
	sound.finished.connect(sound.queue_free)
	sound.play()
	if gain > -16: Mic.output_guard = maxf(Mic.output_guard, 0.25)

func stop_all() -> void:
	for child in get_children():
		if child is AudioStreamPlayer3D:
			child.stop()
			child.queue_free()

func _ready() -> void:
	for name in ["Effects", "Music", "Threat"]:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, name)
	Game.updated.connect(_settings)
	_settings()

func _settings() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Effects"), linear_to_db(Game.settings.effects) - (9 if Game.capture_in_progress else 0))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(Game.settings.music) - (6 if Game.capture_in_progress else 0))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Threat"), linear_to_db(Game.settings.effects))

func at(kind: String, pos: Vector3, gain: float = -12.0) -> void:
	if get_child_count() >= 24: return
	var file := "res://assets/audio/%s.wav" % kind
	if not ResourceLoader.exists(file): return
	var started := Time.get_ticks_usec()
	var sound := AudioStreamPlayer3D.new()
	if not clips.has(kind): clips[kind] = load(file)
	sound.stream = clips[kind]
	sound.bus = "Effects"
	sound.volume_db = gain
	sound.max_distance = 30.0
	add_child(sound)
	sound.global_position = pos
	sound.finished.connect(sound.queue_free)
	sound.play()
	# A short guard reduces self-triggering from known nearby effects; not echo cancellation.
	if gain > -16 and is_instance_valid(Game.player) and Game.player.global_position.distance_to(pos) < 5:
		Mic.output_guard = maxf(Mic.output_guard, 0.25)
	last_spawn_usec = Time.get_ticks_usec() - started
