extends Node
var passed := 0
var failed := 0
var main: Node
func check(ok: bool,title: String):
	if ok: passed+=1
	else: failed+=1;push_error(title)
	print("PASS " if ok else "FAIL ",title)
func _ready(): run.call_deferred()
func run():
	Game.testing = true
	Game.record_results = false
	Game.settings.quality = 1
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/library/manifest.json"))
	check(manifest.models.size()==37,"37 authored models with two geometry versions")
	for id in manifest.models:
		var model_counts: Array[int] = []
		for low in [false,true]:
			var root := ModelLibrary.instantiate(id,low)
			var valid := true
			var uv_triangles := 0
			var triangles := 0
			for visual in root.find_children("*","MeshInstance3D",true,false):
				for surface in visual.mesh.get_surface_count():
					var arrays: Array = visual.mesh.surface_get_arrays(surface)
					var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
					var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
					var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
					var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
					valid = valid and uv.size()==vertices.size() and normals.size()==vertices.size()
					for i in range(0,indices.size(),3):
						triangles+=1
						if valid:
							var a := uv[indices[i+1]]-uv[indices[i]]
							var b := uv[indices[i+2]]-uv[indices[i]]
							if absf(a.cross(b))>0.000000001: uv_triangles+=1
					var mat: StandardMaterial3D = visual.get_active_material(surface)
					valid = valid and mat.albedo_texture!=null and not mat.uv1_triplanar
			check(valid and triangles>0 and uv_triangles>=triangles*.95,"imported normals, mapped PBR and nondegenerate UVs "+id+str(low))
			check(ModelLibrary.bounds(root).size.is_finite() and ModelLibrary.bounds(root).position.is_finite() and ModelLibrary.bounds(root).size.length()>0,"finite dimensions "+id+str(low))
			model_counts.append(triangles)
			root.free()
		check(model_counts[1]<model_counts[0],"lower-detail geometry reduces triangles "+id)
	main = preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	main.start(false,false)
	Game.player.set_physics_process(false)
	Game.player.set_process_unhandled_input(false)
	Game.enemy.set_physics_process(false)
	main.level.events.enabled = false
	main.level.horror.enabled = false
	main.level.get_node("BloodMoonNight").flying.enabled = false
	for i in 8: await get_tree().physics_frame
	check(is_equal_approx(Game.player.camera.position.y,1.56),"FPS camera keeps 1.56 metre eye height")
	for id in ["chave_oficina","fusivel","cartao","generator","fuse_panel","radio","alarm","under_table","exit"]:
		var item = main.level.find_interaction(id)
		check(item!=null and item.has_meta("detailed_model") and item.collider.shape is BoxShape3D,"model integrated with existing interaction hull "+id)
	var key = main.level.find_interaction("chave_oficina")
	var key_model = key.mesh.get_child(0)
	var key_bounds: AABB = key_model.transform*ModelLibrary.bounds(key_model)
	check(absf(key_bounds.size.y-.014)<.001 and absf(key_bounds.position.y+.057)<.001,"key has physical thickness and rests on support")
	var panel = main.level.find_interaction("fuse_panel")
	check(not panel.installed_cartridge.visible,"empty central fuse carrier before insertion")
	Game.world.fuse_installed = true
	Game.updated.emit()
	check(panel.installed_cartridge.visible,"installed fuse appears from saved gameplay state")
	Game.world.fuse_installed = false
	for door in get_tree().get_nodes_in_group("doors"):
		var frame = door.get_node("FixedDoorFrame")
		var previous: Transform3D = frame.global_transform
		var hinge = door.mechanism
		var leaf_before: Transform3D = hinge.leaf.global_transform
		hinge._pose(1)
		for i in 3: await get_tree().physics_frame
		check(frame.global_transform==previous and hinge.leaf.global_transform!=leaf_before,"hinge rotates leaf without moving frame "+door.item_id)
		check(hinge.leaf.is_ancestor_of(door.mesh),"visual remains on physical leaf "+door.item_id)
		hinge._pose(0)
		for i in 3: await get_tree().physics_frame
	var drawer = main.level.find_interaction("drawer")
	check(drawer.mechanism.leaf.find_children("Model_drawer_handle","Node3D",true,false).size()==1,"drawer pull travels with sliding body")
	for prop in get_tree().get_nodes_in_group("physical_props"):
		check((prop.has_meta("detailed_model") or prop.profile.id=="rubber_ball") and is_equal_approx(prop.mass,prop.profile.mass_kg) and prop.continuous_cd and prop.impact_audio!=null,"visual replacement preserves mass CCD and sound "+prop.item_id)
	var state: PhysicsDirectSpaceState3D = main.level.get_world_3d().direct_space_state
	var aperture := PhysicsRayQueryParameters3D.create(Vector3(-8,1.9,.25),Vector3(-11.5,1.9,.25),1)
	check(state.intersect_ray(aperture).is_empty(),"real window aperture has no opaque full-wall collision")
	var grille := PhysicsRayQueryParameters3D.create(Vector3(-8,1.9,0),Vector3(-11.5,1.9,0),1)
	check(not state.intersect_ray(grille).is_empty(),"visible window grille has matching collision")
	var forest = main.level.get_node("BloodMoonNight").forest
	check(ModelLibrary.extracted.size()>=3,"three refined tree variants feed instanced forest")
	var terrain: MeshInstance3D = forest.get_node("UndulatingForestGround")
	var terrain_arrays: Array = terrain.mesh.surface_get_arrays(0)
	check(terrain_arrays[Mesh.ARRAY_NORMAL][0].y>0.8,"terrain triangles face upward instead of disappearing from above")
	check(forest.tree_count==736,"forest population and surrounding horizon preserved")
	check(forest._terrain_height(Vector3(0,0,12))==-.07,"playable central route elevation preserved")
	check(forest._terrain_height(Vector3(22,0,13))>-.07,"terrain undulates beyond playable routes")
	Game.write_json("res://docs/review/geometry/test_results.json",{"geometry_passed":passed,"geometry_failed":failed,"android_hardware":false})
	main.to_menu()
	main.free()
	Sound.stop_all()
	await get_tree().create_timer(.3).timeout
	print("GEOMETRY RESULT ",passed," passed; ",failed," failed")
	get_tree().quit(0 if failed==0 else 1)
