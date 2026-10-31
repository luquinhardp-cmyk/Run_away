extends AnimatableBody3D
var kind := "hanging"
var item_id := "maintenance_chain"
var interaction_distance := 2.5
var angle := 0.0
var angular_speed := 0.0
var cooldown := 0.0
func _ready() -> void:
	name = "HangingMaintenanceChain"
	collision_layer = 8 | 16
	collision_mask = 0
	PhysicsSurfaces.attach(self,"metal")
	var visual := MultiMeshInstance3D.new()
	var chain := TorusMesh.new()
	chain.inner_radius = 0.027
	chain.outer_radius = 0.045
	chain.rings = 8
	chain.ring_segments = 4
	chain.material = HorrorArt.surface("industrial_sheet")
	var links := MultiMesh.new()
	links.transform_format = MultiMesh.TRANSFORM_3D
	links.mesh = chain
	links.instance_count = 12
	for i in 12: links.set_instance_transform(i,Transform3D(Basis.from_euler(Vector3(PI/2,(i%2)*PI/2,0)),Vector3(0,-0.08*i,0)))
	visual.multimesh = links
	add_child(visual)
	var end := MeshInstance3D.new()
	var weight := TorusMesh.new()
	weight.inner_radius = 0.06
	weight.outer_radius = 0.09
	end.mesh = weight
	end.material_override = HorrorArt.surface("rusted_iron")
	end.position.y = -1
	add_child(end)
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.08
	shape.height = 1.1
	collision.shape = shape
	collision.position.y = -0.55
	add_child(collision)
	var sensor := Area3D.new()
	sensor.collision_layer = 0
	sensor.collision_mask = 16
	var sense_shape := CollisionShape3D.new()
	sense_shape.shape = shape
	sense_shape.position.y = -0.55
	sensor.add_child(sense_shape)
	add_child(sensor)
	sensor.body_entered.connect(func(body: Node3D):
		if body is RigidBody3D and body.linear_velocity.length() > 0.4:
			kick(minf(1.0,body.linear_velocity.length()*0.2))
			cooldown = 0.8) # The prop owns initial impact audio; only later rattling belongs here.
func get_prompt() -> String: return "Balançar corrente"
func interact(_player: CharacterBody3D) -> void: kick(0.8)
func kick(strength: float) -> void: angular_speed = clampf(angular_speed + strength, -1.5, 1.5)
func _physics_process(delta: float) -> void:
	if not Game.playing or Game.paused: return
	if Game.settings.quality < 1 and is_instance_valid(Game.player) and global_position.distance_to(Game.player.global_position) > 12: return
	cooldown -= delta
	angular_speed += (-angle * 9.8 - angular_speed * 1.5) * delta
	angle = clampf(angle + angular_speed * delta, -0.45, 0.45)
	rotation.z = angle
	if absf(angular_speed) > 0.25 and cooldown <= 0:
		cooldown = 0.8
		Sound.physics_impact("chain", global_position + Vector3.DOWN * 0.8,-27)
		NoiseBus.emit_noise(self,0.18,"corrente",8)
