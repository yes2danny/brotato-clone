extends Area2D
class_name Bullet

# ─────────────────────────────────────────────
# Bullet
# Attach to an Area2D node (your Bullet scene root).
# A bullet is fired by WeaponController with a direction and damage value.
# It moves forward, damages the first enemy it hits, then destroys itself.
# It also auto-destroys after a set lifetime so stray bullets don't pile up.
#
# Set projectile_texture before add_child (from WeaponData.bullet_sprite), or
# leave null to use the procedural gradient blade in _draw() (no texture).
# ─────────────────────────────────────────────

@export var move_speed: float = 400.0   # Pixels per second
@export var lifetime: float = 2.0       # Seconds until auto-destroy

var direction: Vector2 = Vector2.RIGHT  # Set by WeaponController before adding to scene
var damage: int = 20                    # Set by WeaponController
## Assigned by WeaponController before the bullet is added to the tree.
var projectile_texture: Texture2D = null

var _time_alive: float = 0.0

var _visual: Sprite2D


func _ready() -> void:
	_visual = get_node_or_null("Sprite2D") as Sprite2D
	body_entered.connect(_on_body_entered)
	if _visual != null and projectile_texture != null:
		_visual.texture = projectile_texture
		_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_visual.visible = true
	elif _visual != null:
		_visual.visible = false
	if direction.length_squared() > 0.0001:
		rotation = direction.angle()
	queue_redraw()


func _process(delta: float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return

	global_position += direction * move_speed * delta

	_time_alive += delta
	if _time_alive >= lifetime:
		queue_free()
	elif _visual != null and not _visual.visible:
		queue_redraw()


func _draw() -> void:
	if _visual != null and _visual.visible:
		return
	_draw_procedural_blade()


## Fallback art when no bullet_sprite is set: gradient “energy blade” along +X.
func _draw_procedural_blade() -> void:
	var t := _time_alive
	var shimmer: float = 0.12 * sin(t * 16.0)

	# Dark rim behind the fill (slightly larger diamond)
	var rim := PackedVector2Array([
		Vector2(-16, 0),
		Vector2(-5, -3.8),
		Vector2(17, 0),
		Vector2(-5, 3.8),
	])
	draw_polygon(rim, PackedColorArray([
		Color(0.04, 0.05, 0.1, 0.92),
		Color(0.08, 0.1, 0.16, 0.9),
		Color(0.06, 0.08, 0.14, 0.88),
		Color(0.08, 0.1, 0.16, 0.9),
	]))

	# Main blade: cool base → warm mid → hot bright tip (vertex colors = sliding gradient feel)
	var blade := PackedVector2Array([
		Vector2(-14, 0),
		Vector2(-4.5, -3.0),
		Vector2(15, 0),
		Vector2(-4.5, 3.0),
	])
	var tip := Color(1.0, 0.97, 0.78, 1.0).lerp(Color(1.0, 0.55, 0.25, 1.0), 0.35 + shimmer)
	var mid := Color(0.55, 0.72, 1.0, 0.95)
	var haft := Color(0.22, 0.28, 0.42, 0.92)
	draw_polygon(
		blade,
		PackedColorArray([haft, mid, tip, mid])
	)

	# Fine highlight (glint)
	draw_line(Vector2(-5, 0), Vector2(13, 0), Color(1, 1, 1, clampf(0.28 + shimmer * 2.0, 0.12, 0.55)), 1.15)

	# Core charge at the “grip”
	draw_circle(Vector2(-11, 0), 2.2, Color(0.45, 0.85, 1.0, 0.75 + shimmer))
	draw_circle(Vector2(-11, 0), 1.0, Color(1, 1, 1, 0.5))


# Called automatically when another physics body enters this Area2D
func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("enemies"):
		return

	var health = body.get_node_or_null("HealthSystem")
	if health:
		health.take_damage(damage)
	queue_free()
