extends Node3D
## Presentation only: never moves the CharacterBody or reads the microphone.
var model: Node3D
var skeleton: Skeleton3D
var animator: AnimationPlayer
var low := false
var active_clip := ""
var motion_state := 0
var clip_names: Dictionary = {}
static var received_materials: Dictionary = {}
const STATE_CLIPS := {0: "patrol", 1: "breathe", 2: "listen", 3: "investigate", 4: "search", 5: "chase", 6: "attack", 7: "lost", 8: "return"}

func _ready() -> void:
	name = "EscutadorVisual"
	_build()
	Game.updated.connect(_quality)

func _quality() -> void:
	if low != (Game.settings.quality < 1): _build()

func _build() -> void:
	var capture_clip := active_clip if active_clip.begins_with("capture") else ""
	var capture_time := animator.current_animation_position if is_instance_valid(animator) and capture_clip != "" else 0.0
	if is_instance_valid(model): model.free()
	low = Game.settings.quality < 1
	var path := "res://assets/models/escutador_received_low.glb" if low else "res://assets/models/escutador_received.glb"
	model = load(path).instantiate()
	add_child(model)
	# GLB +Y (Blender forward) becomes Godot -Z, same as AI perception.
	skeleton = model.find_children("*", "Skeleton3D", true, false)[0]
	animator = model.find_children("*", "AnimationPlayer", true, false)[0]
	clip_names.clear()
	for name in animator.get_animation_list():
		var plain: String = str(name).get_slice("/", str(name).get_slice_count("/") - 1)
		clip_names[plain] = name
		if plain not in ["listen", "head_tilt", "attack", "capture", "RESET"] and not plain.begins_with("capture_"):
			animator.get_animation(name).loop_mode = Animation.LOOP_LINEAR
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		mesh.visibility_range_end = 42.0
		for index in mesh.mesh.get_surface_count():
			var imported: Material = mesh.mesh.surface_get_material(index)
			if imported == null: continue
			var name: String = imported.resource_name
			mesh.set_surface_override_material(index, _received_material(name, low))
	active_clip = ""
	set_motion(motion_state)
	if Game.capture_in_progress and capture_clip != "":
		play_capture(capture_clip)
		animator.seek(capture_time, true)

static func _received_material(name: String, reduced: bool) -> StandardMaterial3D:
	var key := name + str(reduced)
	if received_materials.has(key): return received_materials[key]
	var mat := StandardMaterial3D.new()
	mat.resource_name = name
	mat.roughness = 0.72
	if name in ["Received_Skin", "Received_Cartilage"]:
		var suffix := "_low" if reduced else ""
		var prefix := "res://assets/textures/escutador_received/skin_"
		mat.albedo_texture = load(prefix + "albedo" + suffix + ".png")
		mat.normal_texture = load(prefix + "normal" + suffix + ".png") if not reduced else null
		mat.normal_enabled = not reduced
		mat.normal_scale = 0.65
		mat.roughness_texture = load(prefix + "orm" + suffix + ".png")
		mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
		mat.roughness = 1.0
		mat.albedo_color = Color(.62,.64,.63) if name == "Received_Skin" else Color(.32,.30,.30)
	elif name == "Received_Keratin":
		mat.albedo_color = Color(.18,.16,.13)
		mat.roughness = .62
	else:
		mat.albedo_color = Color(.012,.008,.009)
		mat.roughness = 1.0
		mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS if reduced else BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	received_materials[key] = mat
	return mat

func set_motion(state: int) -> void:
	motion_state = state
	var clip: String = STATE_CLIPS.get(state, "idle")
	if not is_instance_valid(animator) or active_clip == clip: return
	active_clip = clip
	if clip_names.has(clip): animator.play(clip_names[clip], 0.16)

func advance_motion(speed: float) -> void:
	if motion_state == 4:
		var desired := "hide_search" if speed < .05 else "search"
		if active_clip != desired:
			active_clip = desired
			animator.play(clip_names[desired], .16)
	if active_clip in ["chase", "run"]: animator.speed_scale = clampf(speed / 3.35, 0.8, 1.15)
	elif active_clip in ["patrol", "walk", "investigate", "return", "search"]: animator.speed_scale = clampf(speed / 1.55, 0.65, 1.2)
	else: animator.speed_scale = 1.0

func play_capture(clip: String = "capture") -> void:
	animator.speed_scale = 1.0
	var chosen := clip if clip_names.has(clip) else ("capture" if clip_names.has("capture") else "attack")
	if active_clip == chosen: return
	active_clip = chosen
	if clip_names.has(chosen): animator.play(clip_names[chosen], 0.08)

func inspect_hide() -> void:
	if clip_names.has("hide_search"):
		active_clip = "hide_search"
		animator.play(clip_names[active_clip], 0.12)

func head_position() -> Vector3:
	var bone := skeleton.find_bone("head")
	if bone >= 0: return skeleton.global_transform * skeleton.get_bone_global_pose(bone).origin
	return global_position + Vector3.UP * 2.3
