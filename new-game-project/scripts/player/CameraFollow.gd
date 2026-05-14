extends Camera2D

# ─────────────────────────────────────────────
# CameraFollow
# Attach this script to a Camera2D node.
# It smoothly follows the player using linear interpolation (lerp).
#
# TIP: In Godot you can actually just make Camera2D a child of the
# Player node and it follows automatically — but this script gives you
# smooth lag/damping which feels much better in a fast-paced game.
# ─────────────────────────────────────────────

# How quickly the camera catches up to the player.
# 0 = never moves, 1 = snaps instantly, ~5 is a nice smooth follow.
@export var follow_speed: float = 5.0

# We'll grab a reference to the player once the scene is ready
var player: Node2D = null


func _ready() -> void:
	# Find the player by group — PlayerMovement.gd adds itself to "player" group
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]


func _process(delta: float) -> void:
	if player == null:
		return  # No player found, do nothing

	# lerp smoothly moves from current position toward target position.
	# delta * follow_speed controls how fast — frame-rate independent!
	# global_position is where the camera is in world space.
	global_position = global_position.lerp(player.global_position, follow_speed * delta)
