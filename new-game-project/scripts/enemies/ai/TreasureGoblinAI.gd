extends CharacterBody2D

# ─────────────────────────────────────────────
# TreasureGoblinAI
# Steals uncollected gold, flees from the player,
# and dashes when in danger. Drops huge loot on death!
# ─────────────────────────────────────────────

@export var base_speed: float = 160.0
@export var boost_speed: float = 280.0
@export var boost_duration: float = 1.0
@export var boost_cooldown: float = 4.0
@export var flee_range: float = 280.0
@export var gold_steal_radius: float = 35.0
@export var low_gold_retreat_threshold: int = 2
@export var low_gold_grace_duration: float = 1.25
@export var return_gold_threshold: int = 5
@export var min_distraction_enemies: int = 4
@export var distraction_enemy_radius: float = 320.0
@export var hide_radius: float = 820.0
@export var hide_arrival_radius: float = 36.0

@export var stolen_gold: int = 25  # Base loot

@onready var health_system: Node = $HealthSystem
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var player: CharacterBody2D = null
var _boost_timer: float = 0.0
var _cooldown_timer: float = 0.0
var _wall_slide_dir: Vector2 = Vector2.ZERO
var _wall_slide_timer: float = 0.0
var _low_gold_timer: float = 0.0
var _hide_target: Vector2 = Vector2.ZERO
var _retreat_boosts_remaining: int = 0

enum GoblinState {
	HUNTING,
	RETREATING,
	HIDING,
}

var _state: GoblinState = GoblinState.HUNTING

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("treasure_goblin")
	health_system.died.connect(_on_died)
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	
func _physics_process(delta: float) -> void:
	if player == null or GameManager.state != GameManager.GameState.PLAYING:
		return
		
	_cooldown_timer = maxf(0.0, _cooldown_timer - delta)
	_boost_timer = maxf(0.0, _boost_timer - delta)

	var available_gold := _available_gold_coins()
	var gold_count := available_gold.size()

	match _state:
		GoblinState.HIDING:
			_process_hiding(gold_count)
			return
		GoblinState.RETREATING:
			_process_retreating(delta)
			return
		GoblinState.HUNTING:
			_process_hunting(delta, available_gold, gold_count)

func _process_hunting(delta: float, available_gold: Array[Node2D], gold_count: int) -> void:
	# Bail out and retreat if gold is running low
	if gold_count <= low_gold_retreat_threshold:
		_low_gold_timer += delta
		if _low_gold_timer >= low_gold_grace_duration:
			_begin_retreat()
			return
	else:
		_low_gold_timer = 0.0

	var dist_to_player = global_position.distance_to(player.global_position)

	# Only burst-dash when the player gets DANGEROUSLY close (inner 60% of flee range).
	# The old code dashed any time the player was within flee_range, which made the
	# goblin look panicked instead of casually thieving.
	var panic_range := flee_range * 0.6
	if dist_to_player < panic_range and _cooldown_timer <= 0.0:
		_trigger_boost()

	# We need a gold target to do the wandering thieving behavior.
	# If there's nothing to steal, just retreat.
	var nearest_gold := _nearest_gold(available_gold)
	if nearest_gold == null:
		_begin_retreat()
		return

	# ─── BLENDED STEERING (this is what kills the stutter) ───
	# Instead of a hard switch between "flee" and "chase gold" (which caused the
	# goblin to flip direction every time it crossed the flee_range boundary),
	# we combine three forces every frame and normalize the result. Smooth = no studder.

	# Force 1: pull toward the nearest coin
	var to_gold := nearest_gold.global_position - global_position
	var dist_to_gold := to_gold.length()
	var gold_dir := to_gold.normalized() if dist_to_gold > 0.01 else Vector2.ZERO

	# Force 2: push away from the player, ramping up smoothly as they close in.
	# Squared falloff means barely any push at the edge of flee_range, strong push up close.
	var to_player := player.global_position - global_position
	var away_from_player := -to_player.normalized() if to_player.length() > 0.01 else Vector2.ZERO
	var threat := 0.0
	if dist_to_player < flee_range:
		var t = 1.0 - clampf(dist_to_player / flee_range, 0.0, 1.0)
		threat = t * t

	# Force 3: a tangent "orbit" component perpendicular to the gold direction.
	# This is what makes the goblin curve and wander around the coin pile instead
	# of marching straight at it like a missile. We pick the orbit side that
	# leads away from the player so the arcs look intentional, not random.
	var orbit_dir := Vector2(-gold_dir.y, gold_dir.x)
	if orbit_dir.dot(away_from_player) < 0:
		orbit_dir = -orbit_dir

	# When the goblin is already near the gold, prioritize wandering/orbit over
	# approach. When it's far away, prioritize approach. Smooth blend = casual look.
	var approach_weight := clampf(dist_to_gold / 120.0, 0.0, 1.0)

	# Add a little time-based wobble so the goblin doesn't look robotic when
	# orbiting. Uses its own position as a phase offset so multiple goblins
	# don't wobble in sync.
	var wobble_phase := Time.get_ticks_msec() / 1000.0 + global_position.x * 0.013
	var wobble := Vector2(sin(wobble_phase * 2.3), cos(wobble_phase * 1.7)) * 0.15

	var move_dir := (
		gold_dir * approach_weight                       # head toward the prize
		+ orbit_dir * (1.0 - approach_weight) * 0.9      # wander around it when close
		+ away_from_player * threat * 1.6                # smoothly back off from player
		+ wobble                                          # organic noise so they don't look robotic
	).normalized()

	# Pull back toward the arena center if we're near the boundary (prevents
	# the goblin from getting cornered against a wall while orbiting).
	var dist_from_center := global_position.length()
	if dist_from_center > 600.0:
		var center_pull := clampf((dist_from_center - 600.0) / 300.0, 0.0, 1.5)
		var to_center := (Vector2.ZERO - global_position).normalized()
		move_dir = (move_dir + to_center * center_pull).normalized()

	move_dir = _apply_wall_slide(move_dir, delta)

	var current_speed = base_speed
	if _boost_timer > 0.0:
		current_speed = boost_speed

	velocity = move_dir * current_speed
	move_and_slide()
	_update_sprite()
	_steal_gold()

