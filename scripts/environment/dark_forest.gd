extends Node3D
var rng := RandomNumberGenerator.new()
var batches: Array[MultiMeshInstance3D] = []
var anchors: Array[Vector3] = []
var near_positions: Array[Vector3] = []
var tree_meshes: Array[Dictionary] = []
var leaf_material: ShaderMaterial
var tree_count := 0
func _ready() -> void:
	name = "DarkForest"
	rng.seed = int(Game.world.get("seed",1)) + 7301
	leaf_material = ShaderMaterial.new()
	leaf_material.shader = preload("res://shaders/forest_wind.gdshader")
	for variant in 3: tree_meshes.append(_tree(variant))
	_ground()
	# The close layer surrounds existing fences; no tree is placed in an escape route.
	for sector in 8:
		var close: Array[Transform3D] = []
		for i in 8:
			var angle := (sector + (i+0.3)/8.0) * TAU / 8.0
			var point := Vector3(-3+cos(angle)*30,0,-10+sin(angle)*40)
			close.append(_transform(point,0.9,1.35))
			near_positions.append(point)
			if i % 2 == 0: _trunk_collider(point)
		_layer(close,sector%3,"Near_%d"%sector,90)
		for ring in 2:
			var transforms: Array[Transform3D] = []
			for i in 36:
				var angle := (sector+rng.randf())*TAU/8
				var extra := rng.randf_range(3,14)+ring*16
				var point := Vector3(-3+cos(angle)*(32+extra),-0.03,-10+sin(angle)*(44+extra))
				transforms.append(_transform(point,0.85 if ring==0 else 0.9,1.55))
			_layer(transforms,(sector+ring)%3,"Mid_%d_%d"%[sector,ring],110)
	# Irregular dense approach trees closely frame the front yard.
	for side in [-1,1]:
		var transforms: Array[Transform3D] = []
		for i in 20:
			var point := Vector3(side*rng.randf_range(13.4,20),0,rng.randf_range(8,29))
			point.y = _terrain_height(point)
			transforms.append(_transform(point,0.8,1.3))
			if i < 5:
				near_positions.append(point)
				_trunk_collider(point)
			if i % 4 == 0: anchors.append(point+Vector3.UP*2)
		_layer(transforms,1 if side<0 else 2,"Front_%d"%side,90)
	_horizon()
	_boundaries()
	_rocks()
	Game.updated.connect(apply_quality)
	apply_quality()
func _transform(point: Vector3, low: float, high: float) -> Transform3D:
	var size := rng.randf_range(low,high)
	return Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3(size*rng.randf_range(0.8,1.1),size,size)),point)
func _append(tool: SurfaceTool, mesh: Mesh, transform: Transform3D) -> void:
	tool.append_from(mesh,0,transform)
func _ragged(mesh: Mesh, seed_value: float) -> ArrayMesh:
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in vertices.size():
		var p := vertices[i]
		var amount := 1+0.16*sin(p.x*4.3+p.z*3.7+seed_value)+0.11*cos(p.y*7+seed_value)
		p.x *= amount
		p.z *= amount
		p.y += sin(p.x*6+p.z*3+seed_value)*0.12
		vertices[i] = p
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var surface := ArrayMesh.new()
	surface.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var tool := SurfaceTool.new()
	tool.create_from(surface,0)
	tool.generate_normals()
	return tool.commit()
func _segment(tool: SurfaceTool, a: Vector3, b: Vector3, radius: float) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius*0.55
	mesh.bottom_radius = radius
	mesh.height = a.distance_to(b)
	mesh.radial_segments = 6
	mesh.rings = 1
	_append(tool,mesh,Transform3D(Basis(Quaternion(Vector3.UP,(b-a).normalized())),(a+b)*0.5))
func _tree(variant: int) -> Dictionary:
	var bark := SurfaceTool.new()
	bark.begin(Mesh.PRIMITIVE_TRIANGLES)
	var leaves := SurfaceTool.new()
	leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top := Vector3(0.35 if variant==0 else -0.2,10.0+variant,0.2)
	_segment(bark,Vector3.ZERO,top,0.34)
	for i in 7:
		var angle := i*2.4+variant
		var start := top*(0.32+i*0.075)
		var end := start+Vector3(cos(angle)*(2.5-i*0.18),1.1,sin(angle)*(2.5-i*0.18))
		_segment(bark,start,end,0.11-i*0.01)
		_segment(bark,end,end+Vector3(cos(angle+0.7)*0.7,0.8,sin(angle+0.7)*0.7),0.035)
		if variant==1 and i>1:
			var crown := SphereMesh.new()
			crown.radius = 1.15
			crown.height = 1.7
			crown.radial_segments = 10
			crown.rings = 4
			_append(leaves,_ragged(crown,float(i)),Transform3D(Basis.IDENTITY,end))
	if variant==2:
		for i in 5:
			var cone := CylinderMesh.new()
			cone.top_radius = 0.05
			cone.bottom_radius = 2.7-i*0.42
			cone.height = 2.8
			cone.radial_segments = 8
			cone.rings = 1
			_append(leaves,_ragged(cone,float(i)),Transform3D(Basis.IDENTITY,Vector3(sin(i*2.4)*0.15,4.5+i*1.5,cos(i*2.4)*0.17)))
	return {"bark":bark.commit(),"leaves":leaves.commit() if variant>0 else null}
