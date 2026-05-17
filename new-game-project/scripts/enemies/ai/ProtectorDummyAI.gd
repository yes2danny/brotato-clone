extends "res://scripts/enemies/ai/EnemyAI.gd"
class_name ProtectorDummyAI

## Soft bodyguard behavior for Dummy_LVL2.
## Still chases the player, but gently biases toward screening nearby ranged allies.

@export var protect_search_radius: float = 320.0
@export var screen_distance_from_ranged: float = 72.0
@export var screen_influence: float = 0.42
@export var abandon_screen_player_distance: float = 150.0


func _get_state_move_direction(delta: float) -> Vector2:
	var base_dir: Vector2 = super._get_state_move_direction(delta)
	if state != State.CHASE or player == null:
		return base_dir

	if global_position.distance_to(player.global_position) <= abandon_screen_player_distance:
		return base_dir

	var protected_ranged := _nearest_ranged_ally()
	if protected_ranged == null:
		return base_dir

	var ranged_to_player: Vector2 = player.global_position - protected_ranged.global_position
	if ranged_to_player.length_squared() <= 0.0001:
		return base_dir

	var screen_point: Vector2 = protected_ranged.global_position + ranged_to_player.normalized() * screen_distance_from_ranged
	var screen_dir: Vector2 = (screen_point - global_position).normalized()
	if screen_dir.length_squared() <= 0.0001:
		return base_dir

	return base_dir.lerp(screen_dir, screen_influence).normalized()


func _nearest_ranged_ally() -> Node2D:
	var nearest: Node2D = null
	var nearest_dist: float = protect_search_radius

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == self or not is_instance_valid(enemy):
			continue
		if not enemy is RangedEnemyAI:
			continue

		var dist: float = global_position.distance_to(enemy.global_position)
		if dist <= nearest_dist:
			nearest = enemy
			nearest_dist = dist

	return nearest
