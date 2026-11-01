extends Node
var clock := 0.0
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	if not OS.has_feature("web"): set_process(false)
func _process(delta: float) -> void:
	clock+=delta
	if clock<.15: return
	clock=0
	var bridge = JavaScriptBridge.get_interface("EcosWeb")
	if bridge==null or Game.testing: return
	if (bool(bridge.portrait) or bool(bridge.hidden) or bool(bridge.resumeRequired)) and Game.playing and not Game.paused:
		# Preserve the existing pause/menu path; rotation never restarts a level.
		Game.set_paused(true)