func _process_retreating(delta: float) -> void:
	if _hide_target == Vector2.ZERO:
		_hide_target = _choose_hide_target()

	if _retreat_boosts_remaining > 0 and _boost_timer <= 0.0:
		_trigger_boost(true)
		_retreat_boosts_remaining -= 1

	var to_hide := _hide_target - global_position
	if to_hide.length() <= hide_arrival_radius:
		_enter_hiding()
		return

	var move_dir := _apply_wall_slide(to_hide.normalized(), delta)
	var current_speed = boost_speed if _boost_timer > 0.0 else base_speed
	velocity = move_dir * current_speed
	move_and_slide()
	_update_sprite()

func _process_hiding(gold_count: int) -> void:
	velocity = Vector2.ZERO
	if gold_count >= return_gold_threshold and _has_distraction_cover():
		_exit_hiding()

func _begin_retreat() -> void:
	_state = GoblinState.RETREATING
	_low_gold_timer = 0.0
	_hide_target = _choose_hide_target()
	_retreat_boosts_remaining = 2
	_trigger_boost(true)
	_retreat_boosts_remaining -= 1

func _enter_hiding() -> void:
	_state = GoblinState.HIDING
	velocity = Vector2.ZERO
	sprite.visible = false
	collision_shape.disabled = true

func _exit_hiding() -> void:
	_state = GoblinState.HUNTING
	_low_gold_timer = 0.0
	_hide_target = Vector2.ZERO
	sprite.visible = true
	collision_shape.disabled = false

func _choose_hide_target() -> Vector2:
	var away_dir := Vector2.RIGHT
	if player != null:
		away_dir = global_position - player.global_position
		if away_dir.length_squared() < 0.01:
			away_dir = Vector2.RIGHT.rotated(randf() * TAU)
		else:
			away_dir = away_dir.normalized()
	return away_dir * hide_radius

func _trigger_boost(ignore_cooldown: bool = false) -> void:
	if ignore_cooldown or _cooldown_timer <= 0.0:
		_boost_timer = boost_duration
		_cooldown_timer = boost_cooldown

func _available_gold_coins() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for coin in get_tree().get_nodes_in_group("gold_coin"):
		if is_instance_valid(coin) and not coin.get("_collected"):
			result.append(coin)
	return result

func _nearest_gold(coins: Array[Node2D]) -> Node2D:
	var nearest_gold: Node2D = null
	var min_dist: float = INF
	for coin in coins:
		var d = global_position.distance_to(coin.global_position)
		if d < min_dist:
			min_dist = d
			nearest_gold = coin
	return nearest_gold

func _has_distraction_cover() -> bool:
	if player == null:
		return false

	var nearby_enemies := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == self or enemy.is_in_group("treasure_goblin"):
			continue
		if not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_to(player.global_position) <= distraction_enemy_radius:
			nearby_enemies += 1
			if nearby_enemies >= min_distraction_enemies:
				return true
	return false

func _apply_wall_slide(move_dir: Vector2, delta: float) -> Vector2:
	if is_on_wall():
		var wall_normal: Vector2 = get_wall_normal()
		_wall_slide_dir = (move_dir + wall_normal * 0.8).normalized()
		_wall_slide_timer = 0.4

	if _wall_slide_timer <= 0.0:
		return move_dir

	_wall_slide_timer -= delta
	return _wall_slide_dir

func _update_sprite() -> void:
	if velocity.length_squared() > 10.0:
		sprite.play("Move")
		sprite.flip_h = velocity.x < 0
	else:
		sprite.play("Idle")

func _steal_gold() -> void:
	if _state != GoblinState.HUNTING:
		return

	for coin in get_tree().get_nodes_in_group("gold_coin"):
		if not is_instance_valid(coin) or coin.get("_collected"): continue
		if global_position.distance_to(coin.global_position) <= gold_steal_radius:
			coin._collected = true
			stolen_gold += coin.get("gold_value")
			coin.queue_free()
			
			# Little pop animation on steal
			var base_scale: Vector2 = sprite.scale
			var tw = create_tween()
			tw.tween_property(sprite, "scale", base_scale * 1.17, 0.05)
			tw.tween_property(sprite, "scale", base_scale, 0.1)

func _on_died() -> void:
	# Spits out all the stolen gold + base payout
	var drops: int = int(ceil(float(stolen_gold) / 3.0))
	for i in range(drops):
		GoldDropSystem.spawn_drop(global_position, 3) # Drops smaller coins to make a huge explosion of coins
	queue_free()
