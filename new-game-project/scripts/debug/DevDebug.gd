extends Node

# ─────────────────────────────────────────────
# DevDebug — Autoload shortcuts for playtesting
#
# Active only in debug/editor runs (see _shortcuts_allowed). Toggle the
# on-screen hint panel with F1.
#
# F1  — Toggle this cheat sheet
# F4  — Wave timer −10 s (min 1 s left)
# F5  — Spawn one enemy (uses EnemySpawner pool)
# F6  — Force end current wave (same as timer hitting zero)
# F7  — +100 gold
# F8  — Close shop if it is open (starts next wave)
# F9  — Toggle weapon debug menu (equip guns from DevDebug’s list — not the shop)
# ─────────────────────────────────────────────

## Guns offered in the F9 debug menu only (shop does not sell weapons).
const _DEBUG_WEAPON_PATHS: Array[String] = [
	"res://resources/items/weapons/rifle_ar_1.tres",
	"res://resources/items/weapons/desert_tanned_ar.tres",
	"res://resources/items/weapons/trevor_like_ar.tres",
	"res://resources/items/weapons/ak47.tres",
	"res://resources/items/weapons/older_m16.tres",
	"res://resources/items/weapons/scar_h.tres",
	"res://resources/items/weapons/glock.tres",
	"res://resources/items/weapons/revolver_short_barrel.tres",
	"res://resources/items/weapons/p90.tres",
	"res://resources/items/weapons/shotgun_pump_custom.tres",
	"res://resources/items/weapons/smg_vector.tres",
]

const _GOLD_BONUS := 100
const _WAVE_TIME_SHAVE := 10.0

var _hint_layer: CanvasLayer = null
var _hint_label: Label = null
var _hints_visible: bool = false

var _weapon_menu_layer: CanvasLayer = null
var _weapon_menu_vbox: VBoxContainer = null
var _weapon_menu_visible: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_hint_overlay()
	_build_weapon_debug_menu()
	if _shortcuts_allowed():
		print("[DevDebug] Shortcuts on — F1 overlay | F9 weapon menu | F4–F8 see script header.")


func _shortcuts_allowed() -> bool:
	# Optional project override: add `dev_shortcuts=true` under [debug] in project.godot
	# to enable these keys in release exports when you need them.
	return ProjectSettings.get_setting("debug/dev_shortcuts", OS.is_debug_build())


func _build_hint_overlay() -> void:
	_hint_layer = CanvasLayer.new()
	_hint_layer.name = "DevDebugHints"
	_hint_layer.layer = 100
	_hint_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_hint_layer.visible = false
	add_child(_hint_layer)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	_hint_layer.add_child(margin)

	var align := HBoxContainer.new()
	align.set_anchors_preset(Control.PRESET_FULL_RECT)
	align.alignment = BoxContainer.ALIGNMENT_END
	margin.add_child(align)

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.07, 0.1, 0.88)
	sb.border_color = Color(0.35, 0.55, 0.4, 0.7)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", sb)
	align.add_child(panel)

	_hint_label = Label.new()
	_hint_label.add_theme_font_size_override("font_size", 13)
	_hint_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.82))
	_hint_label.text = _hint_text()
	panel.add_child(_hint_label)


func _hint_text() -> String:
	return (
		"[Dev] F1 hide  |  F9 weapon menu  |  F4 −10s wave  |  F5 spawn enemy\n"
		+ "F6 end wave  |  F7 +100 gold  |  F8 close shop"
	)


func _unhandled_input(event: InputEvent) -> void:
	if not _shortcuts_allowed():
		return
	if not event is InputEventKey:
		return
	var e := event as InputEventKey
	if not e.pressed or e.echo:
		return

	match e.keycode:
		KEY_F1:
			_toggle_hints()
			get_viewport().set_input_as_handled()
		KEY_F4:
			if _gameplay_unpaused():
				_skew_wave_time(-_WAVE_TIME_SHAVE)
			get_viewport().set_input_as_handled()
		KEY_F5:
			if _gameplay_unpaused():
				_spawn_enemy()
			get_viewport().set_input_as_handled()
		KEY_F6:
			if _gameplay_unpaused():
				_end_wave()
			get_viewport().set_input_as_handled()
		KEY_F7:
			_add_gold()
			get_viewport().set_input_as_handled()
		KEY_F8:
			_close_shop()
			get_viewport().set_input_as_handled()
		KEY_F9:
			_toggle_weapon_debug_menu()
			get_viewport().set_input_as_handled()


