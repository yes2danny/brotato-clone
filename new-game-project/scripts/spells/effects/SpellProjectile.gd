extends Area2D
class_name SpellProjectile

@export var move_speed: float = 320.0
@export var lifetime: float = 4.0

var damage: int = 30
var school: SpellData.School = SpellData.School.FIRE
var rank: int = 1
var projectile_scale: float = 1.0

var _direction: Vector2 = Vector2.RIGHT
var _time_alive: float = 0.0
var _hit: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	queue_redraw()


func setup(spell: SpellData, target: Node2D = null, direction: Vector2 = Vector2.ZERO) -> void:
	damage = spell.base_damage
	school = spell.school
	rank = spell.rank
	move_speed = spell.projectile_speed
	lifetime = spell.projectile_lifetime
	projectile_scale = spell.projectile_scale

	if direction.length_squared() > 0.0001:
		_direction = direction.normalized()
	elif target != null and is_instance_valid(target):
		_direction = (target.global_position - global_position).normalized()
	else:
		_direction = Vector2.RIGHT

	rotation = _direction.angle()


func _process(delta: float) -> void:
	_time_alive += delta
	if _time_alive >= lifetime:
		queue_free()
		return
	global_position += _direction * move_speed * delta
	queue_redraw()


func _draw() -> void:
	var pulse := 0.08 * sin(_time_alive * (14.0 + float(rank) * 1.5))
	var colors := _palette_for_school()
	var s := projectile_scale

	var rim := PackedVector2Array([
		Vector2(-18, 0),
		Vector2(-5, -8),
		Vector2(14, -5),
		Vector2(20, 0),
		Vector2(14, 5),
		Vector2(-5, 8),
	])
	var core := PackedVector2Array([
		Vector2(-15, 0),
		Vector2(-3, -6),
		Vector2(12, -4),
		Vector2(17, 0),
		Vector2(12, 4),
		Vector2(-3, 6),
	])
	for i in rim.size():
		rim[i] *= s
	for i in core.size():
		core[i] *= s

	draw_colored_polygon(rim, colors[0])
	draw_colored_polygon(core, colors[1])
	draw_circle(Vector2(7, 0) * s, 5.5 * s, colors[2])
	draw_circle(Vector2(9, 0) * s, 2.8 * s, Color(1.0, 1.0, 1.0, 0.92 + pulse))


func _on_body_entered(body: Node) -> void:
	if _hit:
		return
	if not body.is_in_group("enemies"):
		return

	_hit = true
	var health := body.get_node_or_null("HealthSystem")
	if health and health.has_method("take_damage"):
		health.take_damage(damage)
	queue_free()


func _palette_for_school() -> Array[Color]:
	match school:
		SpellData.School.SHOCK:
			return [
				Color(0.02, 0.12, 0.34, 0.86),
				Color(0.2, 0.62, 1.0, 0.98),
				Color(0.92, 0.98, 1.0, 0.98),
			]
		SpellData.School.POISON:
			return [
				Color(0.05, 0.18, 0.08, 0.86),
				Color(0.28, 0.82, 0.26, 0.98),
				Color(0.88, 1.0, 0.56, 0.98),
			]
		SpellData.School.WATER:
			return [
				Color(0.03, 0.14, 0.22, 0.86),
				Color(0.22, 0.8, 0.96, 0.98),
				Color(0.86, 0.98, 1.0, 0.98),
			]
		SpellData.School.DARK:
			return [
				Color(0.08, 0.05, 0.12, 0.9),
				Color(0.48, 0.36, 0.72, 0.98),
				Color(0.84, 0.78, 0.98, 0.96),
			]
		SpellData.School.BLOOD:
			return [
				Color(0.22, 0.03, 0.04, 0.9),
				Color(0.78, 0.1, 0.14, 0.98),
				Color(1.0, 0.72, 0.76, 0.98),
			]
		_:
			return [
				Color(0.28, 0.06, 0.01, 0.86),
				Color(1.0, 0.38, 0.06, 0.98),
				Color(1.0, 0.82, 0.28, 0.98),
			]
