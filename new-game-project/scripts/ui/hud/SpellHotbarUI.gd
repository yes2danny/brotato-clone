extends Control
class_name SpellHotbarUI

# Compact spell HUD.
# The old version looked more like a debug card stack than a game hotbar.
# This version keeps the same behavior, but presents spells as icon-first slots:
# - a small pixel frame from the existing HUD asset set
# - spell art in the middle when one exists
# - a dark cooldown fill over the icon instead of a progress bar block

const HUD_EMPTY_BLUE := "res://assets/sprites/tilemaps/meadow/UI/UI-elements-32x32-separated sprites/skill_icon_slot_hud_empty_0.png"
const HUD_EMPTY_GOLD := "res://assets/sprites/tilemaps/meadow/UI/UI-elements-32x32-separated sprites/skill_icon_slot_hud_empty_1.png"
const HUD_EMPTY_ORANGE := "res://assets/sprites/tilemaps/meadow/UI/UI-elements-32x32-separated sprites/skill_icon_slot_hud_empty_2.png"

const SLOT_W := 68.0
const SLOT_H := 82.0
const SLOT_GAP := 10.0
const FRAME_SIZE := 52.0
const MARGIN_B := 18.0

const COL_EMPTY := Color(0.56, 0.58, 0.64, 0.5)
const COL_READY := Color(1.0, 0.92, 0.72, 1.0)
const COL_COOLDOWN := Color(0.04, 0.04, 0.06, 0.68)

var _sc: Node = null
var _slot_roots: Array[Control] = []
var _slot_buttons: Array[Button] = []
var _frame_rects: Array[TextureRect] = []
var _icon_rects: Array[TextureRect] = []
var _fallback_labels: Array[Label] = []
var _cooldown_masks: Array[ColorRect] = []
var _name_labels: Array[Label] = []
var _status_labels: Array[Label] = []


func _ready() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_hotbar()
	call_deferred("_connect_spell_controller")


func _connect_spell_controller() -> void:
	var controllers := get_tree().get_nodes_in_group("spell_controller")
	if controllers.is_empty():
		push_warning("[SpellHotbarUI] No SpellController found.")
		return
	_sc = controllers[0]
	_refresh_all_slots()


func _process(_delta: float) -> void:
	if _sc == null:
		return
	for i in SpellController.MAX_SPELL_SLOTS:
		_update_slot(i)


func _update_slot(i: int) -> void:
	var spell = _sc.equipped_spells[i]
	if spell == null:
		_slot_roots[i].modulate = COL_EMPTY
		_slot_buttons[i].disabled = true
		_frame_rects[i].texture = _load_tex(HUD_EMPTY_BLUE)
		_icon_rects[i].texture = null
		_fallback_labels[i].text = ""
		_name_labels[i].text = "Open"
		_status_labels[i].text = ""
		_cooldown_masks[i].visible = false
		return

	_slot_roots[i].modulate = Color.WHITE
	_slot_buttons[i].disabled = false
	_frame_rects[i].texture = _frame_for_spell(spell)
	_icon_rects[i].texture = spell.icon
	_icon_rects[i].visible = spell.icon != null
	_fallback_labels[i].visible = spell.icon == null
	_fallback_labels[i].text = spell.spell_name.left(1).to_upper()
	_name_labels[i].text = spell.spell_name

	var progress: float = _sc.get_cooldown_progress(i)
	var is_ready: bool = _sc.is_ready(i)  # renamed: 'ready' shadows the built-in Node signal
	_cooldown_masks[i].visible = not is_ready
	if is_ready:
		_status_labels[i].text = ""
		_name_labels[i].add_theme_color_override("font_color", COL_READY)
	else:
		var remaining: float = spell.cooldown * (1.0 - progress)
		_status_labels[i].text = "%.1f" % remaining
		_name_labels[i].add_theme_color_override("font_color", Color(0.78, 0.8, 0.88))
		var masked_height := FRAME_SIZE * (1.0 - progress)
		_cooldown_masks[i].position.y = FRAME_SIZE - masked_height
		_cooldown_masks[i].size.y = masked_height


func _refresh_all_slots() -> void:
	for i in SpellController.MAX_SPELL_SLOTS:
		_update_slot(i)


