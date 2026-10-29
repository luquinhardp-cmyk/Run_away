extends StaticBody3D
@export var kind := "document"
@export var item_id := ""
@export var title := "Examinar"
var open := false
var mesh: MeshInstance3D
var collider: CollisionShape3D
var original_position := Vector3.ZERO
var message := ""
signal notified(text: String)

func _ready() -> void:
	collision_layer = 8 if kind != "door" else 1 | 8
	collision_mask = 0
	if kind == "door": set_meta("door", true)
	mesh = get_node_or_null("Mesh")
	collider = get_node_or_null("Collision")
	original_position = position
	if kind == "door" and Game.doors.get(item_id, false): _set_open(true)
	if kind == "pickup" and Game.inventory.has(item_id): queue_free()

func get_prompt() -> String:
	if kind == "door": return "Fechar porta" if open else title
	if kind == "generator" and Game.power: return "Energia restaurada"
	return title

func interact(player: CharacterBody3D) -> void:
	match kind:
		"pickup":
			Game.collect(item_id)
			Sound.at("pickup", global_position)
			if item_id == "lanterna": player.toggle_lamp()
			if item_id == "cartao" and is_instance_valid(Game.enemy):
				Game.enemy.last_known = global_position
				Game.enemy.transition(Game.enemy.State.INVESTIGATE)
				Sound.at("chase", global_position, -18)
			notified.emit("Coletado: " + title)
			queue_free()
		"door":
			if item_id == "security" and not Game.power:
				notified.emit("Fechadura sem energia. Restaure o gerador.")
				return
			_set_open(not open)
			Game.doors[item_id] = open
			NoiseBus.emit_noise(self, 0.35, "porta", 12.0)
			Sound.at("metal", global_position)
		"hide": player.enter_hide(self)
		"generator":
			if Game.power: return
			if not Game.inventory.has("fusivel"):
				notified.emit("Falta um fusível. Procure na manutenção.")
				return
			Game.power = true
			Game.save_checkpoint()
			NoiseBus.emit_noise(self, 1.0, "gerador", 36.0, 2.0)
			Sound.at("generator", global_position, -8)
			notified.emit("ENERGIA RESTAURADA · checkpoint salvo na enfermaria")
		"exit":
			if Game.power and Game.inventory.has("cartao"): Game.finish(true)
			else: notified.emit("Saída bloqueada. Precisa de energia e cartão de segurança.")
		"document": notified.emit(message)
		"drawer":
			open = not open
			mesh.position.z = 0.3 if open else 0.0
			Sound.at("metal", global_position, -22)
			notified.emit("Gaveta vazia. Há marcas de unhas no fundo.")
		"object":
			NoiseBus.emit_noise(self, 1.0, "objeto", 26.0)
			Sound.at("metal", global_position, -8)
			mesh.rotation.z += 0.7
			notified.emit("O metal ecoa pelo corredor. Afaste-se.")

func _set_open(value: bool) -> void:
	open = value
	if collider: collider.set_deferred("disabled", value)
	if mesh: mesh.position.y = 2.8 if value else 0.0
