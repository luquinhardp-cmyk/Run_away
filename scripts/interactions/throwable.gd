extends RigidBody3D
@export var throw_force := 10.0
var lifetime := 0.0
var impact_cooldown := 0.0
var previous_speed := 0.0
var impacts := 0

func _ready() -> void:
	add_to_group("throwables")
	collision_layer = 16
	collision_mask = 1 | 2 | 4
	mass = 0.35
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 4
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.09
	collision.shape = sphere
	add_child(collision)
	var mesh := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = 0.07
	shape.bottom_radius = 0.08
	shape.height = 0.2
	shape.radial_segments = 8
	mesh.mesh = shape
	mesh.material_override = HorrorArt.surface("rusted_iron")
	add_child(mesh)
	body_entered.connect(_impact)

func _physics_process(delta: float) -> void:
	lifetime += delta
	impact_cooldown -= delta
	previous_speed = linear_velocity.length()
	if lifetime > 18 or global_position.y < -8: queue_free()

func _impact(_body: Node) -> void:
	if impact_cooldown > 0 or previous_speed < 0.8 or impacts >= 4: return
	impacts += 1
	impact_cooldown = 0.45
	NoiseBus.emit_noise(self, clampf(previous_speed / 9.0, 0.25, 1.1), "objeto_arremessado", 26)
	Sound.at("metal", global_position, -10)
