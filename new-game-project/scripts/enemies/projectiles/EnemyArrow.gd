extends Area2D
class_name EnemyArrow

@export var move_speed: float = 260.0
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.RIGHT
var damage: int = 10
var _time_alive: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if direction.length_squared() > 0.0001:
		rotation = direction.angle()


func _process(delta: float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return

	global_position += direction * move_speed * delta
	_time_alive += delta
	if _time_alive >= lifetime:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	var health := body.get_node_or_null("HealthSystem")
	if health:
		health.take_damage(damage)
	queue_free()
