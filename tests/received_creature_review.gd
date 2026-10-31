extends Node3D
func _ready(): run.call_deferred()
func run():
	Game.testing=true
	Game.record_results=false
	Game.settings.quality=1
	var visual:=Node3D.new()
	visual.set_script(preload("res://scripts/enemy/escutador_visual.gd"));add_child(visual)
	var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color(.035,.035,.035);env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color(.45,.48,.53);env.environment.ambient_light_energy=.35;add_child(env)
	for entry in [[Vector3(-2,3.5,-3),2.2,Color(.84,.88,1)],[Vector3(2,2,-1),.8,Color(1,.86,.73)],[Vector3(0,3,2),1.8,Color(.7,.8,1)]]:
		var light:=OmniLight3D.new();light.position=entry[0];light.light_energy=entry[1];light.light_color=entry[2];light.omni_range=8;add_child(light)
	var camera:=Camera3D.new();camera.fov=40;add_child(camera);camera.current=true
	DirAccess.make_dir_recursive_absolute("res://docs/review/escutador_received")
	for entry in [["refined_front",Vector3(1.7,1.6,-4.2),Vector3(0,1.35,0),"idle",0.0],["refined_face",Vector3(.5,2.3,-1.35),Vector3(0,2.23,-.18),"idle",0.0],["refined_listen",Vector3(.5,2.3,-1.35),Vector3(0,2.23,-.18),"listen",.8],["refined_back",Vector3(1.6,1.7,4.2),Vector3(0,1.35,0),"idle",0.0],["refined_chase",Vector3(1.7,1.6,-4.2),Vector3(0,1.35,0),"chase",.25]]:
		visual.animator.play(visual.clip_names[entry[3]],0);visual.animator.seek(entry[4],true);visual.animator.pause();camera.position=entry[1];camera.look_at(entry[2])
		for i in 5:await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://docs/review/escutador_received/"+entry[0]+".png")
	get_tree().quit()
