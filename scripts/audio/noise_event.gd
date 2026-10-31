class_name WorldNoise
extends Resource
var event_id: int
var source_id: int
var world_position: Vector3
var category: StringName
var loudness: float
var duration: float
var timestamp: float
var radius: float
var propagation_profile: StringName = &"air"

func as_dictionary(origin: Node3D) -> Dictionary:
	# Keep existing consumers compatible; resource is the canonical event payload.
	return {"event_id": event_id, "source_id": source_id, "world_position": world_position, "category": category, "loudness": loudness, "timestamp": timestamp, "propagation_profile": propagation_profile, "origin": origin, "position": world_position, "kind": str(category), "intensity": loudness, "duration": duration, "time": timestamp, "radius": radius}
