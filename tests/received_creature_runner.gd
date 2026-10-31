extends Node
var passed := 0
var failed := 0
func check(ok: bool,title: String):
	if ok: passed+=1
	else: failed+=1;push_error(title)
	print("PASS " if ok else "FAIL ",title)
func _ready(): run.call_deferred()
func run():
	Game.testing=true
	Game.record_results=false
	var totals: Array[int]=[]
	for quality in [1,0]:
		Game.settings.quality=quality
		var visual:=Node3D.new()
		visual.set_script(preload("res://scripts/enemy/escutador_visual.gd"))
		add_child(visual)
		check(visual.skeleton.get_bone_count()==29,"compatible 29 bone rig quality %d"%quality)
		check(visual.clip_names.size()==23,"23 real imported clips quality %d"%quality)
		var mesh: MeshInstance3D=visual.model.find_children("*","MeshInstance3D",true,false)[0]
		check(not mesh.skeleton.is_empty() and mesh.mesh.get_surface_count()<=4,"single skinned mesh with at most four surfaces")
		var triangles:=0
		var weights_ok:=true
		for surface in mesh.mesh.get_surface_count():
			var arrays:=mesh.mesh.surface_get_arrays(surface)
			triangles+=arrays[Mesh.ARRAY_INDEX].size()/3
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var weights: PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
			var stride: int=weights.size()/maxi(1,vertices.size())
			weights_ok=weights_ok and stride in [4,8]
			for vertex in vertices.size():
				var total:=0.0
				for j in stride:total+=weights[vertex*stride+j]
				weights_ok=weights_ok and absf(total-1.0)<.025
			var mat: StandardMaterial3D=mesh.get_surface_override_material(surface)
			check(mat!=null and mat.resource_name.begins_with("Received_"),"dedicated material surface %d"%surface)
			if mat.resource_name=="Received_Skin":
				check(mat.albedo_texture.get_width()==(512 if quality==0 else 1024),"profile texture size")
				check(mat.albedo_texture.get_image().has_mipmaps(),"skin mipmaps")
		check(weights_ok,"normalized skin weights without unbound vertices")
		totals.append(triangles)
		var aabb: AABB=mesh.mesh.get_aabb()
		check(aabb.size.y>2.3 and aabb.size.y<2.7 and aabb.position.y>-.05,"world scale and floor origin")
		for clip in visual.clip_names:
			visual.animator.play(visual.clip_names[clip],0)
			var animation: Animation=visual.animator.get_animation(visual.clip_names[clip])
			var finite:=true
			for fraction in [0.0,.25,.5,.75,.99]:
				visual.animator.seek(animation.length*fraction,true)
				visual.skeleton.force_update_all_bone_transforms()
				for bone in visual.skeleton.get_bone_count():
					var pose: Transform3D=visual.skeleton.get_bone_global_pose(bone)
					finite=finite and pose.origin.is_finite() and pose.origin.length()<4
			check(finite,"bounded sampled skeletal motion "+clip)
		visual.animator.play(visual.clip_names.listen,0)
		visual.animator.seek(0,true)
		visual.skeleton.force_update_all_bone_transforms()
		var head: int=visual.skeleton.find_bone("head")
		var before: Basis=visual.skeleton.get_bone_global_pose(head).basis
		var foot: int=visual.skeleton.find_bone("foot_L")
		var foot_before: Vector3=visual.skeleton.get_bone_global_pose(foot).origin
		var root: int=visual.skeleton.find_bone("root")
		var root_before: Vector3=visual.skeleton.get_bone_global_pose(root).origin
		visual.animator.seek(.8,true)
		visual.skeleton.force_update_all_bone_transforms()
		check(not before.is_equal_approx(visual.skeleton.get_bone_global_pose(head).basis),"listening visibly articulates head")
		check(foot_before.distance_to(visual.skeleton.get_bone_global_pose(foot).origin)<.005,"listening keeps foot planted")
		check(root_before.distance_to(visual.skeleton.get_bone_global_pose(root).origin)<.001,"presentation does not drive physical root motion")
		var capture_poses: Array[String]=[]
		for id in ["front","side","rear","hide","corridor","chase","silent","dark"]:
			visual.animator.play(visual.clip_names["capture_"+id],0)
			visual.animator.seek(.6,true)
			visual.skeleton.force_update_all_bone_transforms()
			var signature: String=str(visual.skeleton.get_bone_global_pose(head).basis)
			if signature not in capture_poses:capture_poses.append(signature)
		check(capture_poses.size()==8,"eight captures have distinct skeletal poses")
		visual.animator.speed_scale=1.15
		visual.play_capture("capture_front")
		check(is_equal_approx(visual.animator.speed_scale,1.0),"capture timing independent of chase playback speed")
		for calibration in [["patrol",1.55],["chase",3.35]]:
			visual.animator.play(visual.clip_names[calibration[0]],0)
			var length: float=visual.animator.get_animation(visual.clip_names[calibration[0]]).length
			visual.animator.seek(length*.1,true);visual.skeleton.force_update_all_bone_transforms()
			var first: Vector3=visual.skeleton.get_bone_global_pose(foot).origin
			visual.animator.seek(length*.3,true);visual.skeleton.force_update_all_bone_transforms()
			var last: Vector3=visual.skeleton.get_bone_global_pose(foot).origin
			var stance_speed: float=absf(last.z-first.z)/(length*.2)
			check(absf(stance_speed-calibration[1])<.35,"nominal planted-foot speed matches "+calibration[0])
		check(visual.head_position().is_finite(),"capture head anchor valid")
		visual.free()
	check(totals[1]<totals[0]*.60,"low mesh materially reduces triangle count")
	check(totals[0]<32000,"main mesh triangle budget")
	print("RECEIVED CREATURE RESULT ",passed," passed; ",failed," failed")
	get_tree().quit(0 if failed==0 else 1)
