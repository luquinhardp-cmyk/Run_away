extends Node
var player: CharacterBody3D
var held: PhysicalProp3D
var held_time := 0.0
var stuck_time := 0.0
var maximum_mass := 3.0
var maximum_distance := 2.5
var hold_distance := 1.35
var force_limit := 45.0
var dragging := false
func begin_drag(object: PhysicalProp3D) -> bool:
	if object.profile.category != "C" or object.mass > 20 or not object.profile.can_push: return false
	return begin(object, true)
func _ready() -> void:
	player = get_parent()
func begin(object: PhysicalProp3D, as_drag := false) -> bool:
	if is_instance_valid(held): release(); return false
	if not Game.playing or Game.paused or Game.capture_in_progress or player.hidden: return false
	if object.broken or object.freeze or object.held_by != null: return false
	if as_drag:
		if object.profile.category != "C" or object.mass > 20 or not object.profile.can_push: return false
	elif not object.profile.can_hold or object.mass > maximum_mass: return false
	if player.camera.global_position.distance_to(object.global_position) > maximum_distance: return false
	var ray := PhysicsRayQueryParameters3D.create(player.camera.global_position, object.global_position, 1 | 16, [player.get_rid()])
	var hit := player.get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty() and hit.collider != object: return false
	held = object
	dragging = as_drag
	object.held_by = self
	object.sleeping = false
	object.linear_damp = 3
	held_time = 0
	stuck_time = 0
	return true
func release(throw_held := false) -> PhysicalProp3D:
	if not is_instance_valid(held): held = null; return null
	var object := held
	held = null
	dragging = false
	object.held_by = null
	object.linear_damp = object.profile.damping
	if throw_held and object.profile.can_throw and not Game.capture_in_progress:
		var direction: Vector3 = -player.camera.global_basis.z
		object.linear_velocity = object.linear_velocity.limit_length(2)
		object.apply_central_impulse((direction * minf(8.0, 5.0 / sqrt(object.mass)) + Vector3.UP * 0.7) * object.mass)
		object.apply_torque_impulse(player.camera.global_basis.x * object.mass * 0.2)
	return object
func _physics_process(delta: float) -> void:
	if not is_instance_valid(held): held = null; return
	if Game.capture_in_progress or not Game.playing or Game.paused or player.hidden or held.broken: release(); return
	held_time += delta
	var camera: Camera3D = player.camera
	var target := camera.global_position - camera.global_basis.z * hold_distance
	if dragging: target.y = held.global_position.y
	# The spring keeps native collisions; a swept volume limits the target near walls.
	var query := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = held.profile.size.length() * 0.5 + 0.04
	query.shape = sphere
	query.transform = Transform3D(Basis.IDENTITY, camera.global_position)
	query.motion = target - camera.global_position
	query.collision_mask = 1 | 16
	query.exclude = [player.get_rid(), held.get_rid()]
	var fractions := player.get_world_3d().direct_space_state.cast_motion(query)
	if fractions[0] < 1: target = camera.global_position + query.motion * maxf(0, fractions[0] - 0.08)
	var error := target - held.global_position
	if error.length() > maximum_distance: release(); return
	if error.length() > 0.7 and held.linear_velocity.length() < 0.25: stuck_time += delta
	else: stuck_time = maxf(0, stuck_time - delta)
	if stuck_time > 0.8: release(); return
	var force := (error * 30 - held.linear_velocity * 7 + (Vector3.ZERO if dragging else Vector3.UP * 9.8)) * held.mass
	if dragging: force.y = 0
	held.apply_central_force(force.limit_length(95 if dragging else force_limit))
	held.angular_velocity *= maxf(0, 1 - delta * 4)
func _exit_tree() -> void:
	release()
