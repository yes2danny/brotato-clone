extends Area2D

# ─────────────────────────────────────────────
# XPGem
# Dropped by enemies when they die.
# Floats toward the player when they get close enough,
# and is collected (gives XP) when the player touches it.
#
# NOTE: We do distance checks manually in _process() rather than
# relying on collision signals — collision-based pickup was unreliable
# (gems could be missed if the player moved through quickly).
# ─────────────────────────────────────────────

@export var xp_value: int = 5                # How much XP this gem gives
@export var attract_radius: float = 150.0    # Distance at which gem starts flying toward player
@export var collect_radius: float = 20.0     # Distance at which gem is collected
@export var fly_speed: float = 200.0         # Speed when flying toward player

var _player: Node2D = null
var _collected: bool = false  # Guard flag — prevents collecting the same gem twice
var _use_placeholder_art: bool = false


func _ready() -> void:
	var sprite: Sprite2D = get_node_or_null("Sprite2D")
	if sprite and sprite.texture == null:
		_use_placeholder_art = true
		queue_redraw()
	# Find the player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]


func _draw() -> void:
	if not _use_placeholder_art:
		return
	var c := Color(0.35, 0.95, 1.0, 0.95)
	# Simple gem silhouette — replace by assigning a texture on Sprite2D
	var pts := PackedVector2Array([
		Vector2(0, -8), Vector2(7, 0), Vector2(0, 9), Vector2(-7, 0)
	])
	draw_colored_polygon(pts, c)
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(1, 1, 1, 0.35), 2.0, true)


func _process(delta: float) -> void:
	# If already collected or player is gone, do nothing
	if _collected or _player == null:
		return

	var dist = global_position.distance_to(_player.global_position)

	# ── Collection ──
	if dist <= collect_radius:
		_collect()
		return

	# ── Attraction ──
	# Once within attract radius, fly toward the player each frame
	var effective_attract_radius: float = attract_radius + _get_player_pickup_bonus()
	if dist <= effective_attract_radius:
		var dir = (_player.global_position - global_position).normalized()
		position += dir * fly_speed * delta


func _collect() -> void:
	_collected = true  # Set flag first so _process() can't trigger this twice

	# Give XP to the player via the XPSystem singleton
	XPSystem.add_xp(xp_value)

	# Remove the gem from the scene
	queue_free()


func _get_player_pickup_bonus() -> float:
	if _player == null:
		return 0.0
	var bonus = _player.get("pickup_radius_bonus")
	return float(bonus) if bonus != null else 0.0
