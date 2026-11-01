extends Node
func _ready(): run.call_deferred()
func run():
 Game.testing=true
 Game.record_results=false
 var main=preload("res://scenes/main/main.tscn").instantiate()
 add_child(main)
 main.start(false,false)
 await get_tree().physics_frame
 await get_tree().physics_frame
 var points=[]
 for x in [-10.5,-2.5,0.0,2.5,3.0,6.0,10.5]:
  for z in [0.0,1.0,1.8,2.2,12.0,20.5]:
   var hit=main.level.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x,.15,z),Vector3(x,-4,z),1))
   points.append({"x":x,"z":z,"ground":not hit.is_empty(),"height":hit.position.y if not hit.is_empty() else -999})
 var route_points=[]
 for cell in main.level.cells:
  for offset in [Vector2.ZERO,Vector2(-1.5,-1.5),Vector2(1.5,-1.5),Vector2(-1.5,1.5),Vector2(1.5,1.5)]:
   var pos=Vector3(cell.x*4+offset.x,.15,-cell.y*4+offset.y)
   var hit=main.level.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(pos,pos-Vector3.UP*4,1))
   route_points.append({"position":[pos.x,pos.y,pos.z],"ground":not hit.is_empty()})
 for x in [-21.0,-19.0,-17.0,-15.0,-13.0,-11.0]:
  for z in [-32.5,-32.0,-31.5]:
   var pos=Vector3(x,.15,z)
   var hit=main.level.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(pos,pos-Vector3.UP*4,1))
   route_points.append({"position":[pos.x,pos.y,pos.z],"ground":not hit.is_empty()})
 var collider_issues=[]
 var collider_count=0
 for shape in main.level.find_children("*","CollisionShape3D",true,false):
  if shape.get_parent() is CollisionObject3D and shape.get_parent().collision_layer&1:
   collider_count+=1
   if shape.shape==null or shape.disabled or shape.global_basis.determinant()<=0:collider_issues.append(str(shape.get_path()))
 var label="before"
 var args=OS.get_cmdline_user_args()
 if args.size()>0:label=args[0]
 Game.write_json("res://docs/review/stability/"+label+"-map.json",{"points":points,"route_points":route_points,"collider_count":collider_count,"collider_issues":collider_issues,"startup_ms":main.level.startup_ms})
 main.free()
 Sound.stop_all()
 for i in 8:await get_tree().process_frame
 print("MAP AUDIT COMPLETE ",label)
 get_tree().quit()
