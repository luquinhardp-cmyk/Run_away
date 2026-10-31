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
var account_status: Label
var menu_status: Label

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
	Cloud.changed.connect(_cloud_updated)
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
	button("CONTA / PROGRESSO", account_screen)
	menu_status = text(Cloud.status, 16)
	if not OS.has_feature("android") and not OS.has_feature("web"): button("SAIR", func(): get_tree().quit())
	text("Versão 0.9 • Prévia do Escutador\nRecomendado: fones de ouvido. Sustos moderados, sem flashes.", 16)

func _cloud_updated() -> void:
	if screen == "menu" and is_instance_valid(menu_status): menu_status.text = Cloud.status
	if screen == "account" and is_instance_valid(account_status): account_status.text = Cloud.status

func account_screen() -> void:
	screen = "account"
	clear()
	text("CONTA / PROGRESSO", 34)
	account_status = text(Cloud.status, 18)
	var totals: Dictionary = Game.local_stats() if Cloud.uid.is_empty() else Cloud.stats
	text("Pontos: %d  ·  Partidas: %d  ·  Fugas: %d\nMelhor fuga: %s" % [int(totals.get("totalPoints", 0)), int(totals.get("runs", 0)), int(totals.get("escapes", 0)), Game.format_time(int(totals.get("bestEscapeMs", 0))) if int(totals.get("escapes", 0)) > 0 else "—"])
	text("100 pontos por item · 300 pela energia · 500 pela fuga. O tempo não conta pausas.\nAo retomar, você volta à enfermaria com os itens e mecanismos salvos.", 16)
	if Cloud.uid.is_empty():
		text("Entre para levar o progresso a outros aparelhos. Como visitante, os dados ficam neste navegador ou aplicativo.", 16)
		var address := LineEdit.new()
		address.placeholder_text = "E-mail"
		address.custom_minimum_size.y = 48
		address.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_EMAIL_ADDRESS
		column.add_child(address)
		var password := LineEdit.new()
		password.placeholder_text = "Senha (mínimo 6 caracteres)"
		password.secret = true
		password.custom_minimum_size.y = 48
		column.add_child(password)
		button("ENTRAR", func():
			await Cloud.authenticate(address.text, password.text)
			if screen == "account" and not Cloud.uid.is_empty(): account_screen())
		button("CRIAR CONTA", func():
			await Cloud.authenticate(address.text, password.text, true)
			if screen == "account" and not Cloud.uid.is_empty(): account_screen())
		button("ESQUECI MINHA SENHA", func(): Cloud.reset_password(address.text))
	else:
		text(Cloud.email, 18)
		text("Partidas aguardando envio: " + str(Cloud.pending.runs.size()), 16)
		if not Cloud.conflict.is_empty():
			text("Há progresso diferente neste aparelho e na nuvem. Escolha qual continuar; os resultados já concluídos serão preservados.")
			button("USAR CHECKPOINT DA NUVEM", func(): Cloud.choose_checkpoint(true); account_screen())
			button("USAR CHECKPOINT DESTE APARELHO", func(): Cloud.choose_checkpoint(false); account_screen())
		button("SINCRONIZAR / ATUALIZAR", func():
			await Cloud.sync(true)
			if screen == "account": account_screen())
		button("IMPORTAR CHECKPOINT DO VISITANTE", func(): Cloud.import_guest(); account_screen())
		text("A importação substitui o checkpoint desta conta pelo do visitante deste aparelho. Não transfere pontos de visitante.", 16)
		button("SAIR DA CONTA", func(): Cloud.sign_out(); account_screen())
	button("VOLTAR", func():
		if not Cloud.busy and not Cloud.syncing: menu())

func consent_screen(resume: bool) -> void:
	if Cloud.busy or Cloud.syncing or not Cloud.conflict.is_empty():
		account_screen()
		return
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
	if Game.playing and Game.record_results: Game.save_checkpoint()
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
	text("Tempo ativo: %s · Pontos nesta partida: %d\n%s" % [Game.format_time(Game.elapsed_ms), Game.last_score, "Resultado guardado para sincronizar com sua conta." if not Cloud.uid.is_empty() else "Entre em CONTA / PROGRESSO para salvar futuras partidas na nuvem."])
	text("O ar frio do lado de fora nunca pareceu tão vivo." if won else "A instalação guardou mais um silêncio.\nAnde agachado, quebre a linha de visão e evite ruídos perto dos armários.")
	button("TENTAR NOVAMENTE", func(): start(false, false))
	if not Game.checkpoint.is_empty(): button("RETOMAR CHECKPOINT", func(): start(true, false))
	button("MENU PRINCIPAL", to_menu)

