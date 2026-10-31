class_name PhysicalProp3D
extends RigidBody3D
@export var profile: ObjectPhysicsProfile
@export var item_id := ""
@export var persistent := true
@export var secondary := false
var kind := "physical"
var interaction_distance := 2.5
var mesh: Node3D
var impact_audio: PhysicsImpactAudio
var held_by: Node
var previous_velocity := Vector3.ZERO
var age := 0.0
var broken := false
var thrown := false
var spawn_position := Vector3.ZERO
var budget_frozen := false
var noise_kind := "impacto_fisico"
func _ready() -> void:
	if profile == null: profile = load("res://resources/physics/objects/can.tres")
	name = "Prop_" + item_id if item_id != "" else "PhysicalProp"
	add_to_group("physical_props")
	set_meta("impact_owner", true)
	set_meta("physical_category", profile.category)
	mass = profile.mass_kg
	collision_layer = 16
	collision_mask = 1 | 2 | 4 | 16
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 8
	linear_damp = profile.damping
	angular_damp = 0.35
	PhysicsSurfaces.attach(self, profile.surface)
	mesh = Node3D.new()
	mesh.name = "Visual"
	add_child(mesh)
	_build_shape()
	impact_audio = PhysicsImpactAudio.new()
	impact_audio.material_id = profile.surface
	add_child(impact_audio)
	spawn_position = position
	var saved: Dictionary = Game.world.get("physics", {}).get(item_id, {})
	if persistent and not saved.is_empty():
		var decoded := decode_snapshot(saved)
		if not decoded.is_empty():
			position = decoded.position
			rotation = decoded.rotation
			sleeping = true
			if saved.get("broken", false): _restore_broken()
func _part(pos: Vector3, size: Vector3, mat: Material) -> void:
	var visual := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	visual.mesh = cube
	visual.material_override = mat
	visual.position = pos
	mesh.add_child(visual)
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position = pos
	add_child(collider)
func _build_shape() -> void:
	var mat := HorrorArt.surface(profile.pbr)
	var size := profile.size
	if profile.shape in ["chair", "trolley"]:
		if profile.shape == "chair":
			_part(Vector3(0, 0.05, 0), Vector3(size.x, 0.08, size.z), mat)
			_part(Vector3(0, 0.32, size.z * 0.4), Vector3(size.x, 0.5, 0.06), HorrorArt.surface("old_upholstery"))
			for x in [-1, 1]:
				for z in [-1, 1]: _part(Vector3(x * size.x * 0.4, -0.2, z * size.z * 0.4), Vector3(0.05, 0.45, 0.05), mat)
		else:
			for y in [-0.28, 0.23]: _part(Vector3(0, y, 0), Vector3(size.x, 0.05, size.z), mat)
			for x in [-1, 1]:
				for z in [-1, 1]: _part(Vector3(x * size.x * 0.43, -0.02, z * size.z * 0.4), Vector3(0.05, 0.7, 0.05), mat)
		return
	var visual := MeshInstance3D.new()
	var shape: Shape3D
	if profile.shape == "sphere":
		var sphere := SphereMesh.new()
		sphere.radius = size.x * 0.5
		sphere.height = size.x
		visual.mesh = sphere
		var collision := SphereShape3D.new()
		collision.radius = sphere.radius
		shape = collision
	elif profile.shape in ["cylinder", "bottle"]:
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = size.x * (0.25 if profile.shape == "bottle" else 0.5)
		cylinder.bottom_radius = size.x * 0.5
		cylinder.height = size.y
		cylinder.radial_segments = 12
		visual.mesh = cylinder
		var collision := CylinderShape3D.new()
		collision.radius = size.x * 0.5
		collision.height = size.y
		shape = collision
	else:
		var cube := BoxMesh.new()
		cube.size = size
		visual.mesh = cube
		var collision := BoxShape3D.new()
		collision.size = size
		shape = collision
	visual.material_override = mat
	mesh.add_child(visual)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	add_child(collider)
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not is_instance_valid(impact_audio) or broken: return
	impact_audio.advance(state.step)
	for i in state.get_contact_count():
		var other := state.get_contact_collider_object(i)
		var normal := state.transform.basis * state.get_contact_local_normal(i)
		var relative := previous_velocity - state.get_contact_collider_velocity_at_position(i)
		var speed := absf(relative.dot(normal))
		if impact_audio.report(state.get_contact_collider_position(i), other, speed, mass, noise_kind):
			if profile.break_speed > 0 and speed >= profile.break_speed: break_apart.call_deferred()
	previous_velocity = state.linear_velocity
