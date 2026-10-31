extends CanvasLayer
signal close_requested
signal selected_item(id: String)
var root: Control
var panel: PanelContainer
var content: GridContainer
var grid: GridContainer
var details: VBoxContainer
var info: Label
var image: TextureRect
var message: Label
var use_button: Button
var equip_button: Button
var examine_button: Button
var drop_button: Button
var category: OptionButton
var selection := ""
var filter := "Todos"
var inspecting := false
var preview_container: SubViewportContainer
var preview_model: Node3D
var preview_camera: Camera3D
var image_zoom := 1.0
var inspection_tools: HBoxContainer
var rebuild_count := 0
func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = IndustrialUI.theme()
	var shade := ColorRect.new()
	shade.color = Color(0.015,.02,.015,.92)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	panel = PanelContainer.new()
	root.add_child(panel)
	panel.minimum_size_changed.connect(func(): layout.call_deferred())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",10)
	panel.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "E C O S  /  MOCHILA"
	title.add_theme_font_size_override("font_size",25)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(IndustrialUI.button("FECHAR","close",func(): close_requested.emit()))
	category = OptionButton.new()
	category.custom_minimum_size.y = 64
	category.item_selected.connect(func(index: int): filter=category.get_item_text(index); rebuild(false))
	column.add_child(category)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	content = GridContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("h_separation",20)
	scroll.add_child(content)
	grid = GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	content.add_child(grid)
	details = VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.custom_minimum_size.x = 370
	content.add_child(details)
	image = TextureRect.new()
	image.custom_minimum_size = Vector2(280,160)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.gui_input.connect(_inspect_input)
	details.add_child(image)
	info = Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(info)
	var buttons := GridContainer.new()
	buttons.columns = 2
	details.add_child(buttons)
	use_button=IndustrialUI.button("USAR","use",use_selected)
	equip_button=IndustrialUI.button("EQUIPAR","hand",equip_selected)
	examine_button=IndustrialUI.button("EXAMINAR","examine",examine_selected)
	drop_button=IndustrialUI.button("DESCARTAR","drop",drop_selected)
	for button in [use_button,equip_button,examine_button,drop_button]:
		button.custom_minimum_size.y = 64
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buttons.add_child(button)
	var zoom := HBoxContainer.new()
	inspection_tools = zoom
	details.add_child(zoom)
	zoom.hide()
	zoom.add_child(IndustrialUI.button("−","examine",func(): zoom_inspection(.15)))
	zoom.add_child(IndustrialUI.button("+","examine",func(): zoom_inspection(-.15)))
	zoom.add_child(IndustrialUI.button("VOLTAR","back",stop_inspection))
	message = Label.new()
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.text = "Selecione um item. A partida fica pausada enquanto a mochila estiver aberta."
	column.add_child(message)
	var missions := Label.new()
	missions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	missions.text = "OBJETIVO ATUAL: " + (TutorialLesson.STEPS[get_parent().manager.step][1] if Game.in_tutorial else Game.objective)
	column.add_child(missions)
	var all_missions := Label.new()
	all_missions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	all_missions.text = "OBJETIVOS DO COMPLEXO\n"
	for definition in Game.objectives.definitions: all_missions.text += definition.caption + "\n"
	all_missions.hide()
	details.add_child(all_missions)
	var objectives_button := IndustrialUI.button("CONSULTAR OBJETIVOS","examine",func():
		all_missions.visible = not all_missions.visible
		if Game.in_tutorial:
			get_parent().manager.flags["objectives_viewed"] = true
			get_parent().manager.check_objectives())
	column.add_child(objectives_button)
	Game.updated.connect(_updated)
	root.resized.connect(layout)
	layout()
	rebuild()
	panel.modulate.a = 0
	create_tween().tween_property(panel,"modulate:a",1,.12)
func layout() -> void:
	if not is_instance_valid(panel): return
	var margin := IndustrialUI.insets(root.size)
	panel.position = margin
	panel.size = root.size - margin*2
	content.columns = 1 if root.size.x < 950 or root.size.x/root.size.y < 1.3 else 2
	grid.columns = 3 if content.columns == 2 else clampi(int((root.size.x-80)/176),1,4)
