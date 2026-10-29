extends Node
signal emitted(event: Dictionary)

func emit_noise(origin: Node3D, intensity: float, kind: String, radius: float, duration: float = 0.3) -> void:
	if not is_instance_valid(origin) or not Game.playing or Game.paused: return
	emitted.emit({"origin": origin, "position": origin.global_position, "intensity": intensity, "kind": kind, "radius": radius, "duration": duration, "time": Time.get_ticks_msec() / 1000.0})

func perceived(event: Dictionary, listener: Node3D) -> float:
	var distance: float = listener.global_position.distance_to(event.position)
	if distance > event.radius: return 0.0
	var strength: float = event.intensity * pow(maxf(0.0, 1.0 - distance / event.radius), 1.4)
	var start := listener.global_position + Vector3.UP * 1.3
	var end: Vector3 = event.position + Vector3.UP
	var exclude: Array[RID] = [listener.get_rid()]
	# Up to three barriers; doors attenuate less than concrete.
	for i in 3:
		var ray := PhysicsRayQueryParameters3D.create(start, end, 1, exclude)
		var hit := listener.get_world_3d().direct_space_state.intersect_ray(ray)
		if hit.is_empty(): break
		var object: Node = hit.collider
		if object == event.origin: break
		strength *= 0.55 if object.has_meta("door") else 0.25
		exclude.append(object.get_rid())
	return strength
