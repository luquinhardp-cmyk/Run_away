class_name WorldSign3D
extends Node3D
@export var sign_id := ""
@export_multiline var text := ""
@export_enum("metal", "wood", "emergency", "danger", "map", "paper") var sign_type := "metal"
@export var dimensions := Vector2(1.7, 0.38)
@export_range(0, 1) var wear := 0.65
@export var illuminated := false
@export var language := "pt-BR"
@export var reading_distance := 12.0
@export var post_mounted := false
@export var surface: Material
var lettering: Label3D
var panel: MeshInstance3D

func _ready() -> void:
	add_to_group("world_signs")
	panel = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(dimensions.x, dimensions.y, 0.045)
	panel.mesh = box
	var mat: Material = surface
	if mat == null:
		mat = HorrorArt.surface("rotten_wood" if sign_type == "wood" else ("torn_fabric" if sign_type == "paper" else "rusted_iron")).duplicate()
		mat.albedo_color = Color("607459") if sign_type == "emergency" else (Color("99865a") if sign_type == "danger" else Color("55554a"))
		mat.albedo_color = mat.albedo_color.lerp(Color("463a2a"), wear * 0.4)
		mat.roughness = lerpf(0.5, 0.95, wear)
	panel.material_override = mat
	panel.visibility_range_end = reading_distance + 6
	add_child(panel)
	lettering = Label3D.new()
	lettering.text = text
	lettering.font_size = 48
	var longest := 1
	for line in text.split("\n"): longest = maxi(longest, line.length())
	lettering.pixel_size = minf((dimensions.x - 0.12) / (longest * 31.0), (dimensions.y - 0.06) / (text.count("\n") + 1) / 60.0)
	lettering.position.z = 0.027
	lettering.modulate = Color("e3d9b5")
	lettering.modulate = lettering.modulate.lerp(Color("9e977c"), wear * 0.35)
	lettering.outline_size = 2
	lettering.shaded = not illuminated
	lettering.no_depth_test = false
	lettering.double_sided = false
	lettering.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	lettering.visibility_range_end = reading_distance
	add_child(lettering)
	# Four rivets in one instanced draw, plus an optional physical post.
	var rivets := MultiMeshInstance3D.new()
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	var screw := BoxMesh.new()
	screw.size = Vector3(0.025, 0.025, 0.012)
	screw.material = HorrorArt.solid(Color("302d23"))
	multi.mesh = screw
	multi.instance_count = 4
	for i in 4:
		multi.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3((dimensions.x * 0.5 - 0.045) * (-1 if i < 2 else 1), (dimensions.y * 0.5 - 0.045) * (-1 if i % 2 == 0 else 1), 0.03)))
	rivets.multimesh = multi
	rivets.visibility_range_end = reading_distance + 4
	add_child(rivets)
	if post_mounted:
		var post := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.08, maxf(0.5, position.y), 0.08)
		post.mesh = mesh
		post.material_override = HorrorArt.surface("rotten_wood")
		post.position = Vector3(0, -position.y * 0.5, -0.06)
		add_child(post)
