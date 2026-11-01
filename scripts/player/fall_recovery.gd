extends Node
## Local diagnostics only. This never changes objectives, inventory or cloud data.
signal recovered(incident: Dictionary)
@export var minimum_y := -8.0
@export var maximum_fall_seconds := 4.0
@export var log_path := "user://fall_incidents.json"
var player: CharacterBody3D
var fallback := Vector3.ZERO
var safe_positions: Array[Vector3] = []
var sample_clock := 0.0
var falling := 0.0
var fall_origin := 0.0
var fall_started_at := Vector3.ZERO
var recent_recoveries: Array[float] = []
var cooldown := 0.0
var incidents: Array = []
var recovery_count := 0
var blocked := false
func _ready() -> void:
	player = get_parent()
	fallback = player.global_position
	if not Game.testing and FileAccess.file_exists(log_path):
		var previous = JSON.parse_string(FileAccess.get_file_as_string(log_path))
		if previous is Dictionary: previous=previous.get("incidents",[])
		if previous is Array: incidents = previous.slice(maxi(0,previous.size()-63))
func ground_at(pos: Vector3) -> Dictionary:
	return player.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(pos+Vector3.UP*.22,pos-Vector3.UP*.38,1,[player.get_rid()]))
func valid_position(pos: Vector3) -> bool:
	if not pos.is_finite(): return false
	var floor_hit := ground_at(pos)
	if floor_hit.is_empty() or floor_hit.normal.y < .65: return false
	# A fence top or the edge of a hole is not a safe landing, even when a
	# center ray hits it. Check support around the capsule's footprint too.
	for offset in [Vector3(.2,0,0),Vector3(-.2,0,0),Vector3(0,0,.2),Vector3(0,0,-.2)]:
		var support := ground_at(pos+offset)
		if support.is_empty() or support.normal.y<.65 or absf(support.position.y-floor_hit.position.y)>.2: return false
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = player.shape.shape
	query.transform = Transform3D(Basis.IDENTITY,pos+player.shape.position+Vector3.UP*.04)
	query.collision_mask = 1 | 4 | 16
	query.exclude = [player.get_rid()]
	return player.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()
func tick(delta: float) -> void:
	if blocked or not Game.playing or Game.paused or Game.capture_in_progress or player.hidden: return
	# Narrative drops can opt out explicitly; ordinary basement descent is < 2 m.
	if player.get_meta("legitimate_fall",false): falling=0; return
	cooldown=maxf(0,cooldown-delta)
	if player.is_on_floor():
		falling=0
		sample_clock+=delta
		if sample_clock >= .35:
			sample_clock=0
			if valid_position(player.global_position):
				if safe_positions.is_empty() or safe_positions.back().distance_to(player.global_position)>.3:
					safe_positions.append(player.global_position)
					if safe_positions.size()>12: safe_positions.pop_front()
	else:
		if falling==0:
			fall_origin=player.global_position.y
			fall_started_at=player.global_position
		falling+=delta
	if cooldown<=0 and (not player.global_position.is_finite() or player.global_position.y<minimum_y or (falling>maximum_fall_seconds and fall_origin-player.global_position.y>6)):
		recover()
func recover() -> bool:
	var before := player.global_position
	var before_velocity := player.velocity
	var now := Time.get_ticks_msec()/1000.0
	while not recent_recoveries.is_empty() and recent_recoveries.front()<now-15: recent_recoveries.pop_front()
	var candidates := safe_positions.duplicate()
	candidates.reverse()
	candidates.append(fallback)
	var destination := Vector3.ZERO
	var found := false
	for pos in candidates:
		if valid_position(pos): destination=pos; found=true; break
	if recent_recoveries.size()>=3: found=false
	var incident := {"time_utc":Time.get_datetime_string_from_system(true),"scene":player.get_parent().scene_file_path,"position":[before.x,before.y,before.z],"velocity":[before_velocity.x,before_velocity.y,before_velocity.z],"fall_seconds":falling,"probable_cause":"outside_supported_geometry" if before.y<minimum_y else "prolonged_or_invalid_fall","recovered":found,"destination":[destination.x,destination.y,destination.z] if found else [],"tutorial":Game.in_tutorial}
	incident["fall_started_at"]=[fall_started_at.x,fall_started_at.y,fall_started_at.z]
	incident["last_safe_position"]=[safe_positions.back().x,safe_positions.back().y,safe_positions.back().z] if not safe_positions.is_empty() else []
	incident["collision_mask"]=player.collision_mask
	if recent_recoveries.size()>=3: incident.probable_cause="repeated_recovery_guard"
	incidents.append(incident)
	if incidents.size()>64: incidents.pop_front()
	if not Game.testing: Game.write_json(log_path,{"version":1,"incidents":incidents})
	player.velocity=Vector3.ZERO
	player.touch_move=Vector2.ZERO
	player.touch_run=false
	if is_instance_valid(player.manipulator): player.manipulator.release()
	falling=0
	cooldown=3
	if found:
		recent_recoveries.append(now)
		player.global_position=destination+Vector3.UP*.06
		player.camera.position=Vector3(0,.9 if player.crouched else 1.56,0)
		player.camera.rotation=Vector3(player.pitch,0,0)
		recovery_count+=1
	else:
		blocked=true
		Game.set_paused(true)
		push_warning("Fall recovery: no verified clear floor; session paused. See fall_incidents.json")
	recovered.emit(incident)
	return found
