extends Node
var rows: Array = []
func _ready() -> void:
	run.call_deferred()
func visit(node: Node, source: String) -> void:
	if not node.scene_file_path.is_empty(): source = node.scene_file_path
	if node is MeshInstance3D or node is CollisionObject3D or node is CollisionShape3D or node is Joint3D:
		var mats: Array = []
		var textures: Array = []
		if node is MeshInstance3D and node.mesh:
			for i in node.mesh.get_surface_count():
				var mat: Material = node.get_active_material(i)
				if mat:
					mats.append(mat.resource_name if mat.resource_name != "" else mat.resource_path)
					if mat is BaseMaterial3D:
						for tex in [mat.albedo_texture, mat.normal_texture, mat.roughness_texture]:
							if tex: textures.append(tex.resource_path)
		var kind: String = str(node.get("kind")) if node.get("kind") != null else ""
		var category := "F" if kind != "" else ("B" if node is RigidBody3D else "A")
		if kind in ["door", "drawer"]: category = "E"
		if kind in ["hide", "generator"]: category = "D"
		var mass_value: float = node.mass if node is RigidBody3D else (180 if category == "D" else 0)
		if node is PhysicalProp3D: category = node.profile.category
		rows.append({"id": str(node.get_path()), "name": node.name, "source_scene": source, "author_script": node.get_script().resource_path if node.get_script() else "", "type": node.get_class(), "kind": kind, "category": category, "materials": mats, "textures": textures, "collision_layer": node.collision_layer if node is CollisionObject3D else 0, "shape": node.shape.get_class() if node is CollisionShape3D and node.shape else "", "needs_gravity": node is RigidBody3D, "needs_movement": category in ["B", "C", "E"], "interaction": kind, "gameplay_mass_kg": mass_value, "sounds": "material impact" if category == "B" else ("mechanism" if category == "E" else "none unless activated"), "performance": "active solver" if category == "B" else "static/batched or controlled", "position": str(node.global_position)})
	for child in node.get_children(): visit(child, source)
func run() -> void:
	Game.testing = true
	Game.record_results = false
	Game.settings.seed = 70421
	var main := preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	main.start(false, false)
	for i in 4: await get_tree().physics_frame
	visit(main, "res://scenes/main/main.tscn")
	var label := OS.get_environment("ECOS_INVENTORY_PHASE")
	if label == "": label = "before"
	Game.write_json("res://docs/INVENTARIO_FISICA_" + label + ".json", {"seed":70421, "objects":rows, "note":"Runtime generated scene inventory; source scripts identify procedural origin. Mesh-only decoration remains static; gameplay props are individually classified in the physics guide."})
	print("INVENTORY ", label, " ", rows.size())
	main.to_menu()
	main.free()
	Sound.stop_all()
	await get_tree().create_timer(0.6).timeout
	get_tree().quit()
