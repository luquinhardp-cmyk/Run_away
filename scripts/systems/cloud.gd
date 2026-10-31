extends Node
## Firebase client REST. Credentials live only in memory; the outbox contains game data.
signal changed
var uid := ""
var email := ""
var status := "Visitante · progresso salvo neste aparelho"
var busy := false
var syncing := false
var stats: Dictionary = {}
var pending: Dictionary = {"runs": {}, "checkpoint": {}}
var conflict: Dictionary = {}
var _token := ""
var _refresh := ""
var _expires := 0
var _generation := 0
var _retry := 0.0
var _config: Dictionary = {}
var _guest: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_config = JSON.parse_string(FileAccess.get_file_as_string("res://resources/firebase_config.json"))

func _process(delta: float) -> void:
	_retry -= delta
	if not uid.is_empty() and not busy and not syncing and conflict.is_empty() and _retry <= 0:
		_retry = 30.0
		if not pending.runs.is_empty() or not pending.checkpoint.is_empty(): sync()

func _request(method: HTTPClient.Method, url: String, data: Variant = null, auth: bool = false, form: bool = false) -> Dictionary:
	var request := HTTPRequest.new()
	request.timeout = 20
	# Browsers already decompress fetch/XHR responses while retaining encoding headers.
	if OS.has_feature("web"): request.accept_gzip = false
	add_child(request)
	var headers := PackedStringArray(["Content-Type: application/x-www-form-urlencoded" if form else "Content-Type: application/json"])
	if auth: headers.append("Authorization: Bearer " + _token)
	var payload := "" if data == null else JSON.stringify(data)
	if form:
		var pairs := PackedStringArray()
		for key in data: pairs.append(str(key).uri_encode() + "=" + str(data[key]).uri_encode())
		payload = "&".join(pairs)
	var err := request.request(url, headers, method, payload)
	if err != OK:
		request.queue_free()
		return {"ok": false, "code": 0, "body": {}}
	var reply: Array = await request.request_completed
	request.queue_free()
	var body = JSON.parse_string(reply[3].get_string_from_utf8())
	return {"ok": reply[0] == HTTPRequest.RESULT_SUCCESS and reply[1] >= 200 and reply[1] < 300, "code": reply[1], "body": body if body is Dictionary else {}}

func _auth_url(action: String) -> String:
	return "https://identitytoolkit.googleapis.com/v1/accounts:" + action + "?key=" + _config.apiKey

func _base() -> String:
	return "https://firestore.googleapis.com/v1/projects/" + _config.projectId + "/databases/(default)/documents"

func _name() -> String:
	return "projects/" + _config.projectId + "/databases/(default)/documents/players/" + uid

func authenticate(address: String, password: String, create: bool = false) -> void:
	if busy or syncing or Game.playing: return
	if address.strip_edges().is_empty() or password.length() < 6:
		status = "Informe e-mail e senha com pelo menos 6 caracteres."
		changed.emit()
		return
	busy = true
	status = "Conectando…"
	changed.emit()
	var result := await _request(HTTPClient.METHOD_POST, _auth_url("signUp" if create else "signInWithPassword"), {"email": address.strip_edges(), "password": password, "returnSecureToken": true})
	if not result.ok or not result.body.has("idToken"):
		status = "Não foi possível entrar. Confira a conta, a senha e a conexão."
		if str(result.body.get("error", {}).get("message", "")).contains("CONFIGURATION_NOT_FOUND") or str(result.body.get("error", {}).get("message", "")).contains("OPERATION_NOT_ALLOWED"):
			status = "Login ainda não ativado no projeto Firebase. Jogue como visitante por enquanto."
		busy = false
		changed.emit()
		return
	_guest = Game.checkpoint.duplicate(true)
	uid = result.body.localId
	email = result.body.email
	_token = result.body.idToken
	_refresh = result.body.refreshToken
	_expires = Time.get_ticks_msec() + 3300000
	_generation += 1
	Game.select_profile(uid)
	pending = {"runs": {}, "checkpoint": {}}
	var cached = JSON.parse_string(FileAccess.get_file_as_string(_cache_path())) if FileAccess.file_exists(_cache_path()) else null
	if cached is Dictionary:
		pending = cached.get("pending", pending)
		stats = cached.get("stats", {})
	else: stats = {}
	busy = false
	await sync(true)
	changed.emit()

