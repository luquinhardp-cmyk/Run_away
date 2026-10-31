extends "res://scripts/interactions/interactable.gd"
var tutorial_action := ""
var manager: Node
func interact(player: CharacterBody3D) -> void:
	match tutorial_action:
		"exit": manager.request_exit()
		"simulate": manager.simulate_microphone()
		"microphone": Mic.request_enable(); manager.feedback.emit("Microfone opcional: " + Mic.status + ". A SIMULAÇÃO continua disponível.")
		"recover": manager.recover_can()
		"mission":
			manager.flags["mission_read"] = true
			manager.feedback.emit(message)
			manager.check_objectives()
		_: super.interact(player)
