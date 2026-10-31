class_name HorrorCapture
extends Resource
@export var id := "front"
@export var weight := 1.0
@export var duration := 1.25
@export var camera_roll := 0.02
@export var camera_pull := 0.04
@export var clip := "capture_front"

func compatible(creature: CharacterBody3D, player: CharacterBody3D) -> bool:
	var direction := (creature.global_position - player.global_position).normalized()
	var facing := -player.global_basis.z.dot(direction)
	match id:
		"hide": return is_instance_valid(creature.captured_hide) and creature.captured_hide.has_occupant()
		"rear": return not player.hidden and facing < -0.35
		"side": return not player.hidden and absf(facing) < 0.65
		"front": return not player.hidden and facing > 0.0
		"corridor": return not player.hidden and absf(player.global_position.x) < 1.6
		"chase": return not player.hidden and Vector2(player.velocity.x, player.velocity.z).length() > 2.8
		"silent": return not player.hidden and player.velocity.length() < 0.3 and creature.suspicion < 0.25
		"dark": return not player.hidden and not Game.power
	return false