func _updated() -> void:
	if Game.inventory_open: rebuild()
func rebuild(reset_categories := true) -> void:
	rebuild_count += 1
	var owned := InventoryCatalog.owned()
	owned.sort_custom(func(a: String,b: String): return str(InventoryCatalog.data(a).name)<str(InventoryCatalog.data(b).name))
	if reset_categories:
		category.clear()
		category.add_item("Todos")
		var categories: Array[String] = []
		for id in owned:
			var value: String = InventoryCatalog.data(id).category
			if value not in categories: categories.append(value)
		categories.sort()
		for value in categories: category.add_item(value)
		var selected_index := 0
		for i in category.item_count:
			if category.get_item_text(i) == filter: selected_index = i
		category.select(selected_index)
		filter = category.get_item_text(selected_index)
	for child in grid.get_children(): grid.remove_child(child); child.queue_free()
	for id in owned:
		var entry := InventoryCatalog.data(id)
		if filter != "Todos" and entry.category != filter: continue
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(168,154)
		var visual := VBoxContainer.new()
		visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(visual)
		visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		visual.offset_left = 8; visual.offset_right = -8; visual.offset_top = 8; visual.offset_bottom = -8
		var thumbnail := TextureRect.new()
		thumbnail.texture = InventoryCatalog.image(id)
		thumbnail.custom_minimum_size = Vector2(110,72)
		thumbnail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		thumbnail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		visual.add_child(thumbnail)
		var caption := Label.new()
		caption.text = "%s\n×%d%s" % [entry.name,entry.quantity," · ESSENCIAL" if entry.essential else ""]
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caption.add_theme_font_size_override("font_size",14)
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		visual.add_child(caption)
		slot.tooltip_text = entry.name
		slot.toggle_mode = true
		slot.button_pressed = selection == id
		slot.pressed.connect(func(): select(id))
		grid.add_child(slot)
	if owned.is_empty():
		var empty := Label.new()
		empty.text = "MOCHILA VAZIA\nExplore e colete objetos."
		grid.add_child(empty)
	if selection not in owned: selection = owned[0] if not owned.is_empty() else ""
	show_details()
func select(id: String) -> void:
	selection = id
	stop_inspection()
	selected_item.emit(id)
	ui_sound()
	rebuild(false)
func show_details() -> void:
	var present := not selection.is_empty() and selection in InventoryCatalog.owned()
	for button in [use_button,equip_button,examine_button,drop_button]: button.disabled = not present
	if not present: info.text="Nenhum item selecionado."; image.texture=null; return
	var entry := InventoryCatalog.data(selection)
	image.texture = InventoryCatalog.image(selection)
	info.text = "%s\n%s · Quantidade: %d\n\n%s\n%s" % [entry.name,entry.category,entry.quantity,entry.description,"Item essencial: descarte bloqueado." if entry.essential else ""]
	use_button.disabled = not can_use()
	equip_button.disabled = selection not in ["lanterna","throwables"]
	drop_button.disabled = entry.essential
	use_button.tooltip_text = "Aproxime-se do mecanismo compatível, mire nele e abra a mochila." if use_button.disabled else "Usar no objeto sob a mira"
	drop_button.tooltip_text = "Itens essenciais não podem ser descartados." if entry.essential else "Soltar um objeto físico no mundo"
func can_use() -> bool:
	if selection == "lanterna": return true
	if not is_instance_valid(Game.player) or not is_instance_valid(Game.player.focus): return false
	var target: Node3D = Game.player.focus
	if Game.player.camera.global_position.distance_to(target.global_position)>2.9: return false
	return (selection=="fusivel" and target.get("kind")=="fuse_panel") or (selection=="cartao" and target.get("kind")=="exit") or (selection in ["chave_oficina","tutorial_key"] and target.get("required_key")==selection)
func use_selected() -> void:
	if not can_use(): message.text="Mire em um mecanismo compatível próximo antes de abrir a mochila."; return
	var target: Node = Game.player.focus
	close_requested.emit()
	if selection == "lanterna": Game.player.toggle_lamp()
	elif is_instance_valid(target): target.interact(Game.player)
