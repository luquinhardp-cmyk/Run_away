extends Node
var passed := 0
var failed := 0
var main: Node
func check(ok: bool, title: String):
 if ok: passed += 1
 else: failed += 1; push_error(title)
 print("PASS " if ok else "FAIL ",title)
func _ready(): run.call_deferred()
func run():
 Game.testing = true
 Game.record_results = false
 main = preload("res://scenes/main/main.tscn").instantiate()
 add_child(main)
 main.start(false,false)
 Game.player.set_physics_process(false)
 Game.player.set_process_unhandled_input(false)
 Game.enemy.set_physics_process(false)
 main.level.events.enabled = false
 main.level.horror.enabled = false
 var night = main.level.get_node("BloodMoonNight")
 var flight = night.flying
 flight.set_process(false)
 night.ambience.set_process(false)
 Game.player.global_position = Vector3(0,0.1,12)
 Game.player.rotation = Vector3.ZERO
 Game.player.camera.look_at(Game.player.camera.global_position+night.moon_direction*100)
 for i in 5: await get_tree().physics_frame
 var director = main.level.horror
 director.since_scare = 100
 director.since_chase = 100
 director.active_until = 0
 director.tension = 0
 Game.enemy.state = Game.enemy.State.PATROL
 check(night.is_outdoors(Game.player.camera.global_position),"yard is outdoors with overhead ray")
 var roof := StaticBody3D.new()
 var roof_shape := CollisionShape3D.new()
 var box := BoxShape3D.new()
 box.size = Vector3(8,0.3,8)
 roof_shape.shape = box
 roof.add_child(roof_shape)
 main.level.add_child(roof)
 roof.global_position = Vector3(0,4,12)
 for i in 3: await get_tree().physics_frame
 check(not night.is_outdoors(Game.player.camera.global_position),"real overhead obstacle blocks yard eligibility")
 roof.free()
 for i in 3: await get_tree().physics_frame
 check(not night.is_outdoors(Vector3(0,1.6,-4)),"interior excluded")
 check(not night.is_outdoors(Vector3(-18,-0.3,-32)),"basement excluded")
 check(flight.looking_up(),"actual camera direction sees sky")
 Game.player.camera.look_at(Game.player.camera.global_position+Vector3(0,0,1))
 check(not flight.looking_up(),"horizontal gaze rejected")
 Game.player.camera.look_at(Game.player.camera.global_position+night.moon_direction*100)
 check(flight.cooldown>=240 and flight.cooldown<=540,"initial cooldown 4 to 9 minutes")
 check(not flight.begin(flight.patterns[0]),"initial cooldown prevents spawn")
 flight.cooldown = 0
 flight.exploration = 100
 Game.capture_in_progress = true
 check(not flight.compatible(),"capture blocks flight")
 Game.capture_in_progress = false
 Game.enemy.state = Game.enemy.State.CHASE
 check(not flight.compatible(),"terrestrial chase blocks flight")
 Game.enemy.state = Game.enemy.State.PATROL
 director.active_until = director.clock+10
 check(not flight.compatible(),"incompatible director event blocks flight")
 director.active_until = 0
 check(night.forest.tree_count==736,"736 trees across four layers")
 check(night.forest.has_node("ContinuousForestHorizon"),"continuous surrounding horizon")
 check(get_tree().get_nodes_in_group("flying_shadows").size()==1,"single pooled winged entity")
 for quality in 3:
  Game.settings.quality = quality
  night.forest.apply_quality()
  flight._quality()
  check(night.forest.batches[0].multimesh.visible_instance_count>0,"near forest preserved quality %d"%quality)
  check(flight.low==(quality==0),"model LOD quality %d"%quality)
 for pattern in flight.patterns:
  director.active_until = 0
  director.since_scare = 100
  flight.cooldown = 0
  check(flight.begin(pattern),"starts contextual pattern "+pattern.id)
  check(flight.play_clip(pattern.clip),"animation exists "+pattern.clip)
  var start = flight.point_at(0)
  var end = flight.point_at(1)
  check(start.distance_to(end)>10 and flight.point_at(0.5).is_finite(),"continuous trajectory "+pattern.id)
  flight._process(flight.duration*0.5)
  check(flight.active,"own director reservation does not cancel "+pattern.id)
  var previous: float = flight.elapsed
  Game.paused = true
  flight._process(2)
  check(flight.elapsed==previous,"pause freezes trajectory "+pattern.id)
  Game.paused = false
  if pattern.id=="moon_cross" or pattern.id=="moon_silent":
   var direction = (flight.point_at(0.5)-Game.player.camera.global_position).normalized()
   check(direction.dot(night.moon_direction)>0.995,"crosses lunar disk "+pattern.id)
  if pattern.id=="moon_silent": check(not flight.scream.playing and not flight.wing.playing and not flight.whoosh.playing,"completely silent lunar passage")
  if pattern.id=="unseen_cry":
   check(flight.materials[0].albedo_color.a==0 and not flight.vocal_played,"shadow gone before delayed cry")
   flight._process(flight.duration*0.1)
   check(flight.vocal_played,"cry after disappearance")
  flight.finish_event()
  check(not flight.entity.visible and flight.cooldown>=240,"hidden and cooldown reset "+pattern.id)
  var repeats := false
  for i in 30:
   if flight.choose().id==flight.last_id: repeats = true
  check(not repeats,"no consecutive repetition "+pattern.id)
 check(flight.scream.max_distance==170 and flight.scream.volume_db<=-17,"bounded spatial scream")
 check(night.ambience.voices.size()==3,"three bounded forest voices")
 main.to_menu()
 main.free()
 Sound.stop_all()
 await get_tree().create_timer(0.3).timeout
 print("NIGHT RESULT ",passed," passed; ",failed," failed")
 get_tree().quit(0 if failed==0 else 1)
