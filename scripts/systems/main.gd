extends Node
var level: Node3D
var hud: CanvasLayer
var ui: CanvasLayer
var background: ColorRect
var panel: PanelContainer
var column: VBoxContainer
var screen := "menu"
var pause_was := false
var menu_stage: Node3D

func _exit_tree() -> void:
	if is_instance_valid(menu_stage): menu_stage.set_active(false)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	menu_stage = Node3D.new()
	menu_stage.set_script(preload("res://scripts/systems/menu_stage.gd"))
	add_child(menu_stage)
	ui = CanvasLayer.new()
	ui.layer = 20
	add_child(ui)
	var theme := Theme.new()
	theme.default_font_size = 20
	var button_style := StyleBoxFlat.new()
	button_style.bg_color = Color(0.075, 0.085, 0.07, 0.88)
	button_style.border_color = Color("645b43")
	button_style.set_border_width_all(1)
	button_style.set_content_margin_all(12)
	theme.set_stylebox("normal", "Button", button_style)
	var hover := button_style.duplicate()
	hover.bg_color = Color(0.22, 0.20, 0.14, 0.96)
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("pressed", "Button", hover)
	background = ColorRect.new()
	background.color = Color(0.018, 0.035, 0.042, 0.96)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; uniform float shade = 0.86; void fragment() { float edge = mix(shade, 0.30, smoothstep(0.25, 1.0, UV.x)); COLOR = vec4(0.025, 0.03, 0.025, edge); }"
	var shader_mat := ShaderMaterial.new()
	shader_mat.shader = shader
	background.material = shader_mat
	ui.add_child(background)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 180
	scroll.offset_right = -180
	scroll.offset_top = 28
	scroll.offset_bottom = -28
	scroll.theme = theme
	ui.add_child(scroll)
	column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	scroll.add_child(column)
	Game.ended.connect(_ended)
	Game.updated.connect(_updated)
	Game.save_settings()
	menu()

func clear() -> void:
	for child in column.get_children():
		column.remove_child(child)
		child.queue_free()
	ui.show()

func text(value: String, size: int = 20) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.modulate = Color("c4bba2")
	column.add_child(label)
	return label

func button(value: String, callback: Callable) -> Button:
	var result := Button.new()
	result.text = value
	result.custom_minimum_size.y = 58
	result.pressed.connect(callback)
	column.add_child(result)
	return result

func menu() -> void:
	screen = "menu"
	clear()
	menu_stage.set_active(true)
	text("E C O S", 68)
	text("INSTALAÇÃO ABANDONADA", 26)
	text("Não há armas. Há caminhos. E algo escutando.\nEncontre o fusível, restaure a energia e alcance a saída.")
	button("INICIAR NOVA SESSÃO", func(): consent_screen(false))
	if not Game.checkpoint.is_empty(): button("CONTINUAR DO CHECKPOINT", func(): consent_screen(true))
	button("CONFIGURAÇÕES", func(): settings_screen("menu"))
	if not OS.has_feature("android") and not OS.has_feature("web"): button("SAIR", func(): get_tree().quit())
	text("Direção de arte 0.2 • O Escutador\nRecomendado: fones de ouvido. Sustos moderados, sem flashes.", 16)

func consent_screen(resume: bool) -> void:
	screen = "consent"
	clear()
	text("ATÉ O SEU MEDO FAZ BARULHO.", 38)
	text("Com o microfone ligado, sons perto do celular podem atrair a criatura.\nApenas a intensidade é processada localmente. Nenhuma voz é gravada ou enviada.\nA captura para na pausa e em segundo plano. Você pode desligá-la imediatamente no HUD.\nUse fones para evitar que o alto-falante do jogo ative o microfone.")
	text("Ao ativar: mantenha silêncio durante 3 segundos para calibrar o ruído ambiente.")
	button("JOGAR COM MICROFONE · permitir", func(): start(resume, true))
	button("JOGAR SEM MICROFONE", func(): start(resume, false))
	button("VOLTAR", menu)