func _build_hotbar() -> void:
	var total_w := (SLOT_W * 3.0) + (SLOT_GAP * 2.0)
	var root := Control.new()
	root.name = "HotbarRoot"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.anchor_left = 0.5
	root.anchor_top = 1.0
	root.anchor_right = 0.5
	root.anchor_bottom = 1.0
	root.offset_left = -total_w * 0.5
	root.offset_right = total_w * 0.5
	root.offset_top = -(SLOT_H + MARGIN_B)
	root.offset_bottom = -MARGIN_B
	add_child(root)

	for i in SpellController.MAX_SPELL_SLOTS:
		var x := float(i) * (SLOT_W + SLOT_GAP)
		root.add_child(_make_slot(i, x))


func _make_slot(index: int, x: float) -> Control:
	var slot := Control.new()
	slot.name = "Slot%d" % index
	slot.position = Vector2(x, 0.0)
	slot.size = Vector2(SLOT_W, SLOT_H)
	_slot_roots.append(slot)

	var frame_holder := Control.new()
	frame_holder.position = Vector2((SLOT_W - FRAME_SIZE) * 0.5, 0.0)
	frame_holder.size = Vector2(FRAME_SIZE, FRAME_SIZE)
	slot.add_child(frame_holder)

	var frame := TextureRect.new()
	frame.texture = _load_tex(HUD_EMPTY_BLUE)
	frame.custom_minimum_size = Vector2(FRAME_SIZE, FRAME_SIZE)
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame_holder.add_child(frame)
	_frame_rects.append(frame)

	var icon := TextureRect.new()
	icon.position = Vector2(11, 11)
	icon.size = Vector2(30, 30)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame_holder.add_child(icon)
	_icon_rects.append(icon)

	var fallback := Label.new()
	fallback.position = Vector2(0, 10)
	fallback.size = Vector2(FRAME_SIZE, 28)
	fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fallback.add_theme_font_size_override("font_size", 18)
	fallback.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
	frame_holder.add_child(fallback)
	_fallback_labels.append(fallback)

	var cooldown := ColorRect.new()
	cooldown.color = COL_COOLDOWN
	cooldown.position = Vector2.ZERO
	cooldown.size = Vector2(FRAME_SIZE, 0.0)
	cooldown.visible = false
	frame_holder.add_child(cooldown)
	_cooldown_masks.append(cooldown)

	var key_lbl := Label.new()
	key_lbl.text = str(index + 1)
	key_lbl.position = Vector2(-2, -4)
	key_lbl.size = Vector2(16, 14)
	key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_lbl.add_theme_font_size_override("font_size", 10)
	key_lbl.add_theme_color_override("font_color", Color(0.94, 0.92, 0.82))
	frame_holder.add_child(key_lbl)

	var name_lbl := Label.new()
	name_lbl.position = Vector2(0, 54)
	name_lbl.size = Vector2(SLOT_W, 14)
	name_lbl.text = "Open"
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", Color(0.82, 0.84, 0.9))
	slot.add_child(name_lbl)
	_name_labels.append(name_lbl)

	var status_lbl := Label.new()
	status_lbl.position = Vector2(0, 68)
	status_lbl.size = Vector2(SLOT_W, 12)
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.add_theme_font_size_override("font_size", 10)
	status_lbl.add_theme_color_override("font_color", Color(0.92, 0.94, 1.0))
	slot.add_child(status_lbl)
	_status_labels.append(status_lbl)

	var cast_btn := Button.new()
	cast_btn.name = "CastButton"
	cast_btn.flat = true
	cast_btn.focus_mode = Control.FOCUS_NONE
	cast_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	cast_btn.pressed.connect(_on_slot_pressed.bind(index))
	slot.add_child(cast_btn)
	_slot_buttons.append(cast_btn)

	return slot


func _frame_for_spell(spell: SpellData) -> Texture2D:
	match spell.school:
		SpellData.School.FIRE:
			return _load_tex(HUD_EMPTY_ORANGE)
		SpellData.School.SHOCK:
			return _load_tex(HUD_EMPTY_BLUE)
		_:
			return _load_tex(HUD_EMPTY_GOLD)


func _on_slot_pressed(slot_index: int) -> void:
	if _sc and _sc.has_method("request_cast_slot"):
		_sc.request_cast_slot(slot_index)


func _load_tex(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		push_warning("[SpellHotbarUI] Texture not found: %s" % path)
		return null
	return load(path) as Texture2D
