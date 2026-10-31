extends Node3D
var facility: Node3D
var environment: Environment
var sky_material: ShaderMaterial
var moon_direction := Vector3(0.15,0.70,0.70).normalized()
var forest: Node3D
var flying: Node3D
var ambience: Node
var moon_light: DirectionalLight3D
var outdoors := false
var evaluation := 0.0
var exterior_blend := 0.0
func _ready() -> void:
	name = "BloodMoonNight"
	facility = get_parent()
	for child in facility.get_children():
		if child is WorldEnvironment: environment = child.environment; break
	var sky := Sky.new()
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	sky.process_mode = Sky.PROCESS_MODE_AUTOMATIC
	sky_material = ShaderMaterial.new()
	sky_material.shader = preload("res://shaders/blood_moon.gdshader")
	sky_material.set_shader_parameter("moon_texture",preload("res://assets/textures/night/moon_craters.png"))
	sky_material.set_shader_parameter("moon_direction",moon_direction)
	sky.sky_material = sky_material
	environment.sky = sky
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	environment.fog_sky_affect = 0.04
	moon_light = DirectionalLight3D.new()
	moon_light.light_color = Color(0.52,0.1,0.06)
	moon_light.light_energy = 0.055
	add_child(moon_light)
	moon_light.look_at(-moon_direction)
	forest = Node3D.new()
	forest.set_script(preload("res://scripts/environment/dark_forest.gd"))
	add_child(forest)
	flying = Node3D.new()
	flying.set_script(preload("res://scripts/environment/flying_shadow_event.gd"))
	add_child(flying)
	ambience = Node.new()
	ambience.set_script(preload("res://scripts/environment/forest_audio.gd"))
	add_child(ambience)
	Game.updated.connect(apply_quality)
	apply_quality()
func is_outdoors(point: Vector3) -> bool:
	# The currently playable exterior is the fenced yard, not the basement or roof.
	if absf(point.x)>10.9 or point.z<2.3 or point.z>21.0 or point.y<0.2 or point.y>4: return false
	var ray := PhysicsRayQueryParameters3D.create(point,point+Vector3.UP*60,1)
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
func sky_clear(camera: Camera3D) -> bool:
	var ray := PhysicsRayQueryParameters3D.create(camera.global_position,camera.global_position-camera.global_basis.z*100,1)
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
func apply_quality() -> void:
	moon_light.shadow_enabled = Game.settings.quality>=2
	moon_light.directional_shadow_max_distance = 32
	sky_material.set_shader_parameter("star_strength",0.24)
func _process(delta: float) -> void:
	if not Game.playing or Game.paused: return
	evaluation -= delta
	if evaluation<=0 and is_instance_valid(Game.player):
		evaluation = 0.25
		outdoors = is_outdoors(Game.player.camera.global_position)
	exterior_blend = move_toward(exterior_blend,1.0 if outdoors else 0.0,delta*0.6)
	environment.ambient_light_energy = lerpf(0.38,0.075,exterior_blend)
	environment.fog_density = lerpf(0.017,0.013,exterior_blend)
	environment.fog_light_color = Color(0.06,0.07,0.055).lerp(Color(0.017,0.011,0.014),exterior_blend)