func _layer(transforms: Array[Transform3D], variant: int, title: String, distance: float) -> void:
	var source: Dictionary = tree_meshes[variant]
	if title.begins_with("Front") or title in ["Near_0","Near_3"]: source = ModelLibrary.forest_mesh(variant,Game.settings.quality<2)
	for part in ["bark","leaves"]:
		if source[part] == null: continue
		var node := MultiMeshInstance3D.new()
		node.name = title+"_"+part
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = source[part]
		if title.begins_with("Mid") or title=="BoundaryShrubs": node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		multi.instance_count = transforms.size()
		for i in transforms.size(): multi.set_instance_transform(i,transforms[i])
		node.multimesh = multi
		if part=="leaves": node.material_override = leaf_material
		else:
			var material := HorrorArt.surface("rotten_wood").duplicate()
			material.albedo_color = Color(0.22,0.25,0.22)
			node.material_override = material
		node.visibility_range_end = distance
		node.set_meta("layer_type",title)
		add_child(node)
		batches.append(node)
	tree_count += transforms.size()
func _trunk_collider(point: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = point+Vector3.UP*2
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.35
	shape.height = 4
	collision.shape = shape
	body.add_child(collision)
	PhysicsSurfaces.attach(body,"wood")
	add_child(body)
func _ground() -> void:
	var ground := MeshInstance3D.new()
	ground.name = "UndulatingForestGround"
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Leave the building, ramp and basement cut-out untouched.
	for rect in [Rect2(-100,-120,76,220),Rect2(16,-120,84,220),Rect2(-24,-120,40,75),Rect2(-24,25,40,75),Rect2(-24,22,40,3),Rect2(-24,2,13,20),Rect2(11,2,5,20),Rect2(-24,-8,14,10)]:
		var nx := maxi(1,ceili(rect.size.x/3))
		var nz := maxi(1,ceili(rect.size.y/3))
		for ix in nx:
			for iz in nz:
				var a := Vector3(rect.position.x+rect.size.x*ix/nx,0,rect.position.y+rect.size.y*iz/nz)
				var b := a+Vector3(rect.size.x/nx,0,0)
				var c := a+Vector3(0,0,rect.size.y/nz)
				var d := b+Vector3(0,0,rect.size.y/nz)
				for point in [a,b,c,b,d,c]:
					point.y = _terrain_height(point)
					tool.set_uv(Vector2(point.x,point.z)*0.6)
					tool.add_vertex(point)
	tool.generate_normals()
	tool.generate_tangents()
	ground.mesh = tool.commit()
	var dirt := HorrorArt.surface("mud_leaves").duplicate()
	dirt.albedo_color = Color(0.2,0.23,0.2)
	ground.material_override = dirt
	add_child(ground)
func _terrain_height(point: Vector3) -> float:
	# No elevation changes in the playable yard, basement, ramp or objective routes.
	var edge := maxf(maxf(-12-point.x,point.x-16),maxf(-45-point.z,point.z-25))
	return -0.07+clampf(edge/8,0,1)*absf(sin(point.x*0.29)*sin(point.z*0.23))*0.35
func _rocks() -> void:
	var details := Node3D.new()
	add_child(details)
	for i in 28:
		var point := Vector3((-1 if i%2 else 1)*rng.randf_range(11.8,25),0,rng.randf_range(3,27))
		point.y = _terrain_height(point)
		var height := rng.randf_range(0.14,0.52)
		point.y += height*0.45
		var model := ModelLibrary.fit("rock",Vector3(height*1.7,height,height*1.3),details,point,true)
		model.rotation.y = rng.randf()*TAU
	HorrorArt.merge_static(details,self)
func _horizon() -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 256:
		var a := i*TAU/256
		var b := (i+1)*TAU/256
		var p := Vector3(-3+cos(a)*82,0,-10+sin(a)*102)
		var q := Vector3(-3+cos(b)*82,0,-10+sin(b)*102)
		var top := 12+rng.randf_range(0,8)
		for v in [p,q,p+Vector3.UP*top,q,q+Vector3.UP*(top+1),p+Vector3.UP*top]: tool.add_vertex(v)
	tool.generate_normals()
	var node := MeshInstance3D.new()
	node.name = "ContinuousForestHorizon"
	node.mesh = tool.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.003,0.006,0.005)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	node.material_override = mat
	add_child(node)
func _boundaries() -> void:
	# Dense shrubs and fallen trunks visually explain the existing fence boundaries.
	var transforms: Array[Transform3D] = []
	for side in [-1,1]:
		for i in 18: transforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1.1,0.22,0.8)),Vector3(side*11.5,0,3+i*1.1)))
	for i in 20: transforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.9,0.2,0.8)),Vector3(-11+i*1.15,0,22)))
	_layer(transforms,1,"BoundaryShrubs",70)
	var logs := SurfaceTool.new()
	logs.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in [-1,1]:
		for z in [6,13,20]: _segment(logs,Vector3(side*11.0,0.25,z),Vector3(side*11.6,0.5,z+2.6),0.25)
	var node := MeshInstance3D.new()
	node.mesh = logs.commit()
	node.material_override = HorrorArt.surface("rotten_wood")
	add_child(node)
func apply_quality() -> void:
	var quality := int(Game.settings.quality)
	for node in batches:
		var title := str(node.get_meta("layer_type"))
		var secondary := title.begins_with("Mid")
		node.multimesh.visible_instance_count = int(node.multimesh.instance_count * ([0.42,0.72,1.0][quality] if secondary else 1.0))
		var custom := float(Game.settings.get("vegetation_distance",0.0))
		node.visibility_range_end = (custom if custom>0 else [70,95,115][quality]) if secondary else 90
	leaf_material.set_shader_parameter("wind_strength",[0.02,0.05,0.07][quality])
