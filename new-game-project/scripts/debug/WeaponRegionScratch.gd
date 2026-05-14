extends Node2D
## Run this scene (F6). Select **Sprite2D** in the Remote scene tree, tweak **Region Rect** in the
## Inspector, then press **Copy region** or **F2**. Clipboard gets a `Rect2(...)` line you can paste
## into a **WeaponData** resource (**Sprite Region Rect**) when **Use Sprite Region Rect** is on.

const _CELL_W: float = 33.0
const _CELL_H: float = 32.0
const _COLS: int = 2
const _MAX_CELL: int = 43

@onready var _sprite: Sprite2D = $Sprite2D

var _readout: Label
var _hint: Label
var _copy_btn: Button
var _flash_timer: float = 0.0


func _ready() -> void:
	_build_ui()


func _process(delta: float) -> void:
	if _readout == null or _sprite == null:
		return
	_readout.text = _build_readout_text()
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0 and _copy_btn:
			_copy_btn.text = "Copy region to clipboard"


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F2:
		_copy_to_clipboard()


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 128
	add_child(layer)

	var panel := PanelContainer.new()
	panel.offset_left = 8.0
	panel.offset_top = 8.0
	layer.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	_readout = Label.new()
	_readout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_readout.custom_minimum_size = Vector2(420, 0)
	vbox.add_child(_readout)

	_copy_btn = Button.new()
	_copy_btn.text = "Copy region to clipboard"
	_copy_btn.custom_minimum_size = Vector2(280, 36)
	_copy_btn.pressed.connect(_copy_to_clipboard)
	vbox.add_child(_copy_btn)

	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 12)
	_hint.modulate = Color(0.85, 0.9, 1.0, 0.9)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.custom_minimum_size = Vector2(420, 0)
	_hint.text = "Shortcut: F2. Paste: FileSystem → res://resources/items/weapons/ → double-click a gun .tres (e.g. rifle_ar_1.tres). Inspector → “Sprite crop” → Use Sprite Region Rect ON → paste into Sprite Region Rect. (Each gun = its own file.)"
	vbox.add_child(_hint)


func _rect2_clipboard(r: Rect2) -> String:
	return "Rect2(%s, %s, %s, %s)" % [r.position.x, r.position.y, r.size.x, r.size.y]


func _build_readout_text() -> String:
	var r := _sprite.region_rect
	var rect_s := _rect2_clipboard(r)
	var lines: PackedStringArray = []
	lines.append("Current: " + rect_s)
	var cell := _approx_cell_index(r)
	if cell >= 0:
		lines.append("Grid match (~33×32 aligned): spritesheet_cell_index = %d (then turn OFF Use Sprite Region Rect on WeaponData)." % cell)
	else:
		lines.append("Not a standard cell size/position — use Use Sprite Region Rect + paste the Rect2 line.")
	return "\n".join(lines)


func _approx_cell_index(r: Rect2) -> int:
	if r.size.x < 1.0 or r.size.y < 1.0:
		return -1
	if absf(r.size.x - _CELL_W) > 1.5 or absf(r.size.y - _CELL_H) > 1.5:
		return -1
	var col := int(round(r.position.x / _CELL_W))
	var row := int(round(r.position.y / _CELL_H))
	if col < 0 or col >= _COLS or row < 0:
		return -1
	var idx: int = row * _COLS + col
	if idx > _MAX_CELL:
		return -1
	var expected_x: float = float(col) * _CELL_W
	var expected_y: float = float(row) * _CELL_H
	if absf(r.position.x - expected_x) > 1.5 or absf(r.position.y - expected_y) > 1.5:
		return -1
	return idx


func _copy_to_clipboard() -> void:
	if _sprite == null:
		return
	var r := _sprite.region_rect
	var rect_s := _rect2_clipboard(r)
	var cell := _approx_cell_index(r)
	var parts: PackedStringArray = []
	parts.append(rect_s)
	if cell >= 0:
		parts.append("spritesheet_cell_index = %d" % cell)
	DisplayServer.clipboard_set("\n".join(parts))
	if _copy_btn:
		_copy_btn.text = "Copied!"
		_flash_timer = 1.2
