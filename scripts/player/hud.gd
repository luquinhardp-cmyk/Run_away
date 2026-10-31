extends CanvasLayer
var root: Control
var objective: Label
var prompt: Label
var mic_label: Label
var toast: Label
var danger: ColorRect
var stick: Control
var knob: Panel
var stick_id := -1
var look_id := -1
var stick_center := Vector2.ZERO
var move := Vector2.ZERO
var toast_time := 0.0
var touch_buttons: Array[Button] = []
var inventory_open := false
var actions: Array[Button] = []
var throw_button: Button

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	danger = ColorRect.new()
	danger.color = Color(0.5, 0.06, 0.02, 0)
	danger.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	danger.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(danger)
	objective = label("", Vector2(30, 24), 19)
	objective.modulate = Color("bdb497")
	mic_label = label("", Vector2(30, 54), 15)
	var crosshair := label("·", Vector2.ZERO, 30)
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position = root.size * 0.5 + Vector2(-5, -22)
	prompt = label("", Vector2.ZERO, 20)
	prompt.set_anchors_preset(Control.PRESET_CENTER)
	prompt.position = root.size * 0.5 + Vector2(-220, 50)
	prompt.size = Vector2(440, 60)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast = label("", Vector2.ZERO, 18)
	toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast.position = Vector2(root.size.x * 0.5 - 330, 100)
	toast.size = Vector2(660, 100)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stick = Control.new()
	stick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	root.add_child(stick)
	stick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	var ring := Panel.new()
	ring.size = Vector2(150, 150)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stick.add_child(ring)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.18, 0.13, 0.15)
	style.border_color = Color(0.65, 0.60, 0.42, 0.4)
	style.set_border_width_all(2)
	style.set_corner_radius_all(75)
	ring.add_theme_stylebox_override("panel", style)
	knob = Panel.new()
	knob.size = Vector2(56, 56)
	knob.position = Vector2(47, 47)
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var knob_style := style.duplicate()
	knob_style.bg_color = Color(0.65, 0.60, 0.42, 0.35)
	knob.add_theme_stylebox_override("panel", knob_style)
	stick.add_child(knob)
	button("CORRER", Vector2(-278, -98), func(): Game.player.touch_run = not Game.player.touch_run)
	button("AGACHAR", Vector2(-146, -98), func(): Game.player.toggle_crouch())
	button("INTERAGIR", Vector2(-146, -188), func(): Game.player.interact())
	button("LANTERNA", Vector2(-278, -188), func(): Game.player.toggle_lamp())
	button("MOCHILA", Vector2(-410, -98), toggle_inventory)
	button("ARREMESSAR", Vector2(-410, -188), func(): Game.player.throw_object())
	throw_button = actions[-1]
	var pause := Button.new()
	pause.text = "Ⅱ  PAUSA"
	pause.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause.position = Vector2(-164, 24)
	pause.size = Vector2(140, 52)
	pause.pressed.connect(func(): Game.set_paused(true))
	root.add_child(pause)
	pause.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause.position = Vector2(root.size.x - 164, 24)
	var mute := Button.new()
	mute.text = "DESLIGAR MIC"
	mute.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	mute.position = Vector2(-330, 24)
	mute.size = Vector2(154, 52)
	mute.pressed.connect(func(): Mic.disable())
	root.add_child(mute)
	mute.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	mute.position = Vector2(root.size.x - 330, 24)
	Game.updated.connect(apply_layout)
	apply_layout()
	show_message("WASD mover · mouse olhar · Shift correr · C agachar · E interagir · F lanterna\nNo celular: arraste à esquerda para mover e à direita para olhar.")

func label(text: String, pos: Vector2, font_size: int) -> Label:
	var result := Label.new()
	result.text = text
	result.position = pos
	result.add_theme_font_size_override("font_size", font_size)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(result)
	return result

