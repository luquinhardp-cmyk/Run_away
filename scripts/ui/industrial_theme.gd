class_name IndustrialUI
extends RefCounted
static var icons: Dictionary = {}
static func insets(size: Vector2) -> Vector2:
	var margin := Vector2(24,24)
	if OS.has_feature("android") or OS.has_feature("ios"):
		var safe := DisplayServer.get_display_safe_area()
		var screen := DisplayServer.screen_get_size()
		if screen.x>0 and screen.y>0:
			margin.x = maxf(24,maxf(safe.position.x,screen.x-safe.end.x)*size.x/screen.x)
			margin.y = maxf(24,maxf(safe.position.y,screen.y-safe.end.y)*size.y/screen.y)
	return margin
static func icon(id: String) -> Texture2D:
	if not icons.has(id): icons[id] = load("res://assets/ui/actions/"+id+".svg")
	return icons[id]
static func panel(color := Color("191d1b"), border := Color("444641")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.set_content_margin_all(12)
	return style
static func theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 18
	result.set_stylebox("panel","PanelContainer",panel())
	for state in ["normal","hover","pressed","disabled","focus"]:
		var color := Color("191d1b")
		var border := Color("444641")
		if state in ["hover","focus"]: border = Color("b19a64")
		if state == "pressed": color = Color("354438"); border = Color("b19a64")
		if state == "disabled": color = Color("0b0d0c"); border = Color("252a26")
		result.set_stylebox(state,"Button",panel(color,border))
	result.set_color("font_color","Button",Color("ddd6c2"))
	result.set_color("font_disabled_color","Button",Color("74796f"))
	result.set_color("font_color","Label",Color("ddd6c2"))
	return result
static func button(text: String, action: String, callback: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.icon = icon(action)
	node.expand_icon = true
	node.add_theme_constant_override("icon_max_width",28)
	node.custom_minimum_size = Vector2(120,64)
	node.pressed.connect(callback)
	return node
