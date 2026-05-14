extends Node2D

# ─────────────────────────────────────────────
# MapBoundary
# Automatically creates 4 invisible collision walls around the map
# and locks the camera so it can't show the black void outside.
#
# Map is 20x20 tiles × 32px × scale 3 = 1920×1920px
# Centered at origin, so it runs from -960,-960 to 960,960
# ─────────────────────────────────────────────

# These match the map scale set in Main.tscn
# If you change the map scale, update half_size to match:
# half_size = tile_count × tile_size × map_scale / 2
# = 20 × 32 × 3 / 2 = 960
@export var half_size: float = 960.0
@export var wall_thickness: float = 32.0


func _ready() -> void:
	_build_walls()
	_lock_camera()


func _build_walls() -> void:
	# Each wall is a StaticBody2D with a RectangleShape2D
	# They're invisible — just solid physics barriers
	var walls = [
		# [position,          size]
		[Vector2(0, -half_size),         Vector2(half_size * 2, wall_thickness)],  # Top
		[Vector2(0,  half_size),         Vector2(half_size * 2, wall_thickness)],  # Bottom
		[Vector2(-half_size, 0),         Vector2(wall_thickness, half_size * 2)],  # Left
		[Vector2( half_size, 0),         Vector2(wall_thickness, half_size * 2)],  # Right
	]

	for wall_data in walls:
		# Create a StaticBody2D — this is what blocks movement
		var body = StaticBody2D.new()
		body.position = wall_data[0]
		add_child(body)

		# Add the actual shape to the body
		var shape = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = wall_data[1]
		shape.shape = rect
		body.add_child(shape)


func _lock_camera() -> void:
	# Find the Camera2D in the scene and set its limits
	# This stops the camera panning into the black void outside the map
	var camera = get_tree().get_first_node_in_group("camera")
	if camera == null:
		# Try finding it by type if not in group
		camera = _find_camera(get_tree().current_scene)

	if camera and camera is Camera2D:
		camera.limit_left   = -int(half_size)
		camera.limit_right  =  int(half_size)
		camera.limit_top    = -int(half_size)
		camera.limit_bottom =  int(half_size)


func _find_camera(node: Node) -> Node:
	# Recursive search for Camera2D in the scene tree
	if node is Camera2D:
		return node
	for child in node.get_children():
		var result = _find_camera(child)
		if result:
			return result
	return null
