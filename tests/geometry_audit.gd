extends Node
var records: Array = []
func _ready(): run.call_deferred()
func visit(node: Node):
	if node is MeshInstance3D and node.mesh != null:
		var surfaces: Array = []
		for i in node.mesh.get_surface_count():
			var mat: Material = node.get_active_material(i)
			var arrays: Array = node.mesh.surface_get_arrays(i)
			surfaces.append({"material":mat.resource_name if mat else "none","vertices":arrays[Mesh.ARRAY_VERTEX].size(),"indices":arrays[Mesh.ARRAY_INDEX].size() if arrays[Mesh.ARRAY_INDEX]!=null else 0,"uv_vertices":arrays[Mesh.ARRAY_TEX_UV].size() if arrays[Mesh.ARRAY_TEX_UV]!=null else 0})
		records.append({"path":str(node.get_path()),"class":node.mesh.get_class(),"resource":node.mesh.resource_path,"bounds":str(node.get_aabb()),"surfaces":surfaces})
	elif node is CollisionShape3D:
		records.append({"path":str(node.get_path()),"collision":node.shape.get_class() if node.shape else "none","disabled":node.disabled})
	elif node is MultiMeshInstance3D:
		records.append({"path":str(node.get_path()),"instances":node.multimesh.instance_count,"mesh":node.multimesh.mesh.get_class()})
	for child in node.get_children(): visit(child)
func run():
	Game.testing = true
	Game.record_results = false
	var main = preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	main.start(false,false)
	Game.player.set_physics_process(false)
	Game.enemy.set_physics_process(false)
	for i in 5: await get_tree().process_frame
	visit(main.level)
	var after := "--after" in OS.get_cmdline_user_args()
	Game.write_json("res://docs/geometry_inventory_after.json" if after else "res://docs/geometry_inventory_before.json",{"records":records,"note":"Generated runtime scene; primitives used as invisible collision hulls are intentionally retained."})
	print("AUDIT records ",records.size())
	main.to_menu()
	main.free()
	Sound.stop_all()
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()
