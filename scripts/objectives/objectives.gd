class_name HorrorObjectives
extends RefCounted
enum Status { LOCKED, AVAILABLE, ACTIVE, COMPLETE }
var definitions: Array[HorrorObjective] = []

func _init() -> void:
	for id in ["lanterna", "fusivel", "power", "cartao", "escape", "shortcut"]:
		definitions.append(load("res://resources/objectives/" + id + ".tres"))

func completed(id: String) -> bool:
	match id:
		"power": return Game.power
		"escape": return bool(Game.world.get("escaped", false))
		"shortcut": return bool(Game.world.get("unlocks", {}).get("workshop", false))
	return Game.inventory.has(id)

func state(definition: HorrorObjective) -> Status:
	if completed(definition.id): return Status.COMPLETE
	for requirement in definition.requires:
		if not completed(requirement): return Status.LOCKED
	return Status.ACTIVE if definition.id == "power" and bool(Game.world.get("fuse_installed", false)) else Status.AVAILABLE

func current_text() -> String:
	for definition in definitions:
		if not definition.optional and state(definition) in [Status.AVAILABLE, Status.ACTIVE]: return definition.caption
	return "Você escapou da instalação."
