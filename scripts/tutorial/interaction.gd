extends "res://scripts/interactions/interactable.gd"
var tutorial_action := ""
var manager: Node
var motor: AudioStreamPlayer3D
var switch_handle: Node3D
func activate_generator(actor: CharacterBody3D) -> void:
	super.interact(actor)
func prepare_switch() -> void:
	if not is_instance_valid(switch_handle):
		switch_handle = manager.box(Vector3(-.22,.35,.45),Vector3(.08,.22,.07),"weathered_iron",false,self)
func get_prompt() -> String:
	if tutorial_action == "generator": return "Energia restaurada" if Game.power else "Interagir — Ligar gerador"
	if tutorial_action == "exit" and not Game.power: return "PORTA SEM ENERGIA — ligue o gerador"
	return super.get_prompt()
func restore_motor() -> void:
	if not is_instance_valid(motor):
		motor = AudioStreamPlayer3D.new()
		motor.stream = preload("res://assets/audio/generator.wav")
		motor.bus = "Effects"
		motor.volume_db = -26
		motor.max_db = -20
		motor.max_distance = 12
		add_child(motor)
		motor.finished.connect(func():
			if Game.power: motor.play())
	if not motor.playing: motor.play()
	prepare_switch()
	create_tween().tween_property(switch_handle,"rotation:x",-.7,.35)
func _process(delta: float) -> void:
	super._process(delta)
	if tutorial_action == "generator" and Game.power and is_instance_valid(mesh):
		mesh.position.y = sin(Time.get_ticks_msec() * .045) * .002
func interact(player: CharacterBody3D) -> void:
	match tutorial_action:
		"generator": manager.start_generator(player)
		"exit": manager.request_exit()
		"simulate": manager.simulate_microphone()
		"microphone": Mic.request_enable(); manager.feedback.emit("Microfone opcional: " + Mic.status + ". A SIMULAÇÃO continua disponível.")
		"recover": manager.recover_can()
		"mission":
			manager.flags["mission_read"] = true
			manager.feedback.emit(message)
			manager.check_objectives()
		_: super.interact(player)
