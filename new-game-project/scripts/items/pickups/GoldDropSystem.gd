extends Node

# ─────────────────────────────────────────────
# GoldDropSystem (autoload)
# Spawns a small gold pickup at an enemy death position.
# Call: GoldDropSystem.spawn_drop(global_position, gold_amount)
# ─────────────────────────────────────────────

const _COIN_SCENE := preload("res://scenes/items/pickups/GoldCoin.tscn")
const _SCATTER_RADIUS := 14.0


func spawn_drop(at_global: Vector2, gold_amount: int) -> void:
	call_deferred("_spawn_drop_deferred", at_global, gold_amount)


func _spawn_drop_deferred(at_global: Vector2, gold_amount: int) -> void:
	if gold_amount <= 0:
		return
	var world: Node = get_tree().current_scene
	if world == null:
		return

	var inst: Node = _COIN_SCENE.instantiate()
	world.add_child(inst)

	var scatter := Vector2.ZERO
	if _SCATTER_RADIUS > 0.0:
		var r := _SCATTER_RADIUS
		scatter = Vector2(randf_range(-r, r), randf_range(-r, r))

	if inst is Node2D:
		(inst as Node2D).global_position = at_global + scatter
	elif inst is Node and "global_position" in inst:
		inst.set("global_position", at_global + scatter)

	if "gold_value" in inst:
		inst.set("gold_value", gold_amount)