func settings_screen(back: String) -> void:
	screen = "settings"
	clear()
	text("CONFIGURAÇÕES", 34)
	text("Dificuldade e seed são aplicadas à próxima nova sessão.", 17)
	var difficulty := OptionButton.new()
	for name in ["Fácil", "Normal", "Difícil"]: difficulty.add_item(name)
	difficulty.selected = int(Game.settings.get("difficulty", 1))
	difficulty.item_selected.connect(func(index: int): Game.settings.difficulty = index; Game.save_settings())
	column.add_child(difficulty)
	var seed_input := LineEdit.new()
	seed_input.placeholder_text = "Seed: 0 sorteia uma partida nova"
	seed_input.text = str(Game.settings.get("seed", 0))
	seed_input.text_submitted.connect(func(value: String): Game.settings.seed = clampi(value.to_int(), 0, 2147483647); Game.save_settings())
	seed_input.focus_exited.connect(func(): Game.settings.seed = clampi(seed_input.text.to_int(), 0, 2147483647); Game.save_settings())
	column.add_child(seed_input)
	var metrics := CheckBox.new()
	metrics.text = "Registrar métricas locais (FPS, IA, áudio, memória)"
	metrics.button_pressed = Game.settings.get("metrics", false)
	metrics.toggled.connect(func(value: bool): Game.settings.metrics = value; Game.save_settings())
	column.add_child(metrics)
	text("GRÁFICOS · Baixo: meta 30 FPS. Médio/alto: até 60, conforme o aparelho.",17)
	_graphics_choice("Limite de FPS","fps_limit",["Pelo perfil","30 FPS","60 FPS"],[0,30,60])
	_graphics_choice("Resolução 3D","render_scale",["Pelo perfil","80%","100%","130%","170% · maior consumo"],[0.0,0.8,1.0,1.3,1.7])
	_graphics_choice("Sombras","shadow_quality",["Pelo perfil","Desativadas","Lanterna","Lanterna e lua"],[-1,0,1,2])
	_graphics_choice("Distância da vegetação","vegetation_distance",["Pelo perfil","60 m","90 m","115 m"],[0.0,60.0,90.0,115.0])
	var adaptive := CheckBox.new()
	adaptive.text = "Ajustar resolução gradualmente para manter fluidez"
	adaptive.button_pressed = Game.settings.get("adaptive_resolution",false)
	adaptive.toggled.connect(func(value: bool): Game.settings.adaptive_resolution=value;Game.save_settings())
	column.add_child(adaptive)
	for option in [["visual_scares", "Efeitos visuais de terror"], ["light_variation", "Variações lentas de iluminação"]]:
		var toggle := CheckBox.new()
		toggle.text = option[1]
		toggle.button_pressed = Game.settings.get(option[0], true)
		var setting: String = option[0]
		toggle.toggled.connect(func(value: bool): Game.settings[setting] = value; Game.save_settings())
		column.add_child(toggle)
	text("Movimento da câmera: zero desativa balanço e movimento de captura.", 17)
	var camera_motion := HSlider.new()
	camera_motion.min_value = 0
	camera_motion.max_value = 1
	camera_motion.step = 0.1
	camera_motion.value = Game.settings.get("camera_motion", 0.5)
	camera_motion.value_changed.connect(func(value: float): Game.settings.camera_motion = value; Game.save_settings())
	column.add_child(camera_motion)
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
func _graphics_choice(caption: String,key: String,labels: Array,values: Array):
	text(caption,17)
	var choice := OptionButton.new()
	for label in labels: choice.add_item(label)
	for i in values.size():
		if is_equal_approx(float(Game.settings.get(key,values[0])),float(values[i])): choice.selected=i
	choice.item_selected.connect(func(index: int): Game.settings[key]=values[index];Game.save_settings())
	column.add_child(choice)
