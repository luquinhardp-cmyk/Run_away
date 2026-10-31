class_name ModelLibrary
extends RefCounted
## Visual-only replacements. Physics hulls, IDs and controllers remain authoritative.
static var scenes: Dictionary = {}
static var extracted: Dictionary = {}
static func instantiate(id: String, low: bool = false) -> Node3D:
	var path := "res://assets/models/library/"+id+("_low" if low else "")+".glb"
	if not scenes.has(path): scenes[path] = load(path)
	var root: Node3D = scenes[path].instantiate()
	root.name = "Model_"+id
	root.set_meta("library_id",id)
	root.set_meta("library_low",low)
	for visual in root.find_children("*","MeshInstance3D",true,false):
		for i in visual.mesh.get_surface_count():
			var original: Material = visual.mesh.surface_get_material(i)
			var mat_name := str(original.resource_name) if original else "rusted_iron"
			if mat_name not in HorrorArt.NAMES: mat_name = "rusted_iron"
			if mat_name=="rusted_iron": mat_name = "weathered_iron"
			visual.set_surface_override_material(i,HorrorArt.surface(mat_name,false))
	return root
static func bounds(root: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for visual in root.find_children("*","MeshInstance3D",true,false):
		var local := Transform3D.IDENTITY
		var current: Node3D = visual
		while current != root:
			local = current.transform*local
			current = current.get_parent()
		var box: AABB = local*visual.get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result
static func fit(id: String, size: Vector3, parent: Node3D, offset := Vector3.ZERO, low: bool = false) -> Node3D:
	var model := instantiate(id,low)
	var box := bounds(model)
	var scale_to := size/box.size.max(Vector3.ONE*0.0001)
	model.scale = scale_to
	model.position = offset-box.get_center()*scale_to
	parent.add_child(model)
	return model
static func replace_interaction(item: StaticBody3D) -> bool:
	var id := ""
	match item.kind:
		"pickup": id = {"chave_oficina":"key","fusivel":"fuse","lanterna":"flashlight","cartao":"security_card"}.get(item.item_id,"")
		"generator": id = "diesel_generator"
		"fuse_panel": id = "fuse_panel"
		"radio": id = "radio"
		"alarm": id = "alarm"
		"door": id = "door_wood" if item.item_id in ["storage","workshop"] else "door_steel"
		"exit": id = "door_exit"
		"hide": id = "workbench" if item.item_id=="under_table" else "locker"
		"throw_pickup": id = "mechanical_part"
	if id.is_empty(): return false
	var anchor: MeshInstance3D = item.mesh
	var size: Vector3 = item.collider.shape.size
	var offset := Vector3.ZERO
	if id=="key": size=Vector3(0.22,0.014,0.10);offset.y=-0.05
	if id=="security_card": size=Vector3(0.21,0.008,0.135);offset.y=-0.032
	if id=="workbench": size=Vector3(1.8,1.0,0.9)
	anchor.mesh = null
	anchor.material_override = null
	# The original hinge operates along X thickness / Z width; source doors face -Z.
	if item.kind=="door":
		var pivot := Node3D.new()
		pivot.name = "DoorModelOrientation"
		pivot.rotation.y = -PI/2 if item.position.x>=0 else PI/2
		anchor.add_child(pivot)
		fit(id,Vector3(size.z,size.y,size.x),pivot,offset,Game.settings.quality<1)
		var frame := Node3D.new()
		frame.name = "FixedDoorFrame"
		frame.rotation.y = pivot.rotation.y
		item.add_child(frame)
		fit("door_frame",Vector3(1.93,2.72,0.27),frame,Vector3.ZERO,Game.settings.quality<1)
	else: fit(id,size,anchor,offset,Game.settings.quality<1)
	if id=="fuse_panel":
		item.installed_cartridge = Node3D.new()
		item.installed_cartridge.name = "InstalledFuse"
		item.installed_cartridge.position = Vector3(0,0.10,0.085)
		item.installed_cartridge.rotation.z = PI/2
		item.add_child(item.installed_cartridge)
		fit("fuse",Vector3(0.21,0.048,0.045),item.installed_cartridge)
		item._visual_state()
	item.set_meta("detailed_model",id)
	return true
static func replace_physical(prop: PhysicalProp3D) -> void:
	var id: String = {"tool":"wrench","fragile_crate":"crate","small_crate":"crate"}.get(prop.profile.id,prop.profile.id)
	if id not in ["wrench","crate","rock","bottle","bucket","chair","trolley","can"]: return
	for child in prop.mesh.get_children(): child.free()
	var size: Vector3 = prop.profile.size
	var offset := Vector3.ZERO
	if id=="chair": offset.y=0.01 # Existing seat-origin body extends -0.425..+0.57.
	if id=="trolley": offset.y=0.02
	fit(id,size,prop.mesh,offset,Game.settings.quality<1)
	prop.set_meta("detailed_model",id)
static func forest_mesh(variant: int, low: bool) -> Dictionary:
	var id: String = ["tree_dead","tree_broadleaf","tree_pine"][variant]
	var key := id+str(low)
	if extracted.has(key): return extracted[key]
	var root := instantiate(id,low)
	var bark := ArrayMesh.new()
	var leaves := ArrayMesh.new()
	for visual in root.find_children("*","MeshInstance3D",true,false):
		for i in visual.mesh.get_surface_count():
			var material: Material = visual.mesh.surface_get_material(i)
			var tool := SurfaceTool.new()
			tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			tool.append_from(visual.mesh,i,visual.transform)
			tool.commit(leaves if material.resource_name=="moss" else bark)
	root.free()
	extracted[key] = {"bark":bark,"leaves":leaves if leaves.get_surface_count()>0 else null}
	return extracted[key]
