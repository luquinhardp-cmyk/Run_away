extends Node
var passed := 0
var failed := 0
func check(ok: bool, title: String):
	if ok: passed+=1
	else: failed+=1;push_error(title)
	print("PASS " if ok else "FAIL ",title)
func _ready():
	Game.testing=true
	Game.record_results=false
	var physics_hz := Engine.physics_ticks_per_second
	for quality in 3:
		Game.settings.quality=quality
		Game.settings.render_scale=0.0
		Game.settings.fps_limit=0
		Game.settings.shadow_quality=-1
		Graphics.fingerprint=""
		Graphics.apply()
		check(is_equal_approx(Graphics.active_scale,[.8,1.0,1.0][quality]),"profile internal resolution %d"%quality)
		check(Engine.max_fps==[30,60,60][quality],"profile FPS target %d"%quality)
		check(get_viewport().msaa_3d==[Viewport.MSAA_DISABLED,Viewport.MSAA_2X,Viewport.MSAA_4X][quality],"profile MSAA %d"%quality)
		check(Engine.physics_ticks_per_second==physics_hz,"full physics retained %d"%quality)
	Game.settings.render_scale=1.7
	Game.settings.fps_limit=30
	Game.settings.shadow_quality=0
	Graphics.apply()
	check(is_equal_approx(Graphics.active_scale,1.7) and Engine.max_fps==30 and Graphics.shadow_tier==0,"independent resolution FPS and shadows")
	Game.save_settings()
	check(Engine.max_fps==30,"saving unrelated settings preserves custom FPS limit")
	var before := Graphics.active_scale
	Graphics.evaluate_window(50,40,4,3)
	check(is_equal_approx(Graphics.active_scale,before-.025),"overload lowers resolution gradually")
	for i in 100: Graphics.evaluate_window(50,40,4,3)
	check(is_equal_approx(Graphics.active_scale,Graphics.minimum_scale),"adaptive resolution honors minimum")
	before=Graphics.active_scale
	for i in 3: Graphics.evaluate_window(20,5,4,3)
	check(Graphics.active_scale==before,"headroom requires sustained twelve seconds")
	Graphics.evaluate_window(20,5,4,3)
	check(is_equal_approx(Graphics.active_scale,before+.025),"headroom increases resolution gradually")
	Graphics.set_scale(20)
	check(Graphics.active_scale==Graphics.maximum_scale,"adaptive resolution honors maximum")
	var mips := true
	for id in ["aged_concrete","weathered_iron","damp_wood"]:
		var texture: Texture2D=load("res://assets/textures/pbr/"+id+"_albedo.png")
		mips=mips and texture.get_image().has_mipmaps()
	check(mips,"close surfaces import real mip chains")
	print("GRAPHICS RESULT ",passed," passed; ",failed," failed")
	get_tree().quit(0 if failed==0 else 1)
