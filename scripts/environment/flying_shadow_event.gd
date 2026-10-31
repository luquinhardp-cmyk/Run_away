extends Node3D
signal appeared(id: String)
signal vanished(id: String)
var config: FlyingShadowConfig = preload("res://resources/environment/flying_config.tres")
var patterns: Array[FlyingShadowPattern] = []
var rng := RandomNumberGenerator.new()
var night: Node3D
var entity: Node3D
var animator: AnimationPlayer
var scream: AudioStreamPlayer3D
var wing: AudioStreamPlayer3D
var whoosh: AudioStreamPlayer3D
var whoosh_played := false
var duration := 14.0
var materials: Array[StandardMaterial3D] = []
var elapsed := 0.0
var active := false
var selected: FlyingShadowPattern
var last_id := ""
var cooldown := 0.0
var exploration := 0.0
var evaluation := 0.0
var wing_clock := 0.0
var vocal_played := false
var path: Array[Vector3] = []
var low := false
var enabled := true
var event_count := 0
var last_sample := -1
func _ready() -> void:
	name = "FlyingShadowEvent"
	night = get_parent()
	rng.seed = int(Game.world.get("seed",1))+7319
	cooldown = rng.randf_range(config.minimum_interval,config.reference_maximum)
	last_id = Game.last_flight_pattern
	for id in ["moon_cross","distant","near","tree_rise","silent","moon_silent","unseen_cry"]:
		patterns.append(load("res://resources/environment/flights/"+id+".tres"))
	_load_model()
	for bus_name in ["FlyingNear","FlyingDistant"]:
		if AudioServer.get_bus_index(bus_name)<0:
			AudioServer.add_bus()
			var index := AudioServer.bus_count-1
			AudioServer.set_bus_name(index,bus_name)
			AudioServer.set_bus_send(index,"Effects")
			var filter := AudioEffectLowPassFilter.new()
			filter.cutoff_hz = 2600 if bus_name=="FlyingDistant" else 8000
			AudioServer.add_bus_effect(index,filter)
	scream = _voice()
	wing = _voice()
	whoosh = _voice()
	Game.updated.connect(_quality)
	Game.ended.connect(func(_won: bool): finish_event())
func _voice() -> AudioStreamPlayer3D:
	var audio := AudioStreamPlayer3D.new()
	audio.bus = "FlyingDistant"
	audio.max_distance = 170
	audio.unit_size = 35
	audio.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	entity.add_child(audio)
	return audio
func _load_model() -> void:
	if is_instance_valid(entity): entity.free()
	low = Game.settings.quality < 1
	entity = Node3D.new()
	entity.name = "TheOnlyFlyingShadow"
	entity.add_to_group("flying_shadows")
	add_child(entity)
	var model: Node3D = load("res://assets/models/sombra_alada_low.glb" if low else "res://assets/models/sombra_alada.glb").instantiate()
	entity.add_child(model)
	animator = model.find_children("*","AnimationPlayer",true,false)[0]
	materials.clear()
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.004,0.005,0.006,0)
		mat.roughness = 0.95
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh.material_override = mat
		materials.append(mat)
	entity.hide()
func _quality() -> void:
	if not active and low != (Game.settings.quality<1):
		_load_model()
		scream = _voice()
		wing = _voice()
		whoosh = _voice()
func play_clip(plain: String) -> bool:
	for clip in animator.get_animation_list():
		if str(clip).get_slice("/",str(clip).get_slice_count("/")-1)==plain:
			animator.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
			animator.play(clip,0.3)
			return true
	return false
func compatible() -> bool:
	if not enabled or not Game.playing or Game.paused or Game.capture_in_progress or not is_instance_valid(Game.player): return false
	if not night.is_outdoors(Game.player.camera.global_position): return false
	var director: Node = night.facility.horror
	if director.tension>=4 or director.since_chase<20: return false
	if not active and (director.since_scare<25 or director.clock<director.active_until): return false
	if is_instance_valid(Game.enemy) and Game.enemy.state in [Game.enemy.State.CHASE,Game.enemy.State.ATTACK]: return false
	return true
func looking_up() -> bool:
	return -Game.player.camera.global_basis.z.y >= config.upward_threshold and night.sky_clear(Game.player.camera)
func moon_visible_direction() -> bool:
	return (-Game.player.camera.global_basis.z).dot(night.moon_direction)>0.82
func choose() -> FlyingShadowPattern:
	var choices: Array[FlyingShadowPattern] = []
	var total := 0.0
	for pattern in patterns:
		if pattern.id==last_id or pattern.weight<=0: continue
		if pattern.requires_moon and not moon_visible_direction(): continue
		choices.append(pattern)
		total += pattern.weight
	if choices.is_empty(): return patterns[1]
	var roll := rng.randf()*total
	for pattern in choices:
		roll -= pattern.weight
		if roll<=0: return pattern
	return choices[-1]
