extends Node2D

# ─────────────────────────────────────────────
# WeaponController
# Attach to a child Node2D of the Player.
#
# HOW THE VISUAL WORKS:
#   This node IS the pivot point. It rotates to face the nearest enemy.
#   In _ready() we CREATE a Sprite2D child in pure code — no scene editing
#   needed, so there's zero chance of duplicates.
#   Sprite: res://assets/weapons/ranged/weapons.png — sheet is 66×704.
#   Layout is **2 guns per row** (~33×32 px each). Using the full 66px width
#   showed two rifles at once; crop to one cell with spritesheet_cell_index,
#   or use per-gun **WeaponData** resources (sprite_region_rect or cell index).
#
# HOW FIRING WORKS:
#   A timer fires bullet(s) toward the nearest enemy in range.
#   A tiny recoil tween kicks the sprite back on every shot for game feel.
# ─────────────────────────────────────────────

const _DEFAULT_BULLET := preload("res://scenes/weapons/projectiles/Bullet.tscn")
const _WEAPON_TEXTURE := preload("res://assets/weapons/ranged/weapons.png")

## Source sheet layout (verified PNG 66×704).
const SHEET_COLS: int = 2
const SHEET_CELL_WIDTH: int = 33
const SHEET_CELL_HEIGHT: int = 32
const SHEET_ROW_COUNT: int = 22
const SHEET_CELL_COUNT: int = SHEET_COLS * SHEET_ROW_COUNT

@export var bullet_scene: PackedScene
@export var fire_rate: float = 1.0 ## Shots per second (only used until a WeaponData is applied)
@export var detection_range: float = 300.0
@export var bullet_damage: int = 20

## Which gun from weapons.png: index 0 = top-left cell, then left-to-right, then next row (2 per row).
@export_range(0, SHEET_CELL_COUNT - 1) var weapon_sheet_cell_index: int = 0
## If enabled, uses weapon_region_manual instead of cell index math.
@export var use_weapon_region_manual: bool = false
@export var weapon_region_manual: Rect2 = Rect2(0, 0, 33, 32)
@export var weapon_sprite_scale: Vector2 = Vector2(1.3, 1.3)

@export var weapon_offset: float = 28.0

## Optional: apply this profile when the run starts (same stats as shop equip).
@export var starting_weapon: WeaponData

var _fire_interval: float = 1.0
var _fire_timer: float = 0.0
var _aim_dir: Vector2 = Vector2.RIGHT

var _sprite: Sprite2D
var _bullet_speed: float = 400.0
var _bullet_lifetime: float = 2.0
var _spread_angle: float = 0.0
var _projectile_count: int = 1
var _bullet_texture: Texture2D = null


func _ready() -> void:
	if bullet_scene == null:
		bullet_scene = _DEFAULT_BULLET
	_fire_interval = 1.0 / maxf(fire_rate, 0.01)

	var old_sprite := get_node_or_null("WeaponSprite")
	if old_sprite:
		old_sprite.queue_free()

	_sprite = Sprite2D.new()
	_sprite.name = "HeldWeaponSprite"
	_sprite.texture = _WEAPON_TEXTURE
	_sprite.region_enabled = true
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.position = Vector2(weapon_offset, 0)
	add_child(_sprite)
	_refresh_weapon_visual()
	if starting_weapon:
		call_deferred("_apply_starting_weapon")


func _apply_starting_weapon() -> void:
	if starting_weapon:
		apply_from_weapon_data(starting_weapon)
	else:
		_refresh_weapon_visual()


func _refresh_weapon_visual() -> void:
	if _sprite == null:
		return
	if use_weapon_region_manual:
		_sprite.region_rect = weapon_region_manual
	else:
		var idx := clampi(weapon_sheet_cell_index, 0, SHEET_CELL_COUNT - 1)
		var col := idx % SHEET_COLS
		var row: int = idx / SHEET_COLS
		_sprite.region_rect = Rect2(col * SHEET_CELL_WIDTH, row * SHEET_CELL_HEIGHT, SHEET_CELL_WIDTH, SHEET_CELL_HEIGHT)
	_sprite.scale = weapon_sprite_scale


## Call when equipping a weapon from the shop (WeaponData resource).
func apply_from_weapon_data(data: WeaponData) -> void:
	if data == null:
		return
	bullet_damage = data.damage
	fire_rate = data.fire_rate
	_fire_interval = 1.0 / maxf(fire_rate, 0.01)
	detection_range = data.detection_range
	_bullet_speed = data.bullet_speed
	_bullet_lifetime = data.bullet_lifetime
	_spread_angle = data.spread_angle
	_projectile_count = maxi(1, data.projectile_count)
	weapon_sprite_scale = data.weapon_sprite_scale
	_bullet_texture = data.bullet_sprite
	if data.use_sprite_region_rect:
		use_weapon_region_manual = true
		weapon_region_manual = data.sprite_region_rect
	else:
		use_weapon_region_manual = false
		weapon_sheet_cell_index = data.spritesheet_cell_index
	_refresh_weapon_visual()


func _process(delta: float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return

	var target := _get_nearest_enemy()
	if target != null:
		_aim_dir = (target.global_position - global_position).normalized()

	rotation = _aim_dir.angle()
	if _sprite:
		_sprite.flip_v = (_aim_dir.x < 0)

	_fire_timer -= delta
	if _fire_timer <= 0.0 and target != null:
		_try_fire(target)
		_fire_timer = _fire_interval


func _try_fire(_target: Node2D) -> void:
	var base_dir := ( _target.global_position - global_position ).normalized()
	if base_dir.length_squared() < 0.0001:
		return
	var dirs: Array[Vector2] = []
	if _projectile_count <= 1:
		var d := base_dir
		if _spread_angle > 0.0:
			d = base_dir.rotated(deg_to_rad(randf_range(-_spread_angle, _spread_angle)))
		dirs.append(d)
	else:
		var half := deg_to_rad(_spread_angle) * 0.5
		for i in _projectile_count:
			var t := -1.0 + (2.0 * float(i) / float(max(_projectile_count - 1, 1)))
			dirs.append(base_dir.rotated(t * half))
	for d in dirs:
		_spawn_bullet(d)
	_play_recoil()


func _get_nearest_enemy() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist: float = detection_range
	for enemy in enemies:
		var dist := global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest


func _spawn_bullet(dir: Vector2) -> void:
	if dir.length_squared() < 0.0001 or bullet_scene == null:
		return
	var bullet := bullet_scene.instantiate() as Bullet
	if bullet == null:
		return
	bullet.direction = dir.normalized()
	bullet.damage = bullet_damage
	bullet.move_speed = _bullet_speed
	bullet.lifetime = _bullet_lifetime
	bullet.projectile_texture = _bullet_texture
	var world := get_tree().current_scene
	if world == null:
		return
	world.add_child(bullet)
	bullet.global_position = global_position + _aim_dir * weapon_offset


func _play_recoil() -> void:
	if _sprite == null:
		return
	var tween := create_tween()
	var origin_x := weapon_offset
	tween.tween_property(_sprite, "position:x", origin_x - 4.0, 0.0)
	tween.tween_property(_sprite, "position:x", origin_x, 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)


func upgrade_fire_rate(multiplier: float) -> void:
	fire_rate = maxf(0.2, fire_rate * multiplier)
	_fire_interval = 1.0 / maxf(fire_rate, 0.01)


func upgrade_damage(amount: int) -> void:
	bullet_damage = maxi(1, bullet_damage + amount)
