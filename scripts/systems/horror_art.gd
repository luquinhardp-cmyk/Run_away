class_name HorrorArt
extends RefCounted
## Shared PBR resources. ORM = red AO, green roughness, blue metallic.
static var cache: Dictionary = {}
static var quality := 1
const NAMES := ["aged_concrete", "damp_concrete", "cracked_floor", "peeling_plaster", "rusted_iron", "rotten_wood", "mud_leaves", "torn_fabric", "organic_residue", "creature_skin"]

static func surface(name: String, world_space: bool = true) -> StandardMaterial3D:
	var key := name + ("_world" if world_space else "_uv")
	if cache.has(key): return cache[key]
	var mat: StandardMaterial3D = load("res://assets/materials/" + name + ".tres").duplicate()
	mat.resource_name = name
	mat.set_meta("pbr_name", name)
	mat.uv1_triplanar = world_space
	mat.uv1_world_triplanar = world_space
	mat.uv1_scale = Vector3.ONE * 0.6 if world_space else Vector3.ONE
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mat.roughness = 1.0
	mat.metallic = 1.0
	mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	mat.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
	mat.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	mat.normal_scale = 0.65 if name == "creature_skin" else 0.8
	cache[key] = mat
	_update(mat)
	return mat

static func set_quality(value: int) -> void:
	quality = clampi(value, 0, 2)
	for mat in cache.values():
		if mat.has_meta("pbr_name"): _update(mat)

static func _update(mat: StandardMaterial3D) -> void:
	var name: String = mat.get_meta("pbr_name")
	var suffix := "_low" if quality == 0 else ""
	var prefix := "res://assets/textures/pbr/" + name
	mat.albedo_texture = load(prefix + "_albedo" + suffix + ".png")
	mat.normal_texture = load(prefix + "_normal" + suffix + ".png")
	var orm: Texture2D = load(prefix + "_orm" + suffix + ".png")
	mat.roughness_texture = orm
	mat.metallic_texture = orm
	mat.ao_texture = orm
	mat.normal_enabled = quality > 0
	mat.ao_enabled = quality > 0
	mat.ao_light_affect = 0.35

static func solid(color: Color, emission: float = 0.0) -> StandardMaterial3D:
	var key := str(color) + str(emission)
	if cache.has(key): return cache[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	if emission > 0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission
	cache[key] = mat
	return mat

static func merge_static(root: Node3D, output: Node3D) -> int:
	# Visual meshes merge per material; physics bodies remain independent.
	var buckets: Dictionary = {}
	for node in root.find_children("*", "MeshInstance3D", true, false):
		if node.get_meta("keep_dynamic", false) or node.mesh == null or not node.is_visible_in_tree(): continue
		for surface_id in node.mesh.get_surface_count():
			var mat: Material = node.get_active_material(surface_id)
			if mat == null: continue
			# Bound each batch spatially so rooms retain culling and local light selection.
			var point: Vector3 = node.global_position
			var key := "%s_%s_%s" % [mat.get_instance_id(), floori(point.x / 8.0), floori(point.z / 8.0)]
			if not buckets.has(key):
				var tool := SurfaceTool.new()
				tool.begin(Mesh.PRIMITIVE_TRIANGLES)
				tool.set_material(mat)
				buckets[key] = tool
			var transform: Transform3D = output.global_transform.affine_inverse() * node.global_transform
			buckets[key].append_from(node.mesh, surface_id, transform)
		node.queue_free()
	for key in buckets:
		var merged := MeshInstance3D.new()
		merged.name = "StaticBatch_%s" % key
		merged.mesh = buckets[key].commit()
		output.add_child(merged)
	return buckets.size()