func start(resume: bool, microphone: bool) -> void:
	_remove_level()
	menu_stage.set_active(false)
	Game.begin(resume)
	level = preload("res://scenes/levels/facility.tscn").instantiate()
	level.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(level)
	var player := preload("res://scenes/player/player.tscn").instantiate()
	player.position = Vector3(-7, 0.1, 0)
	level.add_child(player)
	player.rotation.y = 2.356
	player.pitch = -0.56
	player.camera.rotation.x = player.pitch
	var enemy := preload("res://scenes/enemy/creature.tscn").instantiate()
	enemy.position = Vector3(0, 0.1, -30)
	level.add_child(enemy)
	hud = preload("res://scenes/ui/hud.tscn").instantiate()
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hud)
	level.message.connect(hud.show_message)
	screen = "playing"
	ui.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if microphone: Mic.request_enable()
	else: Mic.disable()

func _remove_level() -> void:
	Mic.disable()
	Sound.stop_all()
	if is_instance_valid(level):
		for audio in level.find_children("*", "AudioStreamPlayer3D", true, false): audio.stop()
		for audio in level.find_children("*", "AudioStreamPlayer", true, false): audio.stop()
		level.free()
	if is_instance_valid(hud):
		hud.free()
	Game.player = null
	Game.enemy = null

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and Game.playing:
		Game.set_paused(not Game.paused)
		get_viewport().set_input_as_handled()

func _updated() -> void:
	if Game.playing and Game.paused and screen == "playing": pause_screen()
	elif Game.playing and not Game.paused and screen in ["pause", "settings"]:
		screen = "playing"
		ui.hide()

func pause_screen() -> void:
	screen = "pause"
	clear()
	text("RESPIRA. EM SILÊNCIO.", 40)
	text("PAUSADO · captura de microfone interrompida")
	button("CONTINUAR", func(): Game.set_paused(false))
	button("CONFIGURAÇÕES", func(): settings_screen("pause"))
	button("REINICIAR FASE", func(): start(false, false))
	button("VOLTAR AO MENU", to_menu)

func to_menu() -> void:
	Game.playing = false
	Game.paused = false
	get_tree().paused = false
	_remove_level()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	menu()

func _ended(won: bool) -> void:
	screen = "ended"
	get_tree().paused = true
	clear()
	text("VOCÊ ESCAPOU." if won else "ELE OUVIU VOCÊ.", 50)
	text("O ar frio do lado de fora nunca pareceu tão vivo." if won else "A instalação guardou mais um silêncio.\nAnde agachado, quebre a linha de visão e evite ruídos perto dos armários.")
	button("TENTAR NOVAMENTE", func(): start(false, false))
	if not Game.checkpoint.is_empty(): button("RETOMAR CHECKPOINT", func(): start(true, false))
	button("MENU PRINCIPAL", to_menu)

func settings_screen(back: String) -> void:
	screen = "settings"
	clear()
	text("CONFIGURAÇÕES", 34)
	for data in [["sensitivity", "Sensibilidade da câmera", 0.001, 0.008, 0.0002], ["fov", "Campo de visão", 65, 95, 1], ["master", "Volume geral", 0, 1, 0.05], ["effects", "Efeitos", 0, 1, 0.05], ["music", "Música", 0, 1, 0.05], ["mic_sensitivity", "Sensibilidade do microfone", 0.5, 3, 0.1], ["scares", "Intensidade dos sustos", 0, 1, 0.1], ["quality", "Qualidade: 0 baixa / 1 média / 2 alta", 0, 2, 1], ["controls", "Tamanho dos controles", 0.8, 1.3, 0.1], ["opacity", "Opacidade dos botões", 0.2, 1, 0.05], ["control_x", "Posição horizontal dos controles", -20, 100, 5], ["control_y", "Posição vertical dos controles", -80, 0, 5]]:
		var caption := text(data[1] + " : " + str(Game.settings[data[0]]), 17)
		var slider := HSlider.new()
		slider.min_value = data[2]
		slider.max_value = data[3]
		slider.step = data[4]
		slider.value = Game.settings[data[0]]
		slider.custom_minimum_size.y = 32
		column.add_child(slider)
		var key: String = data[0]
		var title: String = data[1]
		slider.value_changed.connect(func(value: float):
			Game.settings[key] = value
			caption.text = title + " : " + str(value)
			Game.save_settings())
	if Game.playing:
		text("Microfone: " + Mic.status + "\nA ativação ocorre ao continuar. O som pode atrair a criatura; apenas intensidade local.", 17)
		button("PERMITIR MICROFONE AO CONTINUAR", func(): Mic.request_enable())
		button("DESATIVAR MICROFONE", func(): Mic.disable())
	button("SALVAR E VOLTAR", func():
		Game.save_settings()
		if back == "pause": pause_screen()
		else: menu())
