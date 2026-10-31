extends Node
var clips: Dictionary = {}
var last_spawn_usec := 0

func stop_all() -> void:
	for child in get_children():
		if child is AudioStreamPlayer3D:
			child.stop()
			child.queue_free()

func _ready() -> void:
	for name in ["Effects", "Music"]:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, name)
	Game.updated.connect(_settings)
	_settings()

func _settings() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Effects"), linear_to_db(Game.settings.effects))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(Game.settings.music))

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
