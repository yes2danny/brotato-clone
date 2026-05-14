extends CharacterBody2D

# EnemyAI
#
# Handles the enemy's whole moment-to-moment behavior:
# - Wandering when the player is outside detection range.
# - Spotting the player from a little farther away.
# - Doing a short "alert burst" when the player is first spotted.
# - Chasing at normal speed after that burst ends.
# - Sliding off walls and spreading away from nearby enemies.
# - Dealing contact damage and spawning XP on death.

@export var move_speed: float = 80.0
@export var damage: int = 10
@export var contact_cooldown: float = 1.0

## Extra gold dropped on death (added after the HP/damage formula).
@export var gold_drop_bonus: int = 0
## Multiplier on the automatic gold from toughness (max health + damage).
@export var gold_drop_multiplier: float = 1.0

## If set, this scene is used instead of XPDropSettings.pickup_scene.
## Leave empty to use only res://resources/items/xp_drops/xp_drop_settings.tres.
@export var xp_gem_scene: PackedScene

# Detection and chase tuning.
@export var chase_range: float = 520.0
@export var alert_burst_duration: float = 1.0
@export var alert_burst_speed_multiplier: float = 1.45

# Crowd steering tuning.
@export var separation_strength: float = 60.0
@export var separation_radius: float = 50.0

@onready var health_system: Node = $HealthSystem
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

enum State { WANDER, CHASE }

var state: State = State.WANDER
var player: CharacterBody2D = null

var _contact_timer: float = 0.0
var _alert_burst_timer: float = 0.0
var _wander_target: Vector2 = Vector2.ZERO
var _wander_timer: float = 0.0
var _wall_slide_dir: Vector2 = Vector2.ZERO
var _wall_slide_timer: float = 0.0


func _ready() -> void:
	add_to_group("enemies")
	health_system.died.connect(_on_died)

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	# The first wander point is picked after spawn position has been assigned.
	_wander_timer = 0.0


func _physics_process(delta: float) -> void:
	if player == null or GameManager.state != GameManager.GameState.PLAYING:
		return

	_update_state(delta)

	var move_dir: Vector2 = _get_state_move_direction(delta)
	move_dir = _apply_wall_slide(move_dir, delta)

	var current_speed: float = move_speed
	if _alert_burst_timer > 0.0:
		current_speed *= alert_burst_speed_multiplier

	velocity = (move_dir * current_speed) + (_get_separation_force() * separation_strength)
	_update_sprite()
	move_and_slide()
	_process_contact_damage(delta)


func _update_state(delta: float) -> void:
	var was_chasing: bool = state == State.CHASE
	var can_see_player: bool = global_position.distance_to(player.global_position) <= chase_range

	if can_see_player:
		state = State.CHASE
		if not was_chasing:
			_alert_burst_timer = alert_burst_duration
	else:
		state = State.WANDER
		_alert_burst_timer = 0.0

	if _alert_burst_timer > 0.0:
		_alert_burst_timer = maxf(_alert_burst_timer - delta, 0.0)


func _get_state_move_direction(delta: float) -> Vector2:
	if state == State.CHASE:
		return (player.global_position - global_position).normalized()

	_wander_timer -= delta
	if _wander_timer <= 0.0 or global_position.distance_to(_wander_target) < 20.0:
		_pick_wander_target()

	return (_wander_target - global_position).normalized()


func _apply_wall_slide(move_dir: Vector2, delta: float) -> Vector2:
	# is_on_wall() reports the last move_and_slide() result, so this reacts
	# one physics frame after contact and helps the enemy curve around edges.
	if is_on_wall():
		var wall_normal: Vector2 = get_wall_normal()
		_wall_slide_dir = (move_dir + wall_normal * 0.8).normalized()
		_wall_slide_timer = 0.4

	if _wall_slide_timer <= 0.0:
		return move_dir

	_wall_slide_timer -= delta
	var blend: float = _wall_slide_timer / 0.4
	return move_dir.lerp(_wall_slide_dir, blend).normalized()


func _pick_wander_target() -> void:
	var offset: Vector2 = Vector2(randf_range(-200.0, 200.0), randf_range(-200.0, 200.0))
	_wander_target = global_position + offset
	_wander_timer = randf_range(2.0, 4.0)


func _get_separation_force() -> Vector2:
	var push: Vector2 = Vector2.ZERO
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")

	for enemy in enemies:
		if enemy == self:
			continue

		var dist: float = global_position.distance_to(enemy.global_position)
		if dist < separation_radius and dist > 0.0:
			var away_dir: Vector2 = (global_position - enemy.global_position).normalized()
			var strength: float = 1.0 - (dist / separation_radius)
			push += away_dir * strength

	return push


func _update_sprite() -> void:
	if velocity.x < 0:
		sprite.flip_h = true
	elif velocity.x > 0:
		sprite.flip_h = false

	sprite.play("Move")


func _process_contact_damage(delta: float) -> void:
	if _contact_timer > 0.0:
		_contact_timer -= delta

	for i in range(get_slide_collision_count()):
		var collision: KinematicCollision2D = get_slide_collision(i)
		if collision.get_collider() == player:
			_deal_contact_damage()
			break


func _deal_contact_damage() -> void:
	if _contact_timer > 0.0:
		return

	var player_health = player.get_node_or_null("HealthSystem")
	if player_health:
		player_health.take_damage(damage)
		_contact_timer = contact_cooldown


func _on_died() -> void:
	GameManager.register_kill()
	XPDropSystem.spawn_drop(global_position, xp_gem_scene)
	GoldDropSystem.spawn_drop(global_position, _compute_gold_drop())
	queue_free()


func _compute_gold_drop() -> int:
	var mh: int = health_system.max_health if health_system else 30
	var dm: int = damage
	# Tougher bodies and harder hitters pay more, but early waves should not fund the whole shelf.
	var raw: int = int(roundf(float(mh + dm * 2) / 55.0))
	var scaled: int = int(roundf(float(raw) * gold_drop_multiplier))
	return maxi(1, scaled + gold_drop_bonus)
