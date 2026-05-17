extends Area2D
class_name RingOfFireEffect

@export var frame_rate: float = 18.0

var damage: int = 0
var effect_radius: float = 72.0
var visual_scale: float = 1.0
var animation_frames_path: String = ""
var effect_duration: float = 0.45
var school: SpellData.School = SpellData.School.FIRE

var _sprite: AnimatedSprite2D
var _damaged_enemy_ids: Dictionary = {}
var _elapsed: float = 0.0
var _use_fallback_visual: bool = true


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	call_deferred("_damage_current_overlaps")
	queue_redraw()


func setup(spell: SpellData) -> void:
	damage = spell.base_damage
	effect_radius = spell.effect_radius
	visual_scale = spell.visual_scale
	animation_frames_path = spell.animation_frames_path
	effect_duration = spell.effect_duration
	school = spell.school
	_apply_radius()
	_build_animation()


func _process(delta: float) -> void:
	_elapsed += delta
	if _use_fallback_visual:
		if _elapsed >= effect_duration:
			queue_free()
			return
		queue_redraw()


func _draw() -> void:
	if not _use_fallback_visual:
		return
	var colors := _palette_for_school()
	var progress := clampf(_elapsed / maxf(effect_duration, 0.01), 0.0, 1.0)
	var alpha_scale := 1.0 - progress
	var outer_radius := effect_radius * visual_scale * (0.7 + progress * 0.3)
	var inner_radius := outer_radius * 0.58
	var glow_radius := outer_radius * 1.14

	var glow := colors[0]
	glow.a *= 0.28 * alpha_scale
	draw_circle(Vector2.ZERO, glow_radius, glow)

	var ring := colors[1]
	ring.a *= 0.8 * alpha_scale
	draw_arc(Vector2.ZERO, outer_radius, 0.0, TAU, 48, ring, maxf(6.0, 10.0 * visual_scale))

	var core := colors[2]
	core.a *= 0.45 * alpha_scale
	draw_circle(Vector2.ZERO, inner_radius, core)


func _apply_radius() -> void:
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		return
	var shape := collision.shape as CircleShape2D
	if shape:
		shape.radius = effect_radius


func _build_animation() -> void:
	_sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_use_fallback_visual = true
	if _sprite == null or animation_frames_path == "":
		return

	var dir := DirAccess.open(animation_frames_path)
	if dir == null:
		push_warning("[RingOfFireEffect] Could not open animation path: %s" % animation_frames_path)
		return

	var frame_paths: Array[String] = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.begins_with("frame-") and file_name.ends_with(".png"):
			frame_paths.append("%s/%s" % [animation_frames_path.trim_suffix("/"), file_name])
		file_name = dir.get_next()
	dir.list_dir_end()
	frame_paths.sort()
	if frame_paths.is_empty():
		return

	var frames := SpriteFrames.new()
	frames.add_animation("cast")
	frames.set_animation_loop("cast", false)
	frames.set_animation_speed("cast", frame_rate)
	for path in frame_paths:
		var texture := load(path) as Texture2D
		if texture:
			frames.add_frame("cast", texture)
	if frames.get_frame_count("cast") == 0:
		return

	_use_fallback_visual = false
	_sprite.sprite_frames = frames
	_sprite.scale = Vector2.ONE * visual_scale
	if not _sprite.animation_finished.is_connected(_on_animation_finished):
		_sprite.animation_finished.connect(_on_animation_finished)
	_sprite.play("cast")


func _damage_current_overlaps() -> void:
	for body in get_overlapping_bodies():
		_try_damage(body)


func _on_body_entered(body: Node) -> void:
	_try_damage(body)


func _on_animation_finished() -> void:
	queue_free()


func _try_damage(body: Node) -> void:
	if not body.is_in_group("enemies"):
		return
	var body_id := body.get_instance_id()
	if _damaged_enemy_ids.has(body_id):
		return
	_damaged_enemy_ids[body_id] = true
	var health := body.get_node_or_null("HealthSystem")
	if health and health.has_method("take_damage"):
		health.take_damage(damage)


func _palette_for_school() -> Array[Color]:
	match school:
		SpellData.School.SHOCK:
			return [
				Color(0.36, 0.74, 1.0, 0.5),
				Color(0.54, 0.9, 1.0, 0.92),
				Color(0.86, 0.98, 1.0, 0.42),
			]
		SpellData.School.POISON:
			return [
				Color(0.2, 0.62, 0.18, 0.48),
				Color(0.36, 0.86, 0.28, 0.92),
				Color(0.78, 1.0, 0.52, 0.42),
			]
		SpellData.School.WATER:
			return [
				Color(0.16, 0.62, 0.88, 0.5),
				Color(0.34, 0.86, 1.0, 0.92),
				Color(0.82, 0.96, 1.0, 0.4),
			]
		SpellData.School.DARK:
			return [
				Color(0.24, 0.16, 0.32, 0.48),
				Color(0.54, 0.44, 0.76, 0.9),
				Color(0.86, 0.8, 0.96, 0.36),
			]
		SpellData.School.BLOOD:
			return [
				Color(0.52, 0.12, 0.14, 0.48),
				Color(0.84, 0.18, 0.22, 0.92),
				Color(1.0, 0.72, 0.74, 0.38),
			]
		_:
			return [
				Color(0.92, 0.34, 0.08, 0.48),
				Color(1.0, 0.58, 0.14, 0.92),
				Color(1.0, 0.9, 0.36, 0.38),
			]
