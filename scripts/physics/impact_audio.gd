class_name PhysicsImpactAudio
extends Node3D
signal impact_reported(data: Dictionary)
@export var material_id := "metal"
@export var minimum_speed := 0.8
@export var cooldown := 0.32
var clock := 0.0
var last_impact := -1000.0
var samples: Dictionary = {}
var sample_index: Dictionary = {}
var count := 0
func advance(delta: float) -> void:
	clock += delta
func report(point: Vector3, other: Object, relative_speed: float, mass_kg: float, category := "impacto_fisico") -> bool:
	if relative_speed < minimum_speed or clock - last_impact < cooldown or not Game.playing or Game.paused: return false
	# A dynamic pair has exactly one reporting owner, independent of contact order.
	if other is RigidBody3D and other.has_meta("impact_owner") and get_parent().get_instance_id() > other.get_instance_id(): return false
	last_impact = clock
	var surface := str(other.get_meta("physical_surface", "concrete")) if is_instance_valid(other) else "concrete"
	var bank := "heavy" if mass_kg > 8 else ("glass" if material_id == "glass" else ("rubber" if material_id == "rubber" else ("wood" if material_id in ["wood", "cloth"] else "metal")))
	var intensity := clampf(relative_speed / 10.0 * sqrt(maxf(0.2, mass_kg)) * (0.55 if surface in ["cloth", "earth", "rubber"] else 1.0), 0.08, 1.4)
	global_position = point
	NoiseBus.emit_noise(self, intensity, category, 5.0 + intensity * 22)
	Sound.physics_impact(bank, point, -30 + intensity * 14, int(sample_index.get(bank, -1)))
	sample_index[bank] = Sound.last_impact_sample
	count += 1
	impact_reported.emit({"position":point, "material":material_id, "surface":surface, "speed":relative_speed, "mass":mass_kg, "intensity":intensity})
	return true
