extends Node
var passed := 0
var failed := 0
func check(ok: bool, title: String) -> void:
	if ok: passed += 1
	else: failed += 1; push_error(title)
	print("PASS " if ok else "FAIL ", title)
func _ready() -> void:
	Game.testing = true
	Game.record_results = false
	for quality in [0,1,2]:
		Game.settings.quality = quality
		var visual := Node3D.new()
		visual.set_script(preload("res://scripts/enemy/escutador_visual.gd"))
		add_child(visual)
		check(visual.model.scene_file_path.contains("escutador_macabre"), "new supplied model selected in profile %d" % quality)
		for mesh in visual.model.find_children("*", "MeshInstance3D", true, false):
			for surface in mesh.mesh.get_surface_count():
				var material: StandardMaterial3D = mesh.get_surface_override_material(surface)
				check(material.resource_name.begins_with("Received_Macabre_") and material.vertex_color_use_as_albedo, "new model colors/materials preserved")
				var colors: PackedColorArray = mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_COLOR]
				check(not colors.is_empty(), "source vertex color data retained")
				var colored := false
				for color in colors:
					if minf(color.r, minf(color.g, color.b)) < .85: colored = true; break
				check(colored, "surface retains pigment after remesh and merge")
				if quality == 0: check(not material.normal_enabled, "low profile avoids normal-map cost")
		visual.set_motion(0)
		visual.advance_motion(0)
		check(visual.active_clip == "breathe", "navigation stop blends to breathing")
		visual.advance_motion(.08)
		check(visual.active_clip == "breathe", "hysteresis avoids stationary animation flicker")
		visual.advance_motion(1.55)
		check(visual.active_clip == "patrol", "movement resumes patrol animation")
		visual.play_capture("capture_front")
		visual.advance_motion(0)
		check(visual.active_clip == "capture_front", "locomotion cannot override capture")
		visual.free()
	print("MACABRE RESULT ", passed, " passed; ", failed, " failed")
	get_tree().quit(0 if failed == 0 else 1)