func _physics_process(delta: float) -> void:
	age += delta
	if held_by != null and (not is_instance_valid(held_by) or Game.capture_in_progress): held_by = null
	if thrown and (age > 20 or position.y < -7): queue_free()
	if persistent and position.y < -6: # Remove failed optional props, never mission items.
		_restore_broken()
func get_prompt() -> String:
	return profile.title + (" · R / segurar" if profile.can_hold and not broken else " · R / arrastar · E / empurrar")
func interact(player: CharacterBody3D) -> void:
	if profile.can_hold: player.manipulator.begin(self)
	elif profile.can_push: nudge(-player.camera.global_basis.z, mass * 1.2)
func nudge(direction: Vector3, strength: float) -> void:
	if not profile.can_push or broken or freeze: return
	sleeping = false
	apply_central_impulse(direction.normalized() * minf(strength, mass * 1.5))
func break_apart() -> void:
	if broken: return
	_restore_broken()
	var holder := get_parent()
	for i in 3:
		if get_tree().get_nodes_in_group("physics_fragments").size() >= 12: break
		var fragment := MeshInstance3D.new()
		fragment.add_to_group("physics_fragments")
		var cube := BoxMesh.new()
		cube.size = Vector3(0.07, 0.02, 0.05)
		fragment.mesh = cube
		fragment.material_override = HorrorArt.surface(profile.pbr)
		holder.add_child(fragment)
		fragment.global_position = global_position + Vector3((i - 1) * 0.1, -profile.size.y * 0.4, 0.04 * i)
		var ray := PhysicsRayQueryParameters3D.create(fragment.global_position + Vector3.UP * 0.1, fragment.global_position + Vector3.DOWN * 6, 1, [get_rid()])
		var floor_hit := get_world_3d().direct_space_state.intersect_ray(ray)
		if not floor_hit.is_empty(): fragment.global_position.y = floor_hit.position.y + 0.015
		holder.get_tree().create_timer(8).timeout.connect(fragment.queue_free)
func _restore_broken() -> void:
	broken = true
	freeze = true
	collision_layer = 0
	collision_mask = 0
	mesh.hide()
	held_by = null
func snapshot() -> Dictionary:
	var point := position if position.y >= -6 else spawn_position
	return {"t":"%.2f,%.2f,%.2f;%.2f,%.2f,%.2f" % [point.x,point.y,point.z,rotation.x,rotation.y,rotation.z], "broken":broken}

static func decode_snapshot(saved: Dictionary) -> Dictionary:
	var coordinates: Array = []
	if saved.get("t") is String:
		var halves: PackedStringArray = saved.t.split(";")
		if halves.size() != 2: return {}
		for half in halves:
			var values := half.split(",")
			if values.size() != 3: return {}
			for value in values:
				if not value.is_valid_float(): return {}
				coordinates.append(float(value))
	elif saved.get("p") is Array and saved.get("r") is Array:
		if saved.p.size() != 3 or saved.r.size() != 3: return {}
		coordinates = saved.p + saved.r # Local migration from development snapshots.
	else: return {}
	for i in 6:
		if not (coordinates[i] is float or coordinates[i] is int) or not is_finite(float(coordinates[i])) or absf(float(coordinates[i])) > (50 if i < 3 else 3.15): return {}
	return {"position":Vector3(coordinates[0],coordinates[1],coordinates[2]),"rotation":Vector3(coordinates[3],coordinates[4],coordinates[5])}
