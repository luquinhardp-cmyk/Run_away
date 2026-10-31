extends Node
signal emitted(event: Dictionary)
signal noise_created(event: WorldNoise)
var sequence := 0
var emitted_count := 0
var ray_count := 0

func emit_noise(origin: Node3D, intensity: float, kind: String, radius: float, duration: float = 0.3) -> void:
	if not is_instance_valid(origin) or not Game.playing or Game.paused: return
	var event := WorldNoise.new()
	sequence += 1
	emitted_count += 1
	event.event_id = sequence
	event.source_id = origin.get_instance_id()
	event.world_position = origin.global_position
	event.category = StringName(kind)
	event.loudness = clampf(intensity, 0, 2)
	event.duration = maxf(0.01, duration)
	event.timestamp = Time.get_ticks_msec() / 1000.0
	event.radius = maxf(0.01, radius)
	event.propagation_profile = &"mechanical" if kind in ["gerador", "radio", "alarme"] else &"air"
	noise_created.emit(event)
	emitted.emit(event.as_dictionary(origin))

func perceived(event: Dictionary, listener: Node3D) -> float:
	var distance: float = listener.global_position.distance_to(event.position)
	if distance > event.radius: return 0.0
	var strength: float = event.intensity * pow(maxf(0.0, 1.0 - distance / event.radius), 1.4)
	var start := listener.global_position + Vector3.UP * 1.3
	var end: Vector3 = event.position + Vector3.UP
	var exclude: Array[RID] = [listener.get_rid()]
	# Up to three barriers; doors attenuate less than concrete.
	for i in 3:
		ray_count += 1
		var ray := PhysicsRayQueryParameters3D.create(start, end, 1, exclude)
		var hit := listener.get_world_3d().direct_space_state.intersect_ray(ray)
		if hit.is_empty(): break
		var object: Node = hit.collider
		if object == event.origin: break
		strength *= 0.55 if object.has_meta("door") else 0.25
		exclude.append(object.get_rid())
	return strength
