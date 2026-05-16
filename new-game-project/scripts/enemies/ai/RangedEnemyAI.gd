extends "res://scripts/enemies/ai/EnemyAI.gd"
class_name RangedEnemyAI

@export var projectile_scene: PackedScene
@export var preferred_range: float = 260.0
@export var retreat_range: float = 170.0
@export var shoot_range: float = 420.0
@export var shoot_cooldown: float = 2.2
@export var projectile_speed: float = 260.0

var _shoot_timer: float = 0.8


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if player == null or GameManager.state != GameManager.GameState.PLAYING:
		return

	_shoot_timer = maxf(_shoot_timer - delta, 0.0)
	if _shoot_timer <= 0.0 and global_position.distance_to(player.global_position) <= shoot_range:
		_shoot_projectile()
		_shoot_timer = shoot_cooldown


func _get_state_move_direction(delta: float) -> Vector2:
	if state != State.CHASE or player == null:
		return super._get_state_move_direction(delta)

	var to_player := player.global_position - global_position
	var distance := to_player.length()
	if distance < retreat_range:
		return -to_player.normalized()
	if distance > preferred_range:
		return to_player.normalized()
	return Vector2.ZERO


func _shoot_projectile() -> void:
	if projectile_scene == null or player == null:
		return

	var dir := (player.global_position - global_position).normalized()
	if dir.length_squared() <= 0.0001:
		return

	var projectile := projectile_scene.instantiate()
	projectile.direction = dir
	projectile.damage = damage
	if projectile.get("move_speed") != null:
		projectile.set("move_speed", projectile_speed)
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position + dir * 20.0
	_play_attack_animation()
