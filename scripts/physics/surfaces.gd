class_name PhysicsSurfaces
extends RefCounted
static var cache: Dictionary = {}
const VALUES := {"metal":Vector2(0.45, 0.12), "wood":Vector2(0.72, 0.08), "concrete":Vector2(0.8, 0.04), "glass":Vector2(0.35, 0.16), "rubber":Vector2(0.95, 0.65), "earth":Vector2(0.9, 0.0), "cloth":Vector2(0.95, 0.02)}
static func material(id: String) -> PhysicsMaterial:
	if not cache.has(id):
		var name := id if VALUES.has(id) else "concrete"
		cache[id] = load("res://resources/physics/surfaces/"+name+".tres")
	return cache[id]
static func identify(mat: Material) -> String:
	if mat == null: return "concrete"
	var id := str(mat.get_meta("pbr_name", mat.resource_name))
	if "wood" in id: return "wood"
	if "glass" in id: return "glass"
	if "rubber" in id or "plastic" in id: return "rubber"
	if "fabric" in id or "upholstery" in id: return "cloth"
	if "mud" in id or "moss" in id: return "earth"
	if "iron" in id or "metal" in id or "steel" in id or "sheet" in id: return "metal"
	return "concrete"
static func attach(body: PhysicsBody3D, id: String) -> void:
	body.set_meta("physical_surface", id)
	if body is StaticBody3D or body is RigidBody3D: body.physics_material_override = material(id)
