extends Node
var owner_body: StaticBody3D
var leaf: AnimatableBody3D
var shape: CollisionShape3D
var progress := 0.0
var target := 0.0
var duration := 0.65
var jammed := false
var is_door := true
var side := 1.0
func _ready() -> void:
	owner_body = get_parent()
	is_door = owner_body.kind == "door"
	side = 1.0 if owner_body.position.x >= 0 else -1.0
	leaf = AnimatableBody3D.new()
	leaf.name = "HingedLeaf" if is_door else "SlidingDrawer"
	leaf.collision_layer = 1 | 8
	leaf.collision_mask = 2 | 4 | 16
	PhysicsSurfaces.attach(leaf, "metal" if is_door else "wood")
	leaf.set_meta("door", is_door)
	leaf.set_meta("interaction_owner", owner_body)
	owner_body.add_child(leaf)
	owner_body.mesh.reparent(leaf, false)
	shape = CollisionShape3D.new()
	shape.shape = owner_body.collider.shape.duplicate()
	leaf.add_child(shape)
	if is_door:
		owner_body.mesh.position = Vector3(0,0,0.9)
		shape.position.z = 0.9
	else:
		(shape.shape as BoxShape3D).size = Vector3(1.22,0.035,0.58)
		shape.position.y = -0.1
		owner_body.mesh.mesh = BoxMesh.new()
		owner_body.mesh.mesh.size = Vector3(1.22,0.035,0.58)
		owner_body.mesh.position.y = -0.1
		owner_body.mesh.material_override = HorrorArt.surface("damp_wood")
		for entry in [[Vector3(0,0.01,0.29),Vector3(1.26,0.23,0.035)], [Vector3(0,0.01,-0.29),Vector3(1.22,0.2,0.035)], [Vector3(-0.6,0.01,0),Vector3(0.035,0.2,0.56)], [Vector3(0.6,0.01,0),Vector3(0.035,0.2,0.56)]]: _drawer_panel(entry[0],entry[1])
		var paper := MeshInstance3D.new()
		var note := BoxMesh.new()
		note.size = Vector3(0.25,0.005,0.16)
		paper.mesh = note
		paper.material_override = HorrorArt.surface("torn_fabric")
		paper.position = Vector3(0.35,-0.075,0.12)
		leaf.add_child(paper)
		owner_body.collision_layer = 8
		owner_body.collider.disabled = true
		owner_body.add_to_group("physics_mechanisms")
		owner_body.open = Game.world.get("physics",{}).get(owner_body.item_id,{}).get("open",false)
	progress = 1.0 if owner_body.open else 0.0
	target = progress
	_pose(progress)
func _drawer_panel(at: Vector3, size: Vector3) -> void:
	var panel := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	panel.mesh = box
	panel.material_override = HorrorArt.surface("damp_wood")
	panel.position = at
	leaf.add_child(panel)
	var collider := CollisionShape3D.new()
	var hull := BoxShape3D.new()
	hull.size = size
	collider.shape = hull
	collider.position = at
	leaf.add_child(collider)
func set_state(value: bool, seconds := 0.65) -> void:
	target = 1.0 if value else 0.0
	duration = maxf(0.2,seconds)
	jammed = false
func _pose(amount: float) -> void:
	# One atomic transform: sync_to_physics defers setters, so separate position
	# and rotation assignments in the same tick can overwrite the hinge origin.
	leaf.transform = Transform3D(Basis(Vector3.UP,side * PI * 0.5 * amount),Vector3(0,0,-0.9)) if is_door else Transform3D(Basis.IDENTITY,Vector3(0,0,amount*0.36))
func _physics_process(delta: float) -> void:
	if not Game.playing or Game.paused or Game.capture_in_progress or is_equal_approx(progress,target): return
	var next := move_toward(progress,target,delta/duration)
	var prediction := Transform3D(Basis(Vector3.UP,side * PI * 0.5 * next),Vector3(0,0,-0.9)) if is_door else Transform3D(Basis.IDENTITY,Vector3(0,0,next*0.36))
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape.shape
	query.transform = owner_body.global_transform * prediction * shape.transform
	query.collision_mask = (2 | 4 | 16) if is_door else (2 | 4)
	query.exclude = [owner_body.get_rid(),leaf.get_rid()]
	var hits := leaf.get_world_3d().direct_space_state.intersect_shape(query,1)
	jammed = not hits.is_empty()
	if jammed: return
	progress = next
	_pose(progress)
