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

@export var stolen_gold: int = 25  # Base loot

@onready var health_system: Node = $HealthSystem
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var player: CharacterBody2D = null
var _boost_timer: float = 0.0
var _cooldown_timer: float = 0.0
var _wall_slide_dir: Vector2 = Vector2.ZERO
var _wall_slide_timer: float = 0.0

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
	
	var dist_to_player = global_position.distance_to(player.global_position)
	
	if dist_to_player < flee_range and _cooldown_timer <= 0.0:
		_boost_timer = boost_duration
		_cooldown_timer = boost_cooldown
		
	var move_dir := Vector2.ZERO
	if dist_to_player < flee_range:
		# Run away from player, but curve away from map edges to avoid getting cornered
		var to_player = (player.global_position - global_position).normalized()
		var away_from_player = -to_player
		var map_center_dir = (Vector2.ZERO - global_position).normalized()
		var dist_from_center = global_position.length()
		
		# Weight increases as we get closer to the arena edge (960 is the boundary)
		var center_weight = clampf((dist_from_center - 600.0) / 300.0, 0.0, 1.5)
		
		# Calculate a perpendicular vector (sidestep) to skirt around the player
		var perp = Vector2(-to_player.y, to_player.x)
		if perp.dot(map_center_dir) < 0:
			perp = -perp # Pick the sidestep direction that leads closer to the center
			
		move_dir = (away_from_player + (map_center_dir * center_weight) + (perp * center_weight * 0.8)).normalized()
	else:
		# Find nearest gold to steal
		var nearest_gold: Node2D = null
		var min_dist: float = INF
		for coin in get_tree().get_nodes_in_group("gold_coin"):
			if not is_instance_valid(coin) or coin.get("_collected"): continue
			var d = global_position.distance_to(coin.global_position)
			if d < min_dist:
				min_dist = d
				nearest_gold = coin
		if nearest_gold:
			move_dir = (nearest_gold.global_position - global_position).normalized()
		else:
			# If no gold and player is far away, just idle / wander slightly
			move_dir = Vector2.ZERO
			
	move_dir = _apply_wall_slide(move_dir, delta)
	
	var current_speed = base_speed
	if _boost_timer > 0.0:
		current_speed = boost_speed
		
	velocity = move_dir * current_speed
	move_and_slide()
	_update_sprite()
	_steal_gold()

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
	for coin in get_tree().get_nodes_in_group("gold_coin"):
		if not is_instance_valid(coin) or coin.get("_collected"): continue
		if global_position.distance_to(coin.global_position) <= gold_steal_radius:
			coin._collected = true
			stolen_gold += coin.get("gold_value")
			coin.queue_free()
			
			# Little pop animation on steal
			var tw = create_tween()
			tw.tween_property(sprite, "scale", Vector2(3.5, 3.5), 0.05)
			tw.tween_property(sprite, "scale", Vector2(3.0, 3.0), 0.1)

func _on_died() -> void:
	# Spits out all the stolen gold + base payout
	var drops: int = int(ceil(float(stolen_gold) / 3.0))
	for i in range(drops):
		GoldDropSystem.spawn_drop(global_position, 3) # Drops smaller coins to make a huge explosion of coins
	queue_free()