extends Node
## Explicit live integration suite: temporary accounts, no real-player data.
var failures := 0
var passed := 0
var users: Array = []
var password := "T!" + Crypto.new().generate_random_bytes(16).hex_encode()

func check(ok: bool, title: String) -> void:
	if ok: passed += 1
	else: failures += 1
	print("PASS " if ok else "FAIL ", title)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run.call_deferred()

func record_user() -> void:
	users.append({"uid": Cloud.uid})
	var path := OS.get_environment("RUN_AWAY_TEST_USERS")
	if not path.is_empty(): Game.write_json(path, {"users": users})

func run() -> void:
	Game.record_results = false
	var prefix := "runaway-qa-" + Crypto.new().generate_random_bytes(8).hex_encode()
	var address := prefix + "@example.com"
	await Cloud.authenticate(address, password, true)
	check(not Cloud.uid.is_empty() and Cloud.status.begins_with("Sincronizado"), "create account and initialize protected player")
	if Cloud.uid.is_empty(): get_tree().quit(1); return
	record_user()
	var first_uid := Cloud.uid
	var checkpoint := {"version": 1, "items": ["lanterna", "fusivel"], "power": true, "doors": {}, "elapsed_ms": 75432}
	Cloud.queue_checkpoint(checkpoint)
	await Cloud.sync()
	check(Cloud.pending.checkpoint.is_empty(), "checkpoint uploaded")
	var event := {"id": Crypto.new().generate_random_bytes(16).hex_encode(), "won": true, "elapsed_ms": 105432, "score": 1100, "items": ["lanterna", "fusivel", "cartao"], "power": true}
	Cloud.queue_run(event)
	await Cloud.sync()
	check(Cloud.stats.get("totalPoints") == 1100 and Cloud.stats.get("runs") == 1 and Cloud.stats.get("bestEscapeMs") == 105432, "atomic score and best escape")
	Cloud.queue_run(event)
	await Cloud.sync()
	check(Cloud.stats.get("totalPoints") == 1100 and Cloud.stats.get("runs") == 1 and Cloud.pending.runs.is_empty(), "retry never doubles points")
	var offline := event.duplicate(true)
	offline.id = Crypto.new().generate_random_bytes(16).hex_encode()
	offline.elapsed_ms = 95432
	Cloud.queue_run(offline)
	Cloud.sign_out()
	await Cloud.authenticate(address, password)
	check(Cloud.stats.get("totalPoints") == 2200 and Cloud.stats.get("runs") == 2 and Cloud.stats.get("bestEscapeMs") == 95432, "persisted outbox survives sign-out and improves best time")
	var slower := event.duplicate(true)
	slower.id = Crypto.new().generate_random_bytes(16).hex_encode()
	Cloud.queue_run(slower)
	await Cloud.sync()
	check(Cloud.stats.get("bestEscapeMs") == 95432, "slower escape preserves previous best")
	Cloud._expires = 0
	await Cloud.sync()
	check(Cloud.status.begins_with("Sincronizado"), "expired identity token refresh")
	Cloud.sign_out()
	await Cloud.authenticate(address, password)
	check(Game.checkpoint == checkpoint and Cloud.stats.get("totalPoints") == 3300, "login restores checkpoint and statistics")
	Cloud.pending.checkpoint = {"version": 1, "items": [], "power": false, "doors": {}, "elapsed_ms": 1}
	await Cloud.sync(true)
	check(not Cloud.conflict.is_empty(), "different offline progress requires a choice")
	Cloud.choose_checkpoint(true)
	check(Game.checkpoint == checkpoint and Cloud.pending.checkpoint.is_empty(), "cloud checkpoint choice")
	Cloud.sign_out()
	await Cloud.authenticate(prefix + "-other@example.com", password, true)
	check(not Cloud.uid.is_empty() and Cloud.uid != first_uid, "independent second account")
	if not Cloud.uid.is_empty():
		record_user()
		var denied := await Cloud._request(HTTPClient.METHOD_GET, Cloud._base() + "/players/" + first_uid, null, true)
		check(denied.code == 403, "another account cannot read player data")
		denied = await Cloud._request(HTTPClient.METHOD_PATCH, Cloud._base() + "/players/" + first_uid, {"fields": {}}, true)
		check(denied.code == 403, "another account cannot overwrite player data")
		var forged := event.duplicate(true)
		forged.id = Crypto.new().generate_random_bytes(16).hex_encode()
		forged.score = 999999
		Cloud.queue_run(forged)
		await Cloud.sync()
		check(Cloud.pending.runs.size() == 1 and Cloud.stats.get("totalPoints") == 0, "rules reject forged score and keep failed outbox")
		Cloud.pending.runs = {}
		Cloud._persist()
		await Cloud._request(HTTPClient.METHOD_POST, Cloud._auth_url("delete"), {"idToken": Cloud._token})
	Cloud.sign_out()
	await Cloud.authenticate(address, password)
	if not Cloud.uid.is_empty(): await Cloud._request(HTTPClient.METHOD_POST, Cloud._auth_url("delete"), {"idToken": Cloud._token})
	Cloud.sign_out()
	var anonymous := await Cloud._request(HTTPClient.METHOD_GET, Cloud._base() + "/players/" + first_uid)
	check(anonymous.code == 403, "anonymous access denied")
	check(Game.score_for(["lanterna", "lanterna", "cartao"], false, false) == 200, "unique item scoring")
	Game.begin()
	await get_tree().create_timer(0.12).timeout
	Game.set_paused(true)
	var elapsed := Game.elapsed_ms
	await get_tree().create_timer(0.12).timeout
	check(Game.elapsed_ms == elapsed and elapsed >= 100, "paused time excluded")
	Game.playing = false
	Game.set_paused(false)
	print("CLOUD RESULT ", passed, " passed; ", failures, " failed")
	get_tree().quit(1 if failures else 0)