func _build_weapon_debug_menu() -> void:
	_weapon_menu_layer = CanvasLayer.new()
	_weapon_menu_layer.name = "DevDebugWeaponMenu"
	_weapon_menu_layer.layer = 101
	_weapon_menu_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_weapon_menu_layer.visible = false
	add_child(_weapon_menu_layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	_weapon_menu_layer.add_child(root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.45)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_weapon_menu_dim_gui_input)
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.1, 0.14, 0.97)
	sb.border_color = Color(0.4, 0.55, 0.75, 0.85)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 14.0
	sb.content_margin_right = 14.0
	sb.content_margin_top = 12.0
	sb.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	panel.add_child(outer)

	var title := Label.new()
	title.text = "Debug — equip weapon (dev list only)"
	title.add_theme_font_size_override("font_size", 16)
	outer.add_child(title)

	var sub := Label.new()
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color(0.75, 0.8, 0.88))
	sub.text = "Weapons are not sold in the shop — add paths to _DEBUG_WEAPON_PATHS in DevDebug.gd. Works while paused."
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size = Vector2(360, 0)
	outer.add_child(sub)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(380, 340)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)

	_weapon_menu_vbox = VBoxContainer.new()
	_weapon_menu_vbox.add_theme_constant_override("separation", 6)
	_weapon_menu_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_weapon_menu_vbox)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	outer.add_child(row)

	var close_btn := Button.new()
	close_btn.text = "Close (F9)"
	close_btn.custom_minimum_size = Vector2(120, 32)
	close_btn.pressed.connect(_toggle_weapon_debug_menu)
	row.add_child(close_btn)

	var refresh_btn := Button.new()
	refresh_btn.text = "Refresh list"
	refresh_btn.custom_minimum_size = Vector2(120, 32)
	refresh_btn.pressed.connect(_refresh_weapon_debug_buttons)
	row.add_child(refresh_btn)


func _on_weapon_menu_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _weapon_menu_visible:
			_toggle_weapon_debug_menu()


func _toggle_weapon_debug_menu() -> void:
	if _weapon_menu_layer == null:
		return
	_weapon_menu_visible = not _weapon_menu_visible
	_weapon_menu_layer.visible = _weapon_menu_visible
	if _weapon_menu_visible:
		_refresh_weapon_debug_buttons()


func _weapon_list_for_debug_menu() -> Array[WeaponData]:
	var out: Array[WeaponData] = []
	for path in _DEBUG_WEAPON_PATHS:
		if path.is_empty() or not ResourceLoader.exists(path):
			continue
		var res: Resource = load(path)
		if res is WeaponData:
			out.append(res as WeaponData)
	return out


func _refresh_weapon_debug_buttons() -> void:
	if _weapon_menu_vbox == null:
		return
	for c in _weapon_menu_vbox.get_children():
		c.queue_free()

	var list: Array[WeaponData] = _weapon_list_for_debug_menu()
	if list.is_empty():
		var empty := Label.new()
		empty.text = "No weapons in _DEBUG_WEAPON_PATHS (DevDebug.gd)."
		_weapon_menu_vbox.add_child(empty)
		return

	for wd in list:
		var btn := Button.new()
		btn.text = wd.weapon_name
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(360, 30)
		var captured: WeaponData = wd
		btn.pressed.connect(func() -> void:
			_equip_weapon_debug(captured)
		)
		_weapon_menu_vbox.add_child(btn)


func _equip_weapon_debug(weapon: WeaponData) -> void:
	if weapon == null:
		return
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("[DevDebug] Equip weapon — no node in group 'player'")
		return
	var wc: Node = player.get_node_or_null("WeaponController")
	if wc and wc.has_method("apply_from_weapon_data"):
		wc.apply_from_weapon_data(weapon)
		print("[DevDebug] Equipped: %s" % weapon.weapon_name)
	else:
		push_warning("[DevDebug] Equip weapon — no WeaponController.apply_from_weapon_data")


func _toggle_hints() -> void:
	_hints_visible = not _hints_visible
	if _hint_layer:
		_hint_layer.visible = _hints_visible


func _gameplay_unpaused() -> bool:
	return GameManager.state == GameManager.GameState.PLAYING and not get_tree().paused


func _wave_manager() -> Node:
	return get_tree().get_first_node_in_group("wave_manager")


func _spawn_enemy() -> void:
	var spawner: Node = get_tree().get_first_node_in_group("enemy_spawner")
	if spawner and spawner.has_method("dev_spawn_one"):
		spawner.dev_spawn_one()
		print("[DevDebug] Spawn enemy")
	else:
		push_warning("[DevDebug] No EnemySpawner with dev_spawn_one()")


func _end_wave() -> void:
	var wm := _wave_manager()
	if wm and wm.has_method("dev_force_end_wave"):
		if wm.dev_force_end_wave():
			print("[DevDebug] Force end wave")
		else:
			print("[DevDebug] End wave skipped (already between waves / shop)")
	else:
		push_warning("[DevDebug] No WaveManager with dev_force_end_wave()")


func _skew_wave_time(delta_sec: float) -> void:
	var wm := _wave_manager()
	if wm and wm.has_method("dev_adjust_wave_time_remaining"):
		wm.dev_adjust_wave_time_remaining(delta_sec)
		print("[DevDebug] Wave time %+0.1f s" % delta_sec)
	else:
		push_warning("[DevDebug] No WaveManager with dev_adjust_wave_time_remaining()")


func _add_gold() -> void:
	var sm := get_tree().get_first_node_in_group("shop_manager")
	if sm and sm.has_method("add_gold"):
		sm.add_gold(_GOLD_BONUS)
		print("[DevDebug] +%d gold" % _GOLD_BONUS)
	else:
		push_warning("[DevDebug] No ShopManager.add_gold")


func _close_shop() -> void:
	var sm := get_tree().get_first_node_in_group("shop_manager")
	if sm == null or not sm.has_method("close_shop"):
		print("[DevDebug] Close shop — no ShopManager")
		return
	if not sm.is_shop_open:
		print("[DevDebug] Close shop — shop not open")
		return
	sm.close_shop()
	print("[DevDebug] Close shop")
