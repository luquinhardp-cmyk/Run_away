class_name CharacterPhysicsPush
extends RefCounted
static func apply(actor: CharacterBody3D, creature := false) -> void:
	for i in actor.get_slide_collision_count():
		var contact := actor.get_slide_collision(i)
		var body := contact.get_collider()
		if body is PhysicalProp3D and body.profile.can_push and not body.broken and not body.freeze:
			var direction := -contact.get_normal()
			direction.y = 0
			var speed := Vector2(actor.velocity.x, actor.velocity.z).length()
			body.sleeping = false
			body.apply_central_impulse(direction * minf((160.0 if creature else 65.0) * actor.get_physics_process_delta_time(), body.mass * 1.5) * clampf(speed, 1.0, 2.0))
