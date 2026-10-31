extends CanvasLayer
signal inventory_viewed
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
var hold_button: Button
var inventory_window: CanvasLayer
var noise_meter: ProgressBar
var pause_button: Button
var mute_button: Button

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = IndustrialUI.theme()
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
	noise_meter = ProgressBar.new()
	noise_meter.position = Vector2(30,78)
	noise_meter.size = Vector2(210,7)
	noise_meter.max_value = 3
	noise_meter.show_percentage = false
	noise_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	noise_meter.add_theme_stylebox_override("background",IndustrialUI.panel(Color("191d1b"),Color("444641")))
	noise_meter.add_theme_stylebox_override("fill",IndustrialUI.panel(Color("b19a64"),Color("b19a64")))
	root.add_child(noise_meter)
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
	button("SEGURAR", Vector2(-542, -188), func(): pass)
	hold_button = actions[-1]
	hold_button.button_down.connect(func(): Game.player.begin_hold())
	hold_button.button_up.connect(func(): Game.player.manipulator.release())
	var pause := Button.new()
	pause_button = pause
	pause.icon = IndustrialUI.icon("pause")
	pause.expand_icon = true
	pause.add_theme_constant_override("icon_max_width",24)
	pause.text = "PAUSA"
	pause.add_theme_font_size_override("font_size",16)
	pause.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause.position = Vector2(-164, 24)
	pause.size = Vector2(140, 52)
	pause.pressed.connect(func(): Game.set_paused(true))
	root.add_child(pause)
	pause.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause.position = Vector2(root.size.x - 164, 24)
	var mute := Button.new()
	mute_button = mute
	mute.icon = IndustrialUI.icon("mic")
	mute.expand_icon = true
	mute.add_theme_constant_override("icon_max_width",24)
	mute.text = "DESLIGAR MIC"
	mute.add_theme_font_size_override("font_size",14)
	mute.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	mute.position = Vector2(-330, 24)
	mute.size = Vector2(154, 52)
	mute.pressed.connect(func(): Mic.disable())
	root.add_child(mute)
	mute.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	mute.position = Vector2(root.size.x - 330, 24)
	Game.updated.connect(apply_layout)
	root.resized.connect(apply_layout)
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
	var action: String = {"CORRER":"run","AGACHAR":"crouch","INTERAGIR":"hand","LANTERNA":"flashlight","MOCHILA":"backpack","ARREMESSAR":"throw","SEGURAR":"hold"}.get(text,"hand")
	result.icon = IndustrialUI.icon(action)
	result.expand_icon = true
	result.add_theme_constant_override("icon_max_width",26)
	result.add_theme_font_size_override("font_size",14)
	result.toggle_mode = text in ["CORRER","AGACHAR","LANTERNA"]
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
	result.remove_theme_stylebox_override("normal")
	result.add_theme_color_override("font_color", Color("c4bba2"))
	root.add_child(result)
	result.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	actions.append(result)

func apply_layout() -> void:
	var scale_value: float = Game.settings.controls
	# Transform native safe areas into the current canvas size (including iPad).
	var inset := Vector2(24, 24)
	if OS.has_feature("android") or OS.has_feature("ios"):
		var safe := DisplayServer.get_display_safe_area()
		var screen := DisplayServer.screen_get_size()
		var margin_x := maxf(safe.position.x, screen.x - safe.end.x)
		var margin_y := maxf(safe.position.y, screen.y - safe.end.y)
		if screen.x > 0 and screen.y > 0:
			inset = Vector2(maxf(24, margin_x * root.size.x / screen.x), maxf(24, margin_y * root.size.y / screen.y))
	stick.scale = Vector2.ONE * scale_value
	objective.position = Vector2(inset.x, inset.y)
	objective.size.x = maxf(200,root.size.x-inset.x*2-340)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mic_label.position = Vector2(inset.x,inset.y+30)
	noise_meter.position = Vector2(inset.x,inset.y+54)
	pause_button.position = Vector2(root.size.x-inset.x-140,inset.y)
	mute_button.position = Vector2(root.size.x-inset.x-306,inset.y)
	stick.position = Vector2(inset.x + Game.settings.control_x, root.size.y - inset.y - 150 * scale_value + Game.settings.control_y)
	for result in actions:
		result.scale = Vector2.ONE * scale_value
		result.position = root.size + result.get_meta("offset") * scale_value + Vector2(-inset.x + 24 - Game.settings.control_x, -inset.y + 24 + Game.settings.control_y)
		result.modulate.a = Game.settings.opacity

