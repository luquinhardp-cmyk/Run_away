extends Node
var props: Array[PhysicalProp3D] = []
var timer := 0.0
var budget_timer := 0.0
var maximum_awake := 16
func _ready() -> void:
	add_to_group("physics_managers")
	for entry in [["can","can",Vector3(-4,0.18,-17.2)], ["bottle_ward","bottle",Vector3(-8.8,0.2,1.4)], ["tool_edge","tool",Vector3(8.7,0.82,-9)], ["small_crate","small_crate",Vector3(-6.5,0.2,-15.5)], ["chair_maintenance","chair",Vector3(6.3,0.46,-6.7)], ["crate_storage","crate",Vector3(-8.8,0.32,-14)], ["trolley_ward","trolley",Vector3(-9.2,0.42,-0.6)], ["bucket_power","bucket",Vector3(-6,0.18,-33)], ["rubber_gallery","rubber_ball",Vector3(12.8,0.12,-18.5)], ["fragile_workshop","fragile_crate",Vector3(13,0.18,-17)], ["bottle_shelf","bottle",Vector3(13.82,1.3,-16.5)]]:
		spawn(entry[0],entry[1],entry[2])
	spawn("drawer_tool","tool",Vector3(5.8,0.35,-9.3))
	# Real shelf supports the bottle; the player can knock it from the edge.
	get_parent().box(Vector3(13.85,1.1,-16.5),Vector3(0.25,0.08,0.6),HorrorArt.surface("damp_wood"),true,get_parent().geometry)
	var hanging := preload("res://scripts/physics/hanging_prop.gd").new()
	hanging.position = Vector3(8,2.85,-8)
	get_parent().add_child(hanging)
func spawn(id: String, type: String, at: Vector3) -> PhysicalProp3D:
	if props.size() >= 16: return null
	var prop := PhysicalProp3D.new()
	prop.profile = load("res://resources/physics/objects/" + type + ".tres")
	prop.item_id = id
	prop.position = at
	prop.secondary = id in ["rubber_gallery", "bottle_shelf"]
	get_parent().add_child(prop)
	props.append(prop)
	return prop
func snapshot() -> void:
	if not Game.world.has("physics"): Game.world.physics = {}
	for prop in props:
		if is_instance_valid(prop) and prop.persistent: Game.world.physics[prop.item_id] = prop.snapshot()
	for object in get_tree().get_nodes_in_group("physics_mechanisms"):
		Game.world.physics[object.item_id] = {"open":object.open}
func _physics_process(delta: float) -> void:
	if not Game.playing or Game.paused: return
	timer += delta
	budget_timer += delta
	if timer >= 2:
		timer = 0
		snapshot()
	if budget_timer < 0.5 or not is_instance_valid(Game.player): return
	budget_timer = 0
	var active := 0
	for prop in props:
		if not is_instance_valid(prop) or prop.broken: continue
		var distance := prop.global_position.distance_to(Game.player.global_position)
		if prop.secondary and Game.settings.quality < 1:
			if distance > 14 and prop.linear_velocity.length() < 0.15 and prop.held_by == null:
				prop.freeze = true
				prop.budget_frozen = true
			elif prop.budget_frozen:
				prop.freeze = false
				prop.budget_frozen = false
		if not prop.sleeping and not prop.freeze: active += 1
		if active > maximum_awake and prop.held_by == null and prop.linear_velocity.length() < 0.1: prop.sleeping = true
