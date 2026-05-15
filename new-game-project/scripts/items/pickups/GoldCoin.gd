extends Area2D

# ─────────────────────────────────────────────
# GoldCoin — World pickup (same feel as XPGem)
# Flies toward the player in range; adds gold to ShopManager on pickup.
# Optional lifetime: after despawn_after_seconds the coin vanishes (risk/reward).
# Timer advances only while this node processes (paused tree = frozen timer).
# ─────────────────────────────────────────────

@export var gold_value: int = 3
@export var attract_radius: float = 90.0
@export var collect_radius: float = 22.0
@export var fly_speed: float = 220.0
## 0 = never despawn. Otherwise seconds until the coin is removed (default 8).
@export var despawn_after_seconds: float = 8.0
## When remaining time is below this, modulate fades slightly so the deadline reads visually.
@export var despawn_warn_seconds: float = 2.0

var _player: Node2D = null
var _collected: bool = false
var _time_alive: float = 0.0


func _ready() -> void:
	add_to_group("gold_coin")
	queue_redraw()
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]


func _draw() -> void:
	var outer := Color(0.95, 0.72, 0.18, 0.95)
	var inner := Color(1.0, 0.92, 0.45, 0.9)
	draw_circle(Vector2.ZERO, 7.0, outer)
	draw_circle(Vector2(-1.0, -1.0), 4.5, inner)
	draw_arc(Vector2.ZERO, 7.0, -PI * 0.35, PI * 0.25, 12, Color(0.55, 0.38, 0.08, 0.5), 2.0, true)


func _process(delta: float) -> void:
	if _collected:
		return

	if despawn_after_seconds > 0.0:
		_time_alive += delta
		if _time_alive >= despawn_after_seconds:
			queue_free()
			return
		var remaining: float = despawn_after_seconds - _time_alive
		if remaining < despawn_warn_seconds and despawn_warn_seconds > 0.0:
			modulate.a = lerpf(0.38, 1.0, remaining / despawn_warn_seconds)
		else:
			modulate.a = 1.0

	if _player == null or not is_instance_valid(_player):
		return
	if GameManager.state != GameManager.GameState.PLAYING:
		return

	var dist := global_position.distance_to(_player.global_position)
	if dist <= collect_radius:
		_collect()
		return
	var effective_attract_radius: float = attract_radius + _get_player_pickup_bonus()
	if dist <= effective_attract_radius:
		var dir := (_player.global_position - global_position).normalized()
		global_position += dir * fly_speed * delta


func _collect() -> void:
	_collected = true
	var sm := get_tree().get_first_node_in_group("shop_manager")
	if sm and sm.has_method("add_gold"):
		sm.add_gold(gold_value)
	else:
		push_warning("GoldCoin: no ShopManager in group 'shop_manager'")
	queue_free()


func _get_player_pickup_bonus() -> float:
	if _player == null:
		return 0.0
	var bonus = _player.get("pickup_radius_bonus")
	return float(bonus) if bonus != null else 0.0
