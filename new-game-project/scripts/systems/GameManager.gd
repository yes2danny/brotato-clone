extends Node

# ─────────────────────────────────────────────
# GameManager — Autoload Singleton
# Tracks game state and global stats.
# Every other script can call GameManager.whatever() from anywhere.
# ─────────────────────────────────────────────

# The possible states the game can be in at any moment
enum GameState {
	PLAYING,   # Normal gameplay
	PAUSED,    # Pause menu open
	GAME_OVER, # Player died
	VICTORY    # Player won (future use)
}

# Current state starts as PLAYING
var state: GameState = GameState.PLAYING

# Stats tracked throughout a run
var enemies_killed: int = 0
var waves_completed: int = 0
var time_survived: float = 0.0  # in seconds

# Placeholder meta payout (future: persistent MetaProgress autoload)
var last_run_meta_awarded: int = 0

# Signal fired when the game ends — UI listens for this
signal game_over_triggered(kills: int, waves: int, time: float)
signal victory_triggered(kills: int, waves: int, time: float)
## Emitted from win_run() after cleanup; hook meta shop / cloud save here later.
signal victory_rewards_applied(meta_amount: int)


func _process(delta: float) -> void:
	# Only count time while actively playing
	if state == GameState.PLAYING:
		time_survived += delta


# Called by HealthSystem when the player dies
func trigger_game_over() -> void:
	if state == GameState.GAME_OVER:
		return  # Don't fire twice
	state = GameState.GAME_OVER
	emit_signal("game_over_triggered", enemies_killed, waves_completed, time_survived)


# Called if you ever add a win condition (boss death, wave 20 clear, debug).
# Prefer calling win_run() from gameplay — it runs cleanup + placeholder rewards first.
func trigger_victory() -> void:
	if state == GameState.VICTORY or state == GameState.GAME_OVER:
		return
	state = GameState.VICTORY
	emit_signal("victory_triggered", enemies_killed, waves_completed, time_survived)


## Canonical "run cleared" entry (Wave Roadmap v2). Safe to call from boss script.
## Clears remaining enemies, stops the spawner, rolls placeholder meta, then shows victory UI.
func win_run() -> void:
	if state != GameState.PLAYING:
		return
	last_run_meta_awarded = 0
	_run_win_cleanup()
	_award_victory_rewards_placeholder()
	trigger_victory()


func _run_win_cleanup() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			enemy.queue_free()
	var spawners := get_tree().get_nodes_in_group("enemy_spawner")
	for spawner in spawners:
		if spawner and spawner.has_method("set_active"):
			spawner.set_active(false)


func _award_victory_rewards_placeholder() -> void:
	# Tune later: tie to danger, wave count, boss bonuses, etc.
	var base: int = 50 + waves_completed * 5 + enemies_killed / 2
	last_run_meta_awarded = maxi(base, 1)
	emit_signal("victory_rewards_applied", last_run_meta_awarded)
	print("[GameManager] victory_rewards_applied (placeholder meta): ", last_run_meta_awarded)


# Called by EnemyAI when an enemy dies
func register_kill() -> void:
	enemies_killed += 1


# Called by WaveManager at the end of each wave
func register_wave_complete() -> void:
	waves_completed += 1


# Reload the current scene to restart
func restart_game() -> void:
	enemies_killed = 0
	waves_completed = 0
	time_survived = 0.0
	last_run_meta_awarded = 0
	state = GameState.PLAYING
	XPSystem.reset_run()
	get_tree().reload_current_scene()


# Go back to the main menu scene (create this scene later)
func load_main_menu() -> void:
	state = GameState.PLAYING
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


# Quit the application entirely
func quit_game() -> void:
	get_tree().quit()
