extends Node
## Renderer-compatible profiles; dynamic resolution is opt-in, never physics scaling.
const SCALES := [0.80,1.0,1.0]
const MINIMUM := [0.70,0.85,0.90]
var active_scale := 1.0
var maximum_scale := 1.0
var minimum_scale := 0.85
var fps_target := 60
var shadow_tier := 1
var fingerprint := ""
var window_ms: Array[float] = []
var window_clock := 0.0
var headroom := 0.0
var settle := 3.0
var adjustments := 0
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.updated.connect(apply)
	apply()
func apply():
	var quality := clampi(int(Game.settings.quality),0,2)
	var values := [quality,Game.settings.get("fps_limit",0),Game.settings.get("render_scale",0.0),Game.settings.get("shadow_quality",-1),Game.settings.get("adaptive_resolution",false),Game.settings.get("metrics",false)]
	var next := str(values)
	if next==fingerprint: return
	fingerprint = next
	fps_target = int(Game.settings.get("fps_limit",0))
	if fps_target not in [30,60]: fps_target = 30 if quality==0 else 60
	Engine.max_fps = 0 if "--uncapped" in OS.get_cmdline_user_args() else fps_target
	var custom := float(Game.settings.get("render_scale",0.0))
	maximum_scale = clampf(custom,0.7,1.7) if custom>0 else SCALES[quality]
	minimum_scale = minf(maximum_scale,MINIMUM[quality])
	active_scale = maximum_scale
	var override := int(Game.settings.get("shadow_quality",-1))
	shadow_tier = quality if override<0 else clampi(override,0,2)
	var viewport := get_viewport()
	viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	viewport.scaling_3d_scale = active_scale
	viewport.msaa_3d = [Viewport.MSAA_DISABLED,Viewport.MSAA_2X,Viewport.MSAA_4X][quality]
	viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	viewport.use_taa = false
	viewport.positional_shadow_atlas_size = [512,1024,2048][shadow_tier]
	RenderingServer.viewport_set_measure_render_time(viewport.get_viewport_rid(),bool(Game.settings.get("metrics",false)) or "--uncapped" in OS.get_cmdline_user_args())
	window_ms.clear()
	window_clock = 0
	headroom = 0
	settle = 3
func evaluate_window(p95_ms: float,gpu_ms: float,cpu_ms: float,seconds: float) -> void:
	var budget := 1000.0/fps_target
	var load_ms := gpu_ms if gpu_ms>0 else p95_ms
	if load_ms>budget*1.12:
		headroom=0
		set_scale(active_scale-0.025)
	elif load_ms<budget*0.80 or (gpu_ms<=0 and p95_ms<budget*1.04 and cpu_ms<budget*.75):
		headroom+=seconds
		if headroom>=12:
			headroom=0
			set_scale(active_scale+0.025)
	else: headroom=0
func set_scale(value: float):
	var next := clampf(value,minimum_scale,maximum_scale)
	if is_equal_approx(next,active_scale): return
	active_scale=next
	get_viewport().scaling_3d_scale=active_scale
	adjustments+=1
func _process(delta: float):
	if not Game.playing or Game.paused or Game.capture_in_progress or not Game.settings.get("adaptive_resolution",false):
		window_ms.clear();window_clock=0
		return
	if settle>0: settle-=delta;return
	window_ms.append(delta*1000)
	if window_ms.size()>240: window_ms.pop_front()
	window_clock+=delta
	if window_clock<3: return
	window_ms.sort()
	var p95 := window_ms[mini(window_ms.size()-1,int(window_ms.size()*.95))]
	var gpu := RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid())
	evaluate_window(p95,gpu,Performance.get_monitor(Performance.TIME_PROCESS)*1000,window_clock)
	window_ms.clear();window_clock=0