func reset_password(address: String) -> void:
	if busy or syncing or address.strip_edges().is_empty(): return
	busy = true
	changed.emit()
	await _request(HTTPClient.METHOD_POST, _auth_url("sendOobCode"), {"requestType": "PASSWORD_RESET", "email": address.strip_edges()})
	status = "Se houver uma conta com esse e-mail, consulte a mensagem de recuperação."
	busy = false
	changed.emit()

func sign_out() -> void:
	if busy or syncing or Game.playing: return
	_generation += 1
	uid = ""
	email = ""
	_token = ""
	_refresh = ""
	stats = {}
	pending = {"runs": {}, "checkpoint": {}}
	conflict = {}
	Game.select_profile("")
	status = "Visitante · progresso salvo neste aparelho"
	changed.emit()

func _cache_path() -> String:
	return "user://accounts/" + uid + "/outbox.json"

func _persist() -> void:
	if uid.is_empty(): return
	Game.write_json(_cache_path(), {"pending": pending, "stats": stats})

func queue_checkpoint(value: Dictionary) -> void:
	if uid.is_empty(): return
	pending.checkpoint = value.duplicate(true)
	_persist()
	_retry = 2.0
	changed.emit()

func queue_run(value: Dictionary) -> void:
	if uid.is_empty(): return
	pending.runs[value.id] = value.duplicate(true)
	_persist()
	_retry = 0
	changed.emit()

func import_guest() -> void:
	if uid.is_empty() or _guest.is_empty() or syncing: return
	Game.checkpoint = _guest.duplicate(true)
	Game.write_json(Game.checkpoint_path(), Game.checkpoint)
	queue_checkpoint(Game.checkpoint)
	status = "Progresso de visitante importado; aguardando sincronização."
	changed.emit()

func choose_checkpoint(use_cloud: bool) -> void:
	if conflict.is_empty() or syncing: return
	if use_cloud:
		Game.checkpoint = conflict.duplicate(true)
		pending.checkpoint = {}
		Game.write_json(Game.checkpoint_path(), Game.checkpoint)
	conflict = {}
	_persist()
	_retry = 0
	status = "Progresso escolhido."
	changed.emit()

func _fresh_token() -> bool:
	if Time.get_ticks_msec() < _expires: return true
	var response := await _request(HTTPClient.METHOD_POST, "https://securetoken.googleapis.com/v1/token?key=" + _config.apiKey, {"grant_type": "refresh_token", "refresh_token": _refresh}, false, true)
	if not response.ok: return false
	_token = response.body.id_token
	_refresh = response.body.refresh_token
	_expires = Time.get_ticks_msec() + 3300000
	return true