func begin(pattern: FlyingShadowPattern) -> bool:
	if active or cooldown>0 or exploration<config.minimum_exploration or not compatible(): return false
	if pattern.id != "unseen_cry" and not looking_up(): return false
	if pattern.requires_moon and not moon_visible_direction(): return false
	selected = pattern
	duration = clampf(pattern.duration,1,config.maximum_event_duration)
	last_id = pattern.id
	Game.last_flight_pattern = last_id
	active = true
	elapsed = 0
	vocal_played = false
	whoosh_played = false
	wing_clock = 0.6
	event_count += 1
	_build_path()
	entity.global_position = path[0]
	entity.show()
	play_clip(pattern.clip)
	var director: Node = night.facility.horror
	director.active_until = director.clock+duration+5
	director.since_scare = 0
	appeared.emit(pattern.id)
	return true
func _build_path() -> void:
	var camera: Camera3D = Game.player.camera
	var center := camera.global_position
	var forward := -camera.global_basis.z
	forward.y = maxf(0.22,forward.y)
	forward = forward.normalized()
	if selected.requires_moon: forward = night.moon_direction
	if selected.id=="unseen_cry": forward = Vector3(-forward.x,0.5,-forward.z).normalized()
	var right := Vector3.UP.cross(forward).normalized()
	var distance := selected.distance*rng.randf_range(0.92,1.08)
	var middle := center+forward*distance
	var width := distance*0.6
	var side := -1 if rng.randf()<0.5 else 1
	path = [middle-right*width*side+Vector3.UP*1.5,middle-right*width*0.35*side+Vector3.UP*4,middle+right*width*0.35*side+Vector3.UP*2,middle+right*width*side-Vector3.UP*9]
	if selected.id=="tree_rise":
		path[0].y = 5
		path[1].y = 27
		path[3].y = 6
	if selected.id=="near":
		for i in 4: path[i].y = maxf(path[i].y,17)
func point_at(amount: float) -> Vector3:
	var t := clampf(amount,0,1)
	return path[0].bezier_interpolate(path[1],path[2],path[3],t)
func _process(delta: float) -> void:
	if not Game.playing or Game.paused: return
	exploration += delta
	if active:
		if not compatible(): finish_event(); return
		elapsed += delta
		var progress := elapsed/duration
		entity.global_position = point_at(progress)
		var camera: Camera3D = Game.player.camera
		entity.look_at(Vector3(camera.global_position.x,entity.global_position.y,camera.global_position.z))
		entity.rotate_object_local(Vector3.FORWARD,sin(progress*TAU)*0.16)
		var fade := smoothstep(0,0.16,progress)*(1-smoothstep(0.78,1,progress))
		if selected.id=="unseen_cry": fade *= 1-smoothstep(0.22,0.38,progress)
		for material in materials: material.albedo_color.a = fade
		if selected.vocal and not vocal_played and progress>=selected.scream_time:
			vocal_played = true
			_play(scream,"scream",selected.id=="near")
		if selected.id=="near" and not whoosh_played and progress>=0.45:
			whoosh_played = true
			_play(whoosh,"whoosh",true)
		wing_clock -= delta
		if selected.wings and wing_clock<=0:
			wing_clock = 1.8 if selected.clip=="glide" else 1.25
			_play(wing,"wing",selected.id=="near")
		if progress>=1: finish_event()
		return
	cooldown = maxf(0,cooldown-delta)
	evaluation -= delta
	if evaluation>0: return
	evaluation = config.evaluation_interval
	if cooldown>0 or exploration<config.minimum_exploration or not compatible(): return
	# Looking skyward only gives a chance, never an obligatory spawn.
	if looking_up():
		if rng.randf()<config.chance: begin(choose())
	elif rng.randf()<config.chance*0.06:
		begin(patterns[-1])
func _play(audio: AudioStreamPlayer3D, bank: String, near: bool) -> void:
	var sample := rng.randi_range(0,2)
	if sample==last_sample: sample=(sample+1)%3
	last_sample = sample
	audio.stream = load("res://assets/audio/night/%s_%d.wav"%[bank,sample])
	audio.bus = "FlyingNear" if near else "FlyingDistant"
	audio.volume_db = (-17 if near else -23) if bank=="scream" else (-21 if near else -29)
	audio.pitch_scale = rng.randf_range(0.95,1.04)
	audio.play()
	Mic.output_guard = maxf(Mic.output_guard,0.3)
func finish_event() -> void:
	if not active: return
	active = false
	entity.hide()
	animator.stop()
	scream.stop()
	wing.stop()
	whoosh.stop()
	cooldown = rng.randf_range(config.minimum_interval,config.reference_maximum)
	vanished.emit(last_id)
	_quality()