func equip_selected() -> void:
	if selection not in InventoryCatalog.owned(): return
	if selection=="lanterna":
		close_requested.emit()
		if not Game.player.lamp_on: Game.player.toggle_lamp()
	elif selection=="throwables": Game.player.throw_selected=true; close_requested.emit()
func drop_selected() -> void:
	if selection not in InventoryCatalog.owned() or InventoryCatalog.data(selection).essential: return
	close_requested.emit()
	if selection.begins_with("held:"): Game.player.manipulator.release()
	elif selection=="throwables": Game.player.drop_throwable()
func ui_sound() -> void:
	Sound.ui_click()
func examine_selected() -> void:
	if selection not in InventoryCatalog.owned(): return
	stop_inspection()
	inspecting = true
	inspection_tools.show()
	info.text += "\n\nINSPEÇÃO: arraste para girar; +/− para aproximar. VOLTAR retorna aos detalhes."
	var model_id: String = InventoryCatalog.data(selection).model
	if int(Game.settings.quality)==0 or not ResourceLoader.exists("res://assets/models/library/"+model_id+"_low.glb"):
		image.custom_minimum_size.y = 260
		message.text = "Inspeção 2D ampliada — perfil leve."
		return
	preview_container = SubViewportContainer.new()
	preview_container.custom_minimum_size = Vector2(280,210)
	preview_container.stretch = true
	preview_container.gui_input.connect(_inspect_input)
	details.add_child(preview_container)
	details.move_child(preview_container,0)
	var view := SubViewport.new()
	view.size = Vector2i(512,384)
	view.own_world_3d = true
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ONCE
	preview_container.add_child(view)
	var stage := Node3D.new()
	view.add_child(stage)
	preview_model = Node3D.new()
	stage.add_child(preview_model)
	var model := ModelLibrary.instantiate(model_id,true)
	preview_model.add_child(model)
	var bounds := ModelLibrary.bounds(model)
	var scale_value := 1.5/maxf(.01,maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z)))
	model.scale = Vector3.ONE*scale_value
	model.position = -bounds.get_center()*scale_value
	preview_camera = Camera3D.new()
	preview_camera.position = Vector3(2,1.2,2.5)
	stage.add_child(preview_camera)
	preview_camera.look_at(Vector3.ZERO)
	preview_camera.current = true
	for pos in [Vector3(2,3,3),Vector3(-2,1,1)]:
		var light := OmniLight3D.new()
		light.position = pos
		light.omni_range = 8
		light.light_energy = 2
		stage.add_child(light)
	image.hide()
	message.text = "Inspeção 3D — um único modelo; renderiza apenas quando você interage."
func _inspect_input(event: InputEvent) -> void:
	if not inspecting: return
	var drag := Vector2.ZERO
	if event is InputEventScreenDrag: drag = event.relative
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT: drag = event.relative
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: zoom_inspection(-.15)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: zoom_inspection(.15)
	if is_instance_valid(preview_model) and drag.length()>0:
		preview_model.rotate_y(drag.x*.015)
		preview_model.rotate_x(drag.y*.01)
		preview_container.get_child(0).render_target_update_mode = SubViewport.UPDATE_ONCE
func zoom_inspection(amount: float) -> void:
	if not inspecting: return
	if is_instance_valid(preview_camera):
		preview_camera.position = preview_camera.position.normalized()*clampf(preview_camera.position.length()+amount,1.8,5)
		preview_container.get_child(0).render_target_update_mode = SubViewport.UPDATE_ONCE
	else:
		image_zoom = clampf(image_zoom-amount,.8,2)
		image.custom_minimum_size.y = 260*image_zoom
func stop_inspection() -> void:
	inspecting = false
	if is_instance_valid(inspection_tools): inspection_tools.hide()
	image_zoom = 1.0
	if is_instance_valid(preview_container): details.remove_child(preview_container); preview_container.queue_free()
	preview_container = null
	preview_model = null
	preview_camera = null
	image.show()
	image.custom_minimum_size.y = 160
	show_details()