func sync(initial: bool = false) -> void:
	if uid.is_empty() or busy or syncing or not conflict.is_empty(): return
	syncing = true
	status = "Sincronizando…"
	changed.emit()
	var ok := await _fresh_token()
	if ok:
		var remote := await _request(HTTPClient.METHOD_GET, _base() + "/players/" + uid, null, true)
		if remote.code == 404:
			var fields := {"schemaVersion": 1, "stats": {"totalPoints": 0, "runs": 0, "escapes": 0, "bestEscapeMs": 604800001}}
			var created := await _commit([{"update": {"name": _name(), "fields": encode_fields(fields)}, "currentDocument": {"exists": false}}])
			ok = created.ok or created.code == 409
		elif remote.ok:
			var document: Dictionary = decode_fields(remote.body.get("fields", {}))
			stats = document.get("stats", {})
			var checkpoint: Dictionary = document.get("checkpoint", {})
			if initial and not checkpoint.is_empty():
				if not pending.checkpoint.is_empty() and pending.checkpoint != checkpoint:
					conflict = checkpoint
				elif pending.checkpoint.is_empty():
					Game.checkpoint = checkpoint
					Game.write_json(Game.checkpoint_path(), checkpoint)
		else: ok = false
		if ok and conflict.is_empty():
			for id in pending.runs.keys():
				var run: Dictionary = pending.runs[id]
				var transforms: Array = [{"fieldPath": "stats.totalPoints", "increment": {"integerValue": str(int(run.score))}}, {"fieldPath": "stats.runs", "increment": {"integerValue": "1"}}, {"fieldPath": "stats.escapes", "increment": {"integerValue": "1" if run.won else "0"}}]
				if run.won:
					transforms.append({"fieldPath": "stats.bestEscapeMs", "minimum": {"integerValue": str(int(run.elapsed_ms))}})
				var event := await _commit([{"update": {"name": _name() + "/runs/" + id, "fields": encode_fields(run)}, "currentDocument": {"exists": false}}, {"update": {"name": _name(), "fields": {"lastRunId": {"stringValue": id}}}, "updateMask": {"fieldPaths": ["lastRunId"]}, "updateTransforms": transforms}])
				var duplicate := false
				if not event.ok:
					var existing := await _request(HTTPClient.METHOD_GET, _base() + "/players/" + uid + "/runs/" + id, null, true)
					duplicate = existing.ok and decode_fields(existing.body.get("fields", {})) == run
				if event.ok or duplicate:
					pending.runs.erase(id)
					# Refetch authoritative totals even after a duplicate retry.
					var fresh := await _request(HTTPClient.METHOD_GET, _base() + "/players/" + uid, null, true)
					if fresh.ok: stats = decode_fields(fresh.body.fields).get("stats", {})
					_persist()
				else:
					ok = false
					break
			if ok and not pending.checkpoint.is_empty():
				var snapshot: Dictionary = pending.checkpoint.duplicate(true)
				var saved := await _commit([{"update": {"name": _name(), "fields": {"checkpoint": encode(snapshot)}}, "updateMask": {"fieldPaths": ["checkpoint"]}}])
				if saved.ok and pending.checkpoint == snapshot: pending.checkpoint = {}
				ok = saved.ok
	_persist()
	syncing = false
	_retry = 30.0
	status = "Escolha qual checkpoint manter." if not conflict.is_empty() else ("Sincronizado · " + email if ok else "Sem sincronização. Dados guardados neste aparelho; tentaremos novamente.")
	changed.emit()

func _commit(writes: Array) -> Dictionary:
	return await _request(HTTPClient.METHOD_POST, _base() + ":commit", {"writes": writes}, true)

static func encode(value: Variant) -> Dictionary:
	match typeof(value):
		TYPE_BOOL: return {"booleanValue": value}
		TYPE_INT: return {"integerValue": str(value)}
		TYPE_FLOAT: return {"integerValue": str(int(value))} if value == floor(value) else {"doubleValue": value}
		TYPE_STRING: return {"stringValue": value}
		TYPE_DICTIONARY: return {"mapValue": {"fields": encode_fields(value)}}
		TYPE_ARRAY:
			var values: Array = []
			for entry in value: values.append(encode(entry))
			return {"arrayValue": {"values": values}}
	return {"nullValue": null}

static func encode_fields(value: Dictionary) -> Dictionary:
	var fields := {}
	for key in value: fields[key] = encode(value[key])
	return fields

static func decode_fields(fields: Dictionary) -> Dictionary:
	var result := {}
	for key in fields:
		var value: Dictionary = fields[key]
		if value.has("mapValue"): result[key] = decode_fields(value.mapValue.get("fields", {}))
		elif value.has("arrayValue"):
			var array: Array = []
			for entry in value.arrayValue.get("values", []): array.append(decode_fields({"v": entry}).v)
			result[key] = array
		elif value.has("integerValue"): result[key] = int(value.integerValue)
		elif value.has("doubleValue"): result[key] = float(value.doubleValue)
		elif value.has("booleanValue"): result[key] = value.booleanValue
		elif value.has("stringValue"): result[key] = value.stringValue
		else: result[key] = null
	return result
