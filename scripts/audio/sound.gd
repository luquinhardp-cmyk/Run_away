extends Node
var clips: Dictionary = {}

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
	var file := "res://assets/audio/%s.wav" % kind
	if not ResourceLoader.exists(file): return
	var sound := AudioStreamPlayer3D.new()
	sound.stream = load(file)
	sound.bus = "Effects"
	sound.volume_db = gain
	sound.max_distance = 30.0
	add_child(sound)
	sound.global_position = pos
	sound.finished.connect(sound.queue_free)
	sound.play()
