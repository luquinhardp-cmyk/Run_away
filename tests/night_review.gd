extends Node
var main: Node
func _ready():
 run.call_deferred()
func run():
 Game.testing = true
 Game.record_results = false
 Game.settings.seed = 70421
 main = preload("res://scenes/main/main.tscn").instantiate()
 add_child(main)
 main.start(false,false)
 Game.player.set_physics_process(false)
 Game.player.set_process_unhandled_input(false)
 Game.enemy.set_physics_process(false)
 main.level.events.enabled = false
 main.level.horror.enabled = false
 main.hud.set_process(false)
 main.hud.root.hide()
 Game.player.global_position = Vector3(0,0.1,12)
 Game.player.rotation = Vector3.ZERO
 Game.collect("lanterna")
 Game.player.lamp_on = true
 Game.player.apply_settings()
 var night = main.level.get_node("BloodMoonNight")
 night.flying.set_process(false)
 Game.player.camera.look_at(Game.player.camera.global_position+night.moon_direction*100)
 for i in 120: await get_tree().process_frame
 DirAccess.make_dir_recursive_absolute("res://docs/review/night")
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png("res://docs/review/night/01_moon.png")
 Game.player.camera.look_at(Game.player.camera.global_position+Vector3(0,0.18,1)*100)
 for i in 30: await get_tree().process_frame
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png("res://docs/review/night/02_forest.png")
 Game.player.camera.look_at(Game.player.camera.global_position+night.moon_direction*100)
 main.level.horror.since_scare = 100
 main.level.horror.since_chase = 100
 main.level.horror.active_until = 0
 main.level.horror.tension = 0
 Game.enemy.state = Game.enemy.State.PATROL
 night.flying.cooldown = 0
 night.flying.exploration = 100
 night.flying.begin(night.flying.patterns[0])
 night.flying._process(night.flying.duration*0.5)
 night.flying.animator.advance(0.5)
 night.flying.animator.pause()
 for i in 10: await get_tree().process_frame
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png("res://docs/review/night/03_shadow_moon.png")
 night.flying.finish_event()
 for quality in 3:
  Game.settings.quality = quality
  night.forest.apply_quality()
  night.apply_quality()
  for i in 10: await get_tree().process_frame
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("res://docs/review/night/quality_%d.png"%quality)
  print("QUALITY ",quality," draws=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," primitives=",Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
 print("NIGHT REVIEW trees=",night.forest.tree_count)
 main.to_menu()
 main.free()
 Sound.stop_all()
 get_tree().quit()
