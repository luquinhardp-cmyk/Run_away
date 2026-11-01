extends Node
var samples := 0
var counted_load_time := 0
func _process(_delta: float) -> void:
	if Game.loading:
		samples+=1
		counted_load_time=maxi(counted_load_time,Game.elapsed_ms)
func _ready() -> void: run.call_deferred()
func run() -> void:
	Game.testing=true
	Game.record_results=false
	var main=preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	main.force_staged_loading=true
	await main.start(false,false)
	# Let the facility's build_finished emission unwind before freeing the scene.
	await get_tree().process_frame
	var checks=[samples>=10,not Game.loading,main.level.nav_ready,is_instance_valid(Game.player),is_instance_valid(Game.enemy),main.screen=="playing",counted_load_time==0]
	var failed := 0
	for i in checks.size():
		print("PASS " if checks[i] else "FAIL ","staged startup assertion ",i)
		if not checks[i]:failed+=1
	main.free()
	Sound.stop_all()
	for i in 8:await get_tree().process_frame
	print("STAGED RESULT ",checks.size()-failed," passed; ",failed," failed")
	get_tree().quit(0 if failed==0 else 1)
