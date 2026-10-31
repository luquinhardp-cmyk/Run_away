extends PhysicalProp3D
@export var throw_force := 9.0
func _ready() -> void:
	profile = load("res://resources/physics/objects/can.tres")
	persistent = false
	thrown = true
	noise_kind = "objeto_arremessado"
	super._ready()
	add_to_group("throwables")