func button(text: String, offset: Vector2, callback: Callable) -> void:
	var result := Button.new()
	result.text = text
	result.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	result.position = offset
	result.size = Vector2(122, 76)
	result.set_meta("offset", offset)
	result.pressed.connect(callback)
	result.focus_mode = Control.FOCUS_NONE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.055, 0.045, 0.9)
	style.border_color = Color(0.45, 0.41, 0.28, 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	result.add_theme_stylebox_override("normal", style)
	result.add_theme_color_override("font_color", Color("c4bba2"))
	root.add_child(result)
	result.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	actions.append(result)

func apply_layout() -> void:
	var scale_value: float = Game.settings.controls
	# Insets are transformed from display pixels to the 1280x720 design space.
	var inset := Vector2(24, 24)
	if OS.has_feature("android"):
		var safe := DisplayServer.get_display_safe_area()
		var screen := DisplayServer.screen_get_size()
		var margin_x := maxf(safe.position.x, screen.x - safe.end.x)
		var margin_y := maxf(safe.position.y, screen.y - safe.end.y)
		inset = Vector2(maxf(24, margin_x * 1280.0 / screen.x), maxf(24, margin_y * 720.0 / screen.y))
	stick.scale = Vector2.ONE * scale_value
	stick.position = Vector2(inset.x + Game.settings.control_x, root.size.y - inset.y - 150 * scale_value + Game.settings.control_y)
	for result in actions:
		result.scale = Vector2.ONE * scale_value
		result.position = root.size + result.get_meta("offset") * scale_value + Vector2(-inset.x + 24 - Game.settings.control_x, -inset.y + 24 + Game.settings.control_y)
		result.modulate.a = Game.settings.opacity

func _input(event: InputEvent) -> void:
	if not Game.playing or Game.paused or not is_instance_valid(Game.player): return
	if event.is_action_pressed("inventory"): toggle_inventory()
	if event is InputEventScreenTouch:
		var point: Vector2 = root.get_global_transform_with_canvas().affine_inverse() * event.position
		if event.pressed:
			for child in root.get_children():
				if child is Button and child.get_global_rect().has_point(point): return
			if point.x < root.size.x * 0.44 and stick_id == -1:
				stick_id = event.index
				stick_center = point
			elif point.x >= root.size.x * 0.44 and look_id == -1: look_id = event.index
		else:
			if event.index == stick_id:
				stick_id = -1
				move = Vector2.ZERO
				knob.position = Vector2(47, 47)
			if event.index == look_id: look_id = -1
	if event is InputEventScreenDrag:
		var inverse := root.get_global_transform_with_canvas().affine_inverse()
		if event.index == stick_id:
			move = ((inverse * event.position - stick_center) / (65 * Game.settings.controls)).limit_length()
			knob.position = Vector2(47, 47) + move * 40
		if event.index == look_id: Game.player.look(event.relative * 1.5)

func show_message(text: String) -> void:
	toast.text = text
	toast_time = 7.0

func toggle_inventory() -> void:
	inventory_open = not inventory_open
	Game.player.throw_selected = int(Game.world.get("throwables", 0)) > 0
	show_message("MOCHILA: " + (", ".join(Game.inventory) if not Game.inventory.is_empty() else "vazia") + "\nPeças metálicas selecionadas: %d · Q / ARREMESSAR\n%s" % [int(Game.world.get("throwables", 0)), Game.objectives.definitions[-1].caption])

func _process(delta: float) -> void:
	root.visible = Game.playing and not Game.paused
	if not is_instance_valid(Game.player): return
	if Game.paused:
		stick_id = -1
		look_id = -1
		move = Vector2.ZERO
		Game.player.touch_run = false
	Game.player.touch_move = move
	throw_button.visible = int(Game.world.get("throwables", 0)) > 0 and not Game.player.hidden
	objective.text = Game.objective
	prompt.text = Game.player.prompt
	mic_label.text = Mic.status + ("  ▰".repeat(Mic.level) if Mic.active else " · sons do jogo ativos")
	mic_label.modulate = Color(0.76, 0.43, 0.26) if Mic.level > 1 else Color("b19a64")
	toast_time -= delta
	toast.visible = toast_time > 0
	var chased: bool = is_instance_valid(Game.enemy) and Game.enemy.state == Game.enemy.State.CHASE
	danger.color.a = 0.07 * Game.settings.scares if chased else 0
