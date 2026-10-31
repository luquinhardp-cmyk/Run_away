extends "res://scripts/player/hud.gd"
var manager: Node
func _ready() -> void:
	super._ready()
	manager.changed.connect(refresh)
	manager.feedback.connect(show_message)
	refresh()
func refresh() -> void:
	objective.text = "PREPARAÇÃO — %d/9 · %s" % [manager.step + 1, TutorialLesson.STEPS[manager.step][0]]
	show_message(TutorialLesson.STEPS[manager.step][1])
func toggle_inventory() -> void:
	super.toggle_inventory()
func _process(delta: float) -> void:
	super._process(delta)
	if not is_instance_valid(manager): return
	objective.text = "PREPARAÇÃO — %d/9 · %s" % [manager.step + 1, TutorialLesson.STEPS[manager.step][0]]
	if toast_time <= 0: refresh()
	if manager.demo_active: mic_label.text = "SIMULAÇÃO — " + ("MODERADO ▰▰" if manager.demo_time < 1.0 else "SILENCIOSO")
	elif manager.flags.get("mic_done",false) and not Mic.active: mic_label.text = "DEMONSTRAÇÃO CONCLUÍDA · microfone continua opcional"