func _input(event: InputEvent) -> void:
	if inventory_open:
		if event.is_action_pressed("inventory") or event.is_action_pressed("pause"):
			close_inventory()
			get_viewport().set_input_as_handled()
		return
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
	if inventory_open: close_inventory(); return
	if not Game.playing or Game.paused or Game.capture_in_progress: return
	inventory_open = true
	Game.inventory_open = true
	stick_id = -1
	look_id = -1
	move = Vector2.ZERO
	Game.player.touch_move = Vector2.ZERO
	Game.player.touch_run = false
	Game.player.velocity = Vector3.ZERO
	Game.set_paused(true)
	inventory_window = CanvasLayer.new()
	inventory_window.set_script(preload("res://scripts/ui/inventory_window.gd"))
	add_child(inventory_window)
	inventory_window.close_requested.connect(close_inventory)
	inventory_window.ui_sound()
	inventory_viewed.emit()

func close_inventory() -> void:
	if not inventory_open: return
	inventory_open = false
	if is_instance_valid(inventory_window):
		inventory_window.ui_sound()
		inventory_window.hide()
		inventory_window.queue_free()
	Game.inventory_open = false
	if Game.playing: Game.set_paused(false)

func _exit_tree() -> void:
	Game.inventory_open = false

func _process(delta: float) -> void:
	root.visible = Game.playing and not Game.paused and not Game.capture_in_progress
	if not is_instance_valid(Game.player): return
	if Game.paused:
		if not inventory_open: Game.player.manipulator.release()
		stick_id = -1
		look_id = -1
		move = Vector2.ZERO
		Game.player.touch_run = false
	Game.player.touch_move = move
	noise_meter.value = Mic.level if Mic.active else 0
	mute_button.disabled = not Mic.consent
	for i in [0,1,3]: actions[i].set_pressed_no_signal([Game.player.touch_run or Input.is_action_pressed("run"),Game.player.crouched,Game.player.lamp_on][[0,1,3].find(i)])
	actions[3].disabled = not Game.inventory.has("lanterna")
	actions[2].disabled = not Game.player.hidden and not is_instance_valid(Game.player.focus)
	actions[2].icon = IndustrialUI.icon("door" if is_instance_valid(Game.player.focus) and Game.player.focus.get("kind")=="door" else "hand")
	if Game.player.hidden: actions[2].text="SAIR"; actions[2].icon=IndustrialUI.icon("door")
	elif is_instance_valid(Game.player.focus):
		var kind: String = str(Game.player.focus.get("kind"))
		actions[2].text = {"pickup":"PEGAR","throw_pickup":"PEGAR","document":"EXAMINAR","door":"PORTA","generator":"ATIVAR","fuse_panel":"INSTALAR","hide":"ESCONDER"}.get(kind,"INTERAGIR")
		if kind in ["fuse_panel","generator","radio","alarm"]: actions[2].icon=IndustrialUI.icon("use")
		elif kind=="document": actions[2].icon=IndustrialUI.icon("examine")
	else: actions[2].text="INTERAGIR"
	throw_button.visible = (int(Game.world.get("throwables", 0)) > 0 or is_instance_valid(Game.player.manipulator.held)) and not Game.player.hidden
	hold_button.visible = not Game.player.hidden and ((is_instance_valid(Game.player.focus) and Game.player.focus is PhysicalProp3D) or is_instance_valid(Game.player.manipulator.held))
	var medium_focus: bool = is_instance_valid(Game.player.focus) and Game.player.focus is PhysicalProp3D and Game.player.focus.profile.category == "C"
	hold_button.text = "ARRASTAR" if Game.player.manipulator.dragging or medium_focus else "SEGURAR"
	throw_button.text = "SOLTAR" if is_instance_valid(Game.player.manipulator.held) and not Game.player.manipulator.held.profile.can_throw else "ARREMESSAR"
	objective.text = Game.objective
	prompt.text = Game.player.prompt
	mic_label.text = Mic.status + ("  ▰".repeat(Mic.level) if Mic.active else " · sons do jogo ativos")
	mic_label.modulate = Color(0.76, 0.43, 0.26) if Mic.level > 1 else Color("b19a64")
	toast_time -= delta
	toast.visible = toast_time > 0
	var chased: bool = is_instance_valid(Game.enemy) and Game.enemy.state == Game.enemy.State.CHASE
	danger.color.a = 0.07 * Game.settings.scares if chased else 0
