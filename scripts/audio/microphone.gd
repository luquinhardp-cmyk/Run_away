extends Node
signal status_changed
var consent := false
var active := false
var available := true
var permission_required := true
var status := "MIC DESLIGADO"
var level := 0
var volume_db := -80.0
var floor_db := -60.0
var calibrated := false
var calibrating := 0.0
var calibration_samples: Array[float] = []
var capture: AudioEffectCapture
var stream: AudioStreamPlayer
var cooldown := 0.0
var sustained := 0.0
var silent_time := 0.0
var bus := -1
var focused := true
var stable_time := 0.0
var previous_db := -80.0
var gate_open := false
var last_rms_usec := 0
var output_guard := 0.0
var sample_clock := 0.0
var web_bridge
var web_state := "off"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	bus = AudioServer.bus_count
	AudioServer.add_bus()
	AudioServer.set_bus_name(bus, "MicCapture")
	capture = AudioEffectCapture.new()
	capture.buffer_length = 0.2
	AudioServer.add_bus_effect(bus, capture)
	# Capture precedes the mute: samples are processed, never monitored.
	AudioServer.set_bus_mute(bus, true)
	stream = AudioStreamPlayer.new()
	stream.bus = "MicCapture"
	stream.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	stream.stream = AudioStreamMicrophone.new()
	add_child(stream)
	if OS.has_feature("android"):
		get_tree().connect("on_request_permissions_result", _permission_result)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		focused = false
		suspend()
		if Game.playing: Game.set_paused.call_deferred(true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		focused = true

func request_enable() -> void:
	consent = true
	if OS.has_feature("web"):
		web_bridge = JavaScriptBridge.get_interface("EcosWeb")
		if web_bridge == null:
			consent=false
			status="MIC INDISPONÍVEL · carregador Web ausente"
			status_changed.emit()
			return
	if OS.has_feature("android"):
		if "android.permission.RECORD_AUDIO" not in OS.get_granted_permissions():
			status = "AGUARDANDO PERMISSÃO"
			OS.request_permission("RECORD_AUDIO")
			status_changed.emit()
			return
	resume_capture()

func _permission_result(permission: String, granted: bool) -> void:
	if permission.ends_with("RECORD_AUDIO"):
		if not consent: return
		permission_required=not granted
		if granted and consent: resume_capture()
		else:
			consent = false
			status = "SEM PERMISSÃO · modo sem microfone"
			status_changed.emit()

func resume_capture() -> void:
	if not consent or not Game.playing or Game.paused or not focused: return
	if OS.has_feature("web"):
		web_bridge = JavaScriptBridge.get_interface("EcosWeb")
		if web_bridge == null: return
		web_bridge.startMic()
		web_state="pending"
		status="AGUARDANDO PERMISSÃO"
		status_changed.emit()
		return
	if OS.has_feature("android") and "android.permission.RECORD_AUDIO" not in OS.get_granted_permissions(): return
	capture.clear_buffer()
	stream.play()
	active = true
	permission_required=false
	silent_time = 0.0
	status = "MIC ATIVO"
	calibrate()
	status_changed.emit()

func disable() -> void:
	consent = false
	suspend()

func suspend() -> void:
	if OS.has_feature("web"):
		var bridge = JavaScriptBridge.get_interface("EcosWeb")
		if bridge != null: bridge.stopMic()
		web_state="off"
	sample_clock=0
	gate_open = false
	stable_time = 0
	if is_instance_valid(stream): stream.stop()
	if capture: capture.clear_buffer()
	active = false
	level = 0
	sustained = 0.0
	volume_db = -80.0
	calibration_samples.clear()
	status = "MIC SUSPENSO" if consent else "MIC DESLIGADO"
	status_changed.emit()

func calibrate() -> void:
	if not active: return
	calibrated = false
	calibrating = 3.0
	calibration_samples.clear()
	status = "CALIBRANDO · fique em silêncio (3 s)"

static func rms_db(frames: PackedVector2Array) -> float:
	if frames.is_empty(): return -80.0
	var energy := 0.0
	for sample in frames: energy += (sample.x * sample.x + sample.y * sample.y) * 0.5
	return maxf(-80.0, linear_to_db(sqrt(energy / frames.size())))

func classify(db: float) -> int:
	var relative := db - floor_db + linear_to_db(float(Game.settings.mic_sensitivity))
	if relative < 8.0: return 0
	if relative < 16.0: return 1
	if relative < 26.0: return 2
	return 3

func update_gate(db: float, delta: float) -> int:
	stable_time = stable_time + delta if absf(db - previous_db) < 1.2 else 0.0
	previous_db = db
	# Slowly absorb steady fan noise; changing/speech-like peaks remain salient.
	if stable_time > 3.0 or db < floor_db + 5:
		floor_db = clampf(lerpf(floor_db, db, minf(1, delta * 0.12)), -72, -16)
	var relative := db - floor_db + linear_to_db(float(Game.settings.mic_sensitivity))
	if gate_open and relative < 6: gate_open = false
	elif not gate_open and relative >= 9: gate_open = true
	if not gate_open: return 0
	var result := maxi(1, classify(db))
	if level >= 2 and relative > 14: result = maxi(2, result)
	if level >= 3 and relative > 24: result = 3
	return result

func _process(delta: float) -> void:
	if OS.has_feature("web"):
		var bridge = JavaScriptBridge.get_interface("EcosWeb")
		available=bridge!=null and bool(bridge.micSupported)
	if OS.has_feature("web") and consent:
		_poll_web(delta)
		return
	if not active: return
	sample_clock+=delta
	output_guard = maxf(0, output_guard - delta)
	cooldown = maxf(0, cooldown - delta)
	var count := capture.get_frames_available()
	if count < 256:
		silent_time += delta
		if silent_time > 6.0:
			disable()
			status = "SEM SINAL · modo sem microfone"
		return
	# Receiving samples proves the device is alive, even in absolute silence.
	silent_time = 0.0
	# Include frames spent waiting for 256 samples, preserving gate timing at high FPS.
	delta=sample_clock
	sample_clock=0
	_process_samples(capture.get_buffer(count), delta)

func _process_samples(frames: PackedVector2Array, delta: float) -> void:
	var started := Time.get_ticks_usec()
	var db := rms_db(frames)
	last_rms_usec = Time.get_ticks_usec() - started
	_process_db(db,delta)

func _poll_web(delta: float) -> void:
	if web_bridge == null or Game.paused or not focused: return
	var state := str(web_bridge.micState)
	if state != web_state:
		web_state=state
		if state=="active":
			active=true
			permission_required=false
			calibrate()
		elif state in ["denied","unavailable","ended"]:
			permission_required=state=="denied"
			disable()
			status={"denied":"PERMISSÃO NEGADA · toque para tentar","unavailable":"MIC INDISPONÍVEL · confira o dispositivo","ended":"MIC INTERROMPIDO · toque para tentar"}[state]
		elif state=="off":
			active=false
			level=0
			sustained=0
			status="MIC SUSPENSO"
		status_changed.emit()
	if state!="active" or not active: return
	sample_clock+=delta
	if sample_clock<.05: return
	var elapsed := sample_clock
	sample_clock=0
	cooldown=maxf(0,cooldown-elapsed)
	output_guard=maxf(0,output_guard-elapsed)
	_process_db(float(web_bridge.micDb),elapsed)

func _process_db(db: float, delta: float) -> void:
	volume_db = lerpf(volume_db, db, 1.0 - exp(-delta * 14.0))
	if calibrating > 0:
		calibration_samples.append(db)
		calibrating -= delta
		if calibrating <= 0:
			calibration_samples.sort()
			floor_db = clampf(calibration_samples[int(calibration_samples.size() * 0.8)], -72.0, -16.0)
			calibrated = true
			status = "MIC ATIVO · piso %.0f dB" % floor_db
			calibration_samples.clear()
		return
	level = update_gate(volume_db, delta)
	sustained = sustained + delta if level > 0 else maxf(0, sustained - delta * 2)
	if level > 0 and sustained >= 0.12 and cooldown <= 0 and (output_guard <= 0 or level == 3) and is_instance_valid(Game.player):
		NoiseBus.emit_noise(Game.player, [0.0, 0.23, 0.62, 1.0][level], "microfone", [0.0, 7.0, 17.0, 30.0][level], 0.5)
		cooldown = 0.55
