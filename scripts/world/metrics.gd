extends Node
var snapshot: Dictionary = {}
var age := 0.0
var frames := 0
var worst_frame_ms := 0.0
var previous_rays := 0

func _process(delta: float) -> void:
	if not Game.playing or not Game.settings.get("metrics", false): return
	age += delta
	frames += 1
	worst_frame_ms = maxf(worst_frame_ms, delta * 1000)
	if age < 1.0: return
	var ai: int = Game.enemy.ai_usec if is_instance_valid(Game.enemy) else 0
	snapshot = {"fps_sample": frames / age, "worst_frame_ms": worst_frame_ms, "process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000, "ai_last_usec": ai, "audio_nodes": Sound.get_child_count(), "audio_output_latency_ms": Performance.get_monitor(Performance.AUDIO_OUTPUT_LATENCY) * 1000, "audio_spawn_usec": Sound.last_spawn_usec, "mic_rms_usec": Mic.last_rms_usec, "noise_rays_per_s": (NoiseBus.ray_count - previous_rays) / age, "physical_props": get_tree().get_nodes_in_group("throwables").size(), "nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT), "memory_static_bytes": Performance.get_monitor(Performance.MEMORY_STATIC), "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
	previous_rays = NoiseBus.ray_count
	age = 0
	frames = 0
	worst_frame_ms = 0
	Game.write_json("user://expansion_metrics.json", snapshot)
