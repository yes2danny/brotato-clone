extends Node2D

# ─────────────────────────────────────────────
# EnemySpawner
# Place this node in your main game scene.
# Spawns enemies in a ring around the player on a timer.
# Picks randomly from a pool of enemy scene types.
# Gets harder each wave by reducing the spawn interval.
#
# HOW TO ADD A NEW ENEMY TYPE:
#   1. Create a new scene in scenes/enemies/ (copy Enemy.tscn as a starting point)
#   2. Assign new sprites and adjust move_speed, damage, max_health in the scene
#   3. In Main.tscn, drag the new scene into the enemy_scenes array on EnemySpawner
#      OR add it to the enemy_scenes array in the Inspector (Node tab won't show it,
#      use the Inspector panel with EnemySpawner selected)
# ─────────────────────────────────────────────

# Pool of enemy types to spawn — add more scenes here in the Inspector!
# Each wave randomly picks from this list, so variety is automatic.
@export var enemy_scenes: Array[PackedScene] = []

@export var spawn_interval: float = 2.0      # Starting seconds between each spawn
@export var spawn_radius: float = 400.0      # How far from the player enemies appear
@export var min_spawn_interval: float = 0.5  # Floor — never spawns faster than this

@export var map_half_size: float = 960.0
@export var map_spawn_margin: float = 48.0

var _timer: float = 0.0      # Countdown to next spawn
var player: Node2D = null    # Reference to the player
var is_active: bool = true   # Can be toggled off between waves


func _ready() -> void:
	# Auto-register so WaveManager can find us without needing Inspector group setup
	add_to_group("enemy_spawner")

	# Find the player by group — PlayerMovement.gd adds itself to "player"
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]


func _process(delta: float) -> void:
	# Only spawn during active gameplay
	if not is_active or player == null:
		return
	if GameManager.state != GameManager.GameState.PLAYING:
		return

	_timer -= delta
	if _timer <= 0:
		_spawn_enemy()
		_timer = spawn_interval  # Reset the countdown


func _spawn_enemy() -> void:
	# No scenes in the pool? Nothing to spawn
	if enemy_scenes.is_empty():
		return

	# Pick a random enemy type from the pool
	var scene_to_spawn = enemy_scenes[randi() % enemy_scenes.size()]
	if not scene_to_spawn:
		return

	# Find a spawn position that isn't inside a wall
	var spawn_pos = _find_valid_spawn_position()
	if spawn_pos == Vector2.ZERO:
		return  # Couldn't find a valid spot this tick, skip

	# Create the enemy and place it
	var enemy = scene_to_spawn.instantiate()
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = spawn_pos


func _find_valid_spawn_position() -> Vector2:
	# We try up to 10 random positions around the player.
	# Each one is checked against the physics world — if it overlaps a wall
	# or static body, we skip it and try the next angle.
	var space = get_world_2d().direct_space_state

	for _attempt in range(32):
		# Random point in a ring around the player
		var angle = randf() * TAU
		var test_pos = player.global_position + Vector2(cos(angle), sin(angle)) * spawn_radius
		if not _is_inside_map_bounds(test_pos):
			continue

		# Build a point query — this asks "is anything solid at this position?"
		var query = PhysicsPointQueryParameters2D.new()
		query.position = test_pos
		query.collide_with_bodies = true
		query.collide_with_areas = false
		# Layer 1 = world/walls (static bodies). We only care about solid obstacles.
		# If your walls are on a different collision layer, change this number.
		query.collision_mask = 1

		var hits = space.intersect_point(query)
		if hits.is_empty():
			# Nothing solid here — safe to spawn!
			return test_pos

	# Tried 10 times and everything was blocked (rare). Skip this spawn tick.
	return Vector2.ZERO


func _is_inside_map_bounds(pos: Vector2) -> bool:
	var min_pos = -map_half_size + map_spawn_margin
	var max_pos = map_half_size - map_spawn_margin
	return pos.x >= min_pos and pos.x <= max_pos and pos.y >= min_pos and pos.y <= max_pos


# Called by WaveManager each wave to ramp up difficulty
func increase_difficulty(reduction: float) -> void:
	spawn_interval -= reduction
	spawn_interval = max(spawn_interval, min_spawn_interval)  # Never go below the floor


# Called by WaveManager to pause/resume spawning between waves
func set_active(active: bool) -> void:
	is_active = active
	if active:
		_timer = spawn_interval  # Fresh timer when re-enabled


## DevDebug: spawn one enemy immediately using the normal spawn rules (ignores is_active).
func dev_spawn_one() -> void:
	if enemy_scenes.is_empty():
		push_warning("EnemySpawner.dev_spawn_one: enemy_scenes is empty")
		return
	if player == null or not is_instance_valid(player):
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
	if player == null:
		push_warning("EnemySpawner.dev_spawn_one: no player in group 'player'")
		return
	_spawn_enemy()
	_timer = spawn_interval
