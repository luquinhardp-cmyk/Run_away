extends Node
var night: Node3D
var voices: Array[AudioStreamPlayer3D] = []
var rng := RandomNumberGenerator.new()
var timer := 5.0
var silence := 0.0
var last_bank := ""
var played := 0
var enabled := true
func _ready() -> void:
	night = get_parent()
	rng.seed = int(Game.world.get("seed",1))+7411
	for i in 3:
		var voice := AudioStreamPlayer3D.new()
		voice.bus = "Effects"
		voice.max_distance = 48
		voice.unit_size = 8
		voice.volume_db = -27
		night.add_child(voice)
		voices.append(voice)
func _process(delta: float) -> void:
	if not enabled or not Game.playing or Game.paused: return
	var outdoors: bool = is_instance_valid(Game.player) and night.outdoors
	var hush: bool = night.flying.active or Game.capture_in_progress
	for voice in voices:
		var desired := -48.0 if not outdoors or hush else -27.0
		voice.volume_db = move_toward(voice.volume_db,desired,delta*12)
	silence = maxf(0,silence-delta)
	timer -= delta
	if timer>0 or silence>0 or hush or not outdoors: return
	timer = rng.randf_range(12,26)
	if rng.randf()<0.22:
		silence = rng.randf_range(10,22)
		return
	var banks := ["wind","leaves","insects","branch","animal"]
	banks.erase(last_bank)
	last_bank = banks[rng.randi_range(0,banks.size()-1)]
	for voice in voices:
		if voice.playing: continue
		voice.stream = load("res://assets/audio/night/forest_"+last_bank+".wav")
		voice.global_position = night.forest.anchors[rng.randi_range(0,night.forest.anchors.size()-1)]
		voice.pitch_scale = rng.randf_range(0.94,1.04)
		voice.play()
		played += 1
		break
