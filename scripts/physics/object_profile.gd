class_name ObjectPhysicsProfile
extends Resource
@export var id := "can"
@export_enum("B", "C", "D", "F") var category := "B"
@export var title := "Lata"
@export var mass_kg := 0.2
@export var surface := "metal"
@export var pbr := "rusted_iron"
@export_enum("box", "cylinder", "bottle", "chair", "trolley", "sphere") var shape := "cylinder"
@export var size := Vector3(0.18, 0.26, 0.18)
@export var can_hold := true
@export var can_throw := true
@export var can_push := true
@export var break_speed := 0.0
@export var damping := 0.15
