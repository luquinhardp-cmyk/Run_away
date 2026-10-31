class_name CreatureMemory
extends RefCounted
var visual_position := Vector3.ZERO
var sound_position := Vector3.ZERO
var direction := Vector3.ZERO
var visual_at := -1000.0
var sound_at := -1000.0
var sound_strength := 0.0
var sound_source := 0
var searched: Array[Vector3] = []
var hide_clues: Dictionary = {}
var results: Array[Dictionary] = []

func saw(position: Vector3, now: float) -> void:
	if visual_at > 0: direction = (position - visual_position).limit_length(1.0)
	visual_position = position
	visual_at = now

func heard(event: Dictionary, strength: float, now: float) -> bool:
	# Do not jitter between weak sources while investigating a stronger fresh clue.
	if now - sound_at < 2.0 and strength < sound_strength * 0.65 and event.get("source_id", 0) != sound_source: return false
	sound_position = event.position
	sound_at = now
	sound_strength = strength
	sound_source = event.get("source_id", 0)
	return true

func mark_searched(point: Vector3, found: bool) -> void:
	searched.append(point)
	if searched.size() > 16: searched.pop_front()
	results.append({"position": point, "found": found})
	if results.size() > 16: results.pop_front()

func decay(delta: float) -> void:
	for id in hide_clues.keys():
		hide_clues[id] = maxf(0, float(hide_clues[id]) - delta * 0.02)
		if hide_clues[id] <= 0: hide_clues.erase(id)
