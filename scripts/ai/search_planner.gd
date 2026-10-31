class_name CreatureSearch
extends RefCounted
var points: Array[Vector3] = []
var index := 0

func build(creature: CharacterBody3D, center: Vector3, memory: CreatureMemory) -> void:
	points.clear()
	index = 0
	var candidates: Array[Vector3] = [center]
	for node in creature.get_tree().get_nodes_in_group("search_points"):
		if node.global_position.distance_to(center) <= 12: candidates.append(node.global_position)
	for ring in [2.5, 5.0, 8.0]:
		for side in 4: candidates.append(center + Vector3(cos(side * PI / 2), 0, sin(side * PI / 2)) * ring)
	candidates.sort_custom(func(a: Vector3, b: Vector3): return a.distance_squared_to(center) < b.distance_squared_to(center))
	var map: RID = creature.agent.get_navigation_map()
	for candidate in candidates:
		var nearest := NavigationServer3D.map_get_closest_point(map, candidate)
		if nearest.distance_to(candidate) > 1.5: continue
		var path := NavigationServer3D.map_get_path(map, creature.global_position, nearest, true)
		if path.is_empty() or path[-1].distance_to(nearest) > 0.6: continue
		var repeated := false
		for prior in points + memory.searched:
			if prior.distance_to(nearest) < 1.1: repeated = true; break
		if not repeated: points.append(nearest)
		if points.size() >= 10: break

func next_point() -> Vector3:
	var result := points[index]
	index += 1
	return result

func has_next() -> bool:
	return index < points.size()
