extends Node

# ─────────────────────────────────────────────
# WaveManager
# Place this node in your main game scene.
# Runs the wave loop: countdown → end wave → clear enemies →
# short break → next wave (harder) → repeat.
# ─────────────────────────────────────────────

@export var wave_duration: float = 60.0          # Overridden each wave by WaveCurve.wave_duration_seconds (roadmap §4)
@export var break_duration: float = 3.0          # Pause between waves

# We'll find the spawner in _ready()
var _spawner: Node = null
var _shop_manager: Node = null

var _wave_timer: float = 0.0
var _break_timer: float = 0.0
var _in_break: bool = false       # True during the between-wave pause (shop or timer fallback)
var current_wave: int = 1

# Signals — GameUI can listen to these to display wave info
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)


func _ready() -> void:
	add_to_group("wave_manager")
	# Find the spawner by group — add EnemySpawner to "enemy_spawner" group in Inspector
	var spawners = get_tree().get_nodes_in_group("enemy_spawner")
	if spawners.size() > 0:
		_spawner = spawners[0]

	# ShopManager sits after WaveManager in Main.tscn, so its _ready (and add_to_group)
	# has not run yet — resolve next idle frame so the group lookup succeeds.
	call_deferred("_hook_shop_manager")

	# Kick off wave 1 after the whole scene tree is ready so HUD can connect to signals first.
	call_deferred("_start_wave")


func _hook_shop_manager() -> void:
	_shop_manager = get_tree().get_first_node_in_group("shop_manager")
	if _shop_manager and _shop_manager.has_signal("shop_closed"):
		if not _shop_manager.shop_closed.is_connected(_on_shop_closed_resume):
			_shop_manager.shop_closed.connect(_on_shop_closed_resume)


func _process(delta: float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return

	if _in_break:
		# ── Between-wave: shop handles flow when present; otherwise timer break ──
		if _shop_manager and _shop_manager.is_shop_open:
			return
		_break_timer -= delta
		if _break_timer <= 0:
			_start_wave()
	else:
		# ── Active wave countdown ──
		_wave_timer -= delta
		if _wave_timer <= 0:
			_end_wave()


func _start_wave() -> void:
	_in_break = false
	
	var wave_path = "res://resources/enemies/waves/wave_%02d.tres" % current_wave
	wave_duration = WaveCurve.wave_duration_seconds(current_wave)
	if ResourceLoader.exists(wave_path):
		var wave_data = load(wave_path) as WaveData
		if wave_data and _spawner and _spawner.has_method("apply_wave_data"):
			_spawner.apply_wave_data(wave_data, current_wave)
	elif _spawner and _spawner.has_method("apply_wave_data"):
		_spawner.apply_wave_data(null, current_wave)
	_wave_timer = wave_duration

	# Re-activate the spawner
	if _spawner:
		_spawner.set_active(true)

	emit_signal("wave_started", current_wave)
	print("Wave %d started!" % current_wave)


func _end_wave() -> void:
	_in_break = true
	_break_timer = break_duration

	# Stop spawning during break
	if _spawner:
		_spawner.set_active(false)

	# Clear all remaining enemies from the scene
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		enemy.queue_free()

	# Tell GameManager a wave was completed
	GameManager.register_wave_complete()

	emit_signal("wave_completed", current_wave)

	# Difficulty curve (spawn interval, HP/DMG, N_total, N_max) comes from WaveCurve + EnemySpawner.apply_wave_data.
	current_wave += 1

	if _shop_manager == null:
		_hook_shop_manager()

	if _shop_manager and _shop_manager.has_method("open_shop"):
		print("Wave %d complete — shop is open." % [current_wave - 1])
	else:
		print("Wave %d complete! Next wave in %.0f seconds..." % [current_wave - 1, break_duration])

	# Between-wave shop (only entry point into the shop during a run)
	if _shop_manager and _shop_manager.has_method("open_shop"):
		_break_timer = 0.0
		_shop_manager.open_shop()
	else:
		_break_timer = break_duration


func _on_shop_closed_resume() -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return
	if not _in_break:
		return
	_start_wave()


## DevDebug: immediately end the active wave (same path as the wave timer expiring).
func dev_force_end_wave() -> bool:
	if GameManager.state != GameManager.GameState.PLAYING:
		return false
	if _in_break:
		return false
	_end_wave()
	return true


## DevDebug: add or subtract time on the current wave countdown (ignored during shop/break).
func dev_adjust_wave_time_remaining(delta_seconds: float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return
	if _in_break:
		return
	_wave_timer = maxf(_wave_timer + delta_seconds, 1.0)
