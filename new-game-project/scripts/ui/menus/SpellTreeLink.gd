@tool
extends Line2D
class_name SpellTreeLink

# Editor-friendly connector line.
# When Danny drags spell nodes around in the SpellTreeUI scene, these lines
# follow the node centers automatically instead of needing manual redraws.

@export var from_node: NodePath
@export var to_node: NodePath


func _ready() -> void:
	_refresh_points()


func _process(_delta: float) -> void:
	_refresh_points()


func _refresh_points() -> void:
	if from_node.is_empty() or to_node.is_empty():
		return
	var from_control := get_node_or_null(from_node) as Control
	var to_control := get_node_or_null(to_node) as Control
	if from_control == null or to_control == null:
		return
	points = PackedVector2Array([
		to_local(from_control.global_position + from_control.size * 0.5),
		to_local(to_control.global_position + to_control.size * 0.5),
	])
