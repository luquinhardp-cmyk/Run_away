class_name CreaturePerception
extends RefCounted
var ray_count := 0

func visual_strength(creature: CharacterBody3D, player: CharacterBody3D, profile: CreatureProfile) -> float:
	if not is_instance_valid(player): return 0.0
	if player.hidden and is_instance_valid(player.hide_spot) and player.hide_spot.visual_protection >= 0.95: return 0.0
	var offset := player.global_position - creature.global_position
	var horizontal := Vector3(offset.x, 0, offset.z)
	var distance := horizontal.length()
	# Flashlight is an explicit exposure cue, not a fabricated renderer light meter.
	var range_limit := profile.vision_distance * (1.25 if player.lamp_on else (0.72 if player.crouched else 1.0))
	if distance > range_limit: return 0.0
	if distance > 1.6 and -creature.global_basis.z.dot(horizontal.normalized()) < cos(deg_to_rad(profile.horizontal_fov * 0.5)): return 0.0
	ray_count += 1
	var query := PhysicsRayQueryParameters3D.create(creature.global_position + Vector3.UP * 2.1, player.camera.global_position, 1 | 2, [creature.get_rid()])
	var hit := creature.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or hit.collider != player: return 0.0
	var exposure := 0.7 if player.crouched else 1.0
	if player.velocity.length() > 2.8: exposure *= 1.2
	if player.hidden: exposure *= 1.0 - player.hide_spot.visual_protection
	return clampf(exposure * (1.0 - 0.45 * distance / range_limit) * profile.visual_sensitivity, 0, 1.5)
