extends Node2D

# ─────────────────────────────────────────────
# EnemySpawner
# Place this node in your main game scene.
# Spawns enemies in a ring around the player on a timer.
# Reads the active roster from the **PoolState** autoload — that singleton is
# updated each wave by `WaveManager` (`PoolState.apply_wave(wave_data, n)`),
# applying `pool_additions` / `pool_removals` deltas from `wave_NN.tres`.
#
# HOW TO ADD A NEW ENEMY TYPE:
#   1. Create a new scene in scenes/enemies/ (copy Enemy.tscn as a starting point)
#   2. Assign new sprites and adjust move_speed, damage, max_health in the scene
#   3. Add a `WaveSpawnEntry` for the new scene to **one** wave's
#      `pool_additions` (the wave it should first appear). It will persist on
#      every later wave until something later puts it in `pool_removals`.
#   4. (Optional) Tweak its weight on a later wave by re-adding it in that
#      wave's `pool_additions` — same scene path → in-place upsert.
# ─────────────────────────────────────────────

## Last-resort flat pool when no wave is active (e.g. dev_spawn_one in a
## scene loaded without WaveManager). PoolState is the real source of truth
## once a wave starts.
@export var enemy_scenes: Array[PackedScene] = []

@export var spawn_interval: float = 2.0      # Starting seconds between each spawn
@export var spawn_radius: float = 400.0      # How far from the player enemies appear
@export var min_spawn_interval: float = 0.5  # Floor — never spawns faster than this

@export var map_half_size: float = 960.0
@export var map_spawn_margin: float = 48.0
@export var require_clear_path_from_player: bool = true

## Option B (roadmap): 60s waves; `N_total` is not a hard spawn cap (see `WaveCurve` comment).
## These multiply the doc curve outputs — use 1.0 to match the HTML exactly.
@export_range(0.70, 1.0, 0.01) var spawn_interval_scale: float = 0.90
@export_range(1.0, 1.5, 0.01) var extra_hp_mult: float = 1.10
@export_range(1.0, 1.5, 0.01) var extra_dmg_mult: float = 1.08

const GOBLIN_SCENE = preload("res://scenes/enemies/Enemy_TreasureGoblin.tscn")
const SPAWN_SCENE_META := &"spawn_scene_path"

var _timer: float = 0.0      # Countdown to next spawn
var _goblin_check_timer: float = 3.0 # Periodically checks for treasure goblin spawn conditions
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

	_goblin_check_timer -= delta
	if _goblin_check_timer <= 0:
		_goblin_check_timer = 5.0
		# Spawn a treasure goblin if there's a lot of uncollected gold and no goblin is currently active
		if get_tree().get_nodes_in_group("gold_coin").size() >= 5 and get_tree().get_nodes_in_group("treasure_goblin").size() < 2:
			var spawn_pos = _find_valid_spawn_position()
			if spawn_pos != Vector2.ZERO:
				var goblin = GOBLIN_SCENE.instantiate()
				get_tree().current_scene.add_child(goblin)
				goblin.global_position = spawn_pos


## Kept for any tooling that still pokes at it; the actual roster lives on
## the PoolState autoload now (see `_active_pool()`).
var current_wave_data: WaveData = null
var _active_wave_number: int = 1
var _n_max: int = 999999
var _curve_hp_mult: float = 1.0
var _curve_dmg_mult: float = 1.0


func apply_wave_data(data: WaveData, wave_number: int) -> void:
	current_wave_data = data
	_active_wave_number = wave_number

	_n_max = WaveCurve.n_max_concurrent(wave_number)
	_curve_hp_mult = WaveCurve.hp_mult(wave_number) * extra_hp_mult
	_curve_dmg_mult = WaveCurve.dmg_mult(wave_number) * extra_dmg_mult

	var t_spawn: float = WaveCurve.spawn_interval_seconds(wave_number) * spawn_interval_scale
	spawn_interval = maxf(WaveCurve.SPAWN_INTERVAL_FLOOR, t_spawn)
	min_spawn_interval = WaveCurve.SPAWN_INTERVAL_FLOOR


func clear_wave_data() -> void:
	current_wave_data = null


func _active_pool() -> Array[WaveSpawnEntry]:
	# WaveManager pushes wave deltas into PoolState before the wave starts,
	# so the singleton always holds the authoritative current roster.
	return PoolState.get_pool()


func _live_enemy_count() -> int:
	return get_tree().get_nodes_in_group("enemies").size()


func _alive_count_for_scene_path(scene_path: String) -> int:
	if scene_path.is_empty():
		return 0
	var n: int = 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		if e.get_meta(SPAWN_SCENE_META, "") == scene_path:
			n += 1
			continue
		# Fallback for anything spawned before this meta existed.
		if str(e.scene_file_path) == scene_path:
			n += 1
	return n


func _spawn_enemy() -> void:
	if _live_enemy_count() >= _n_max:
		return

	var scene_to_spawn: PackedScene = null

	var pool: Array[WaveSpawnEntry] = _active_pool()
	if not pool.is_empty():
		var valid_entries: Array[WaveSpawnEntry] = []
		var total_weight: float = 0.0

		for entry in pool:
			if entry == null or entry.enemy_scene == null:
				continue
			var path: String = entry.enemy_scene.resource_path
			var cap_ok: bool = entry.max_alive <= 0 or _alive_count_for_scene_path(path) < entry.max_alive
			if cap_ok:
				valid_entries.append(entry)
				total_weight += entry.weight

		if valid_entries.size() > 0 and total_weight > 0.0:
			var roll: float = randf() * total_weight
			for entry in valid_entries:
				roll -= entry.weight
				if roll <= 0:
					scene_to_spawn = entry.enemy_scene
					break

	# Fallback if no valid scene found from pool
	if scene_to_spawn == null:
		if enemy_scenes.is_empty():
			return
		scene_to_spawn = enemy_scenes[randi() % enemy_scenes.size()]
		if scene_to_spawn == null:
			return

	# Find a spawn position that isn't inside a wall
	var spawn_pos = _find_valid_spawn_position()
	if spawn_pos == Vector2.ZERO:
		return  # Couldn't find a valid spot this tick, skip

	# Create the enemy and place it
	var enemy = scene_to_spawn.instantiate()
	var scene_path: String = scene_to_spawn.resource_path
	if not scene_path.is_empty():
		enemy.set_meta(SPAWN_SCENE_META, scene_path)
	
	if enemy.has_method("apply_wave_scaling"):
		enemy.apply_wave_scaling(_curve_hp_mult, _curve_dmg_mult)
		
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
			if require_clear_path_from_player and not _has_clear_path_from_player(space, test_pos):
				continue
			return test_pos

	# Tried 10 times and everything was blocked (rare). Skip this spawn tick.
	return Vector2.ZERO


func _is_inside_map_bounds(pos: Vector2) -> bool:
	var min_pos = -map_half_size + map_spawn_margin
	var max_pos = map_half_size - map_spawn_margin
	return pos.x >= min_pos and pos.x <= max_pos and pos.y >= min_pos and pos.y <= max_pos


func _has_clear_path_from_player(space: PhysicsDirectSpaceState2D, target_pos: Vector2) -> bool:
	var ray = PhysicsRayQueryParameters2D.create(player.global_position, target_pos, 1)
	ray.collide_with_bodies = true
	ray.collide_with_areas = false
	return space.intersect_ray(ray).is_empty()


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
	if PoolState.get_pool_size() == 0 and enemy_scenes.is_empty():
		push_warning("EnemySpawner.dev_spawn_one: PoolState empty and no enemy_scenes fallback")
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
