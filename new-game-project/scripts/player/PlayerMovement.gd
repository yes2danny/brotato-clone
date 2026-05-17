extends CharacterBody2D

# ─────────────────────────────────────────────
# PlayerMovement
# Handles WASD movement, sprite flipping, and animation.
# ─────────────────────────────────────────────

@export var move_speed: float = 200.0
@export var pickup_radius_bonus: float = 0.0
@export var delayed_departure_boost_duration: float = 15.0
@export var dodge_roll_speed: float = 460.0
@export var dodge_roll_duration: float = 0.35
@export var dodge_invulnerability_duration: float = 0.32
@export var dodge_roll_cooldown: float = 1.0

# AnimatedSprite2D plays the right animation automatically
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_system: Node = $HealthSystem

var delayed_departure_stacks: int = 0
var _wave_move_speed_multiplier: float = 1.0
var _delayed_departure_timer: float = 0.0
var _delayed_departure_boosting: bool = false
var _roll_timer: float = 0.0
var _roll_cooldown_timer: float = 0.0
var _roll_direction: Vector2 = Vector2.RIGHT
var _last_move_direction: Vector2 = Vector2.RIGHT


func _ready() -> void:
	health_system.died.connect(_on_player_died)
	health_system.health_changed.connect(func(_current: int, _maximum: int) -> void: queue_redraw())
	add_to_group("player")
	call_deferred("_connect_wave_manager")



func _draw() -> void:
	if health_system and int(health_system.get("shield_hits")) > 0:
		draw_circle(Vector2.ZERO, 34.0, Color(0.22, 0.68, 1.0, 0.18))
		draw_arc(Vector2.ZERO, 34.0, 0.0, TAU, 48, Color(0.45, 0.9, 1.0, 0.65), 3.0, true)


func _physics_process(delta: float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return

	_update_delayed_departure(delta)

	var input_dir = Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)

	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1.0
	if Input.is_key_pressed(KEY_W):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		input_dir.y += 1.0

	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
		_last_move_direction = input_dir

	_roll_cooldown_timer = maxf(_roll_cooldown_timer - delta, 0.0)
	if _roll_timer > 0.0:
		_roll_timer = maxf(_roll_timer - delta, 0.0)
		velocity = _roll_direction * dodge_roll_speed
	elif Input.is_action_just_pressed("ui_accept") and _roll_cooldown_timer <= 0.0:
		_start_roll(input_dir)
		velocity = _roll_direction * dodge_roll_speed
	else:
		velocity = input_dir * move_speed * _wave_move_speed_multiplier

	# ── Flip sprite to face movement direction ──
	if velocity.x < 0:
		sprite.flip_h = true
	elif velocity.x > 0:
		sprite.flip_h = false

	# ── Play the right animation ──
	if _roll_timer > 0.0:
		sprite.play("Roll")
	elif input_dir.length() > 0:
		sprite.play("Move")
	else:
		sprite.play("Idle")

	move_and_slide()


func _on_player_died() -> void:
	GameManager.trigger_game_over()
	queue_free()


func add_delayed_departure(amount: int) -> void:
	delayed_departure_stacks = maxi(0, delayed_departure_stacks + amount)


func get_last_move_direction() -> Vector2:
	if _last_move_direction.length_squared() > 0.0:
		return _last_move_direction.normalized()
	return Vector2.RIGHT


func _start_roll(input_dir: Vector2) -> void:
	_roll_direction = input_dir if input_dir.length_squared() > 0.0 else _last_move_direction
	if _roll_direction.length_squared() <= 0.0:
		_roll_direction = Vector2.RIGHT
	_roll_timer = dodge_roll_duration
	_roll_cooldown_timer = dodge_roll_cooldown
	if health_system and health_system.has_method("start_invulnerability"):
		health_system.start_invulnerability(dodge_invulnerability_duration)


func _connect_wave_manager() -> void:
	var wm := get_tree().get_first_node_in_group("wave_manager")
	if wm and wm.has_signal("wave_started"):
		if not wm.wave_started.is_connected(_on_wave_started):
			wm.wave_started.connect(_on_wave_started)


func _on_wave_started(_wave_number: int) -> void:
	if delayed_departure_stacks <= 0:
		_wave_move_speed_multiplier = 1.0
		_delayed_departure_boosting = false
		_delayed_departure_timer = 0.0
		return
	_wave_move_speed_multiplier = 1.0 + 0.2 * float(delayed_departure_stacks)
	_delayed_departure_timer = delayed_departure_boost_duration
	_delayed_departure_boosting = true


func _update_delayed_departure(delta: float) -> void:
	if not _delayed_departure_boosting:
		return
	_delayed_departure_timer -= delta
	if _delayed_departure_timer <= 0.0:
		_wave_move_speed_multiplier = maxf(0.1, 1.0 - 0.1 * float(delayed_departure_stacks))
		_delayed_departure_boosting = false
