extends CanvasLayer

# ─────────────────────────────────────────────
# GameUI — HUD: health / XP bars + wave announcement (rustic plaque on wave start)
# If Main.tscn already has VBoxContainer/HPBar, we use it.
# Otherwise we build a small health block in the top-left.
# XP bar path unchanged if present; no XP UI is created here.
# ─────────────────────────────────────────────

var hp_bar: ProgressBar = null
var _hp_text_label: Label = null
var xp_bar: ProgressBar = null
var _gold_label: Label = null

var _health_hooked: bool = false
var _bar_smooth_speed: float = 10.0
var _hp_target_value: float = 100.0
var _hp_display_value: float = 100.0
var _xp_target_value: float = 0.0
var _xp_display_value: float = 0.0

# Wave announcement — rustic plaque, reused each wave via WaveManager.wave_started
var _wave_banner_root: Control = null
var _wave_banner_panel: PanelContainer = null
var _wave_banner_label: Label = null
var _wave_banner_tween: Tween = null
@export var wave_banner_fade_in: float = 0.42
@export var wave_banner_hold: float = 1.55
@export var wave_banner_fade_out: float = 0.48
## Vertical split: lower value = banner sits higher (share of extra space above vs below).
@export_range(0.1, 0.9, 0.01) var wave_banner_top_space_ratio: float = 0.34
## Extra horizontal bias (px): negative nudges left, positive right.
@export_range(-200.0, 200.0, 1.0) var wave_banner_nudge_x: float = -28.0


func _ready() -> void:
	_find_or_build_hp_bar()
	_build_wave_banner()
	_build_version_stamp()
	call_deferred("_connect_player_health")
	_connect_wave_manager()
	call_deferred("_setup_gold_hud")

	# XP — only if scene already has a bar (unchanged behavior)
	xp_bar = get_node_or_null("VBoxContainer/XPBar")
	XPSystem.xp_changed.connect(_on_xp_changed)
	if xp_bar:
		xp_bar.step = 0.01
		xp_bar.max_value = XPSystem.xp_to_next_level
		_xp_target_value = XPSystem.current_xp
		_xp_display_value = _xp_target_value
		xp_bar.value = _xp_display_value


func _process(delta: float) -> void:
	var blend := 1.0 - exp(-_bar_smooth_speed * delta)

	if hp_bar:
		_hp_display_value = lerpf(_hp_display_value, _hp_target_value, blend)
		if absf(_hp_display_value - _hp_target_value) < 0.05:
			_hp_display_value = _hp_target_value
		hp_bar.value = _hp_display_value

	if xp_bar:
		_xp_display_value = lerpf(_xp_display_value, _xp_target_value, blend)
		if absf(_xp_display_value - _xp_target_value) < 0.05:
			_xp_display_value = _xp_target_value
		xp_bar.value = _xp_display_value


func _find_or_build_hp_bar() -> void:
	hp_bar = get_node_or_null("VBoxContainer/HPBar")
	if hp_bar != null:
		_apply_hp_bar_style(hp_bar)
		_hp_text_label = get_node_or_null("VBoxContainer/HPValueLabel")
		return

	# --- Built-in player health HUD (no Main.tscn edits required) ---
	var root := Control.new()
	root.name = "HudRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var margin := MarginContainer.new()
	margin.name = "PlayerHealthMargin"
	margin.set_anchors_preset(Control.PRESET_TOP_LEFT)
	margin.offset_left = 16.0
	margin.offset_top = 14.0
	margin.offset_right = 16.0 + 268.0
	margin.offset_bottom = 14.0 + 76.0
	root.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Health"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	vbox.add_child(title)

	hp_bar = ProgressBar.new()
	hp_bar.name = "HPBar"
	hp_bar.min_value = 0.0
	hp_bar.max_value = 100.0
	hp_bar.value = 100.0
	hp_bar.step = 0.01
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(240.0, 20.0)
	_apply_hp_bar_style(hp_bar)
	vbox.add_child(hp_bar)

	_hp_text_label = Label.new()
	_hp_text_label.name = "HPValueLabel"
	_hp_text_label.add_theme_font_size_override("font_size", 12)
	_hp_text_label.add_theme_color_override("font_color", Color(0.65, 0.7, 0.78))
	_hp_text_label.text = "— / —"
	vbox.add_child(_hp_text_label)


func _apply_hp_bar_style(bar: ProgressBar) -> void:
	bar.step = 0.01

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.09, 0.12)
	bg.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg)

	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.25, 0.82, 0.52)
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)


func _connect_player_health() -> void:
	if hp_bar == null:
		return
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var health: Node = players[0].get_node_or_null("HealthSystem")
	if health == null:
		return
	if not _health_hooked:
		health.health_changed.connect(_on_health_changed)
		_health_hooked = true
	_on_health_changed(health.current_health, health.max_health)
	_hp_display_value = _hp_target_value
	hp_bar.value = _hp_display_value


func _on_health_changed(current: int, maximum: int) -> void:
	if hp_bar:
		hp_bar.max_value = maxf(float(maximum), 1.0)
		_hp_target_value = float(clampi(current, 0, maximum))
	if _hp_text_label:
		_hp_text_label.text = "%d / %d" % [clampi(current, 0, maximum), maximum]


func _on_xp_changed(current: int, required: int) -> void:
	if xp_bar:
		xp_bar.max_value = required
		_xp_target_value = current


func _setup_gold_hud() -> void:
	var attach: Control = get_node_or_null("HudRoot") as Control
	if attach == null:
		var overlay := Control.new()
		overlay.name = "GoldHudRoot"
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(overlay)
		attach = overlay

	var margin := MarginContainer.new()
	margin.name = "GoldHudMargin"
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	margin.anchor_left = 1.0
	margin.anchor_right = 1.0
	margin.offset_left = -220.0
	margin.offset_right = -14.0
	margin.offset_top = 12.0
	margin.offset_bottom = 46.0
	attach.add_child(margin)

	_gold_label = Label.new()
	_gold_label.name = "GoldHudLabel"
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_gold_label.text = "Gold: 0"
	_gold_label.add_theme_font_size_override("font_size", 18)
	_gold_label.add_theme_color_override("font_color", Color(0.98, 0.86, 0.38))
	_gold_label.add_theme_color_override("font_outline_color", Color(0.06, 0.05, 0.04, 0.78))
	_gold_label.add_theme_constant_override("outline_size", 4)
	margin.add_child(_gold_label)

	var sm := get_tree().get_first_node_in_group("shop_manager")
	if sm == null:
		_gold_label.text = "Gold: —"
		return
	if not sm.gold_changed.is_connected(_on_gold_hud_changed):
		sm.gold_changed.connect(_on_gold_hud_changed)
	_on_gold_hud_changed(sm.player_gold)


func _on_gold_hud_changed(amount: int) -> void:
	if _gold_label:
		_gold_label.text = "Gold: %d" % amount


func _build_version_stamp() -> void:
	var root := Control.new()
	root.name = "VersionStampRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var margin := MarginContainer.new()
	margin.name = "VersionStampMargin"
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	margin.anchor_left = 1.0
	margin.anchor_top = 1.0
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.offset_left = -180.0
	margin.offset_top = -34.0
	margin.offset_right = -12.0
	margin.offset_bottom = -10.0
	root.add_child(margin)

	var label := Label.new()
	label.name = "VersionStamp"
	label.text = BuildInfo.display_text()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72, 0.32))
	margin.add_child(label)


func _build_wave_banner() -> void:
	_wave_banner_root = Control.new()
	_wave_banner_root.name = "WaveBannerRoot"
	_wave_banner_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_wave_banner_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wave_banner_root.visible = false
	add_child(_wave_banner_root)

	# Bias above center (less “dead middle”) + slight horizontal nudge
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 0)
	_wave_banner_root.add_child(column)

	var top_spacer := Control.new()
	top_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_spacer.size_flags_stretch_ratio = wave_banner_top_space_ratio
	column.add_child(top_spacer)

	var row := MarginContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var side := int(roundf(absf(wave_banner_nudge_x)))
	if wave_banner_nudge_x <= 0.0:
		row.add_theme_constant_override("margin_left", 0)
		row.add_theme_constant_override("margin_right", side)
	else:
		row.add_theme_constant_override("margin_left", side)
		row.add_theme_constant_override("margin_right", 0)
	column.add_child(row)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_child(center)

	var bottom_spacer := Control.new()
	bottom_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom_spacer.size_flags_stretch_ratio = maxf(0.1, 1.0 - wave_banner_top_space_ratio)
	column.add_child(bottom_spacer)

	_wave_banner_panel = PanelContainer.new()
	_wave_banner_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wave_banner_panel.custom_minimum_size = Vector2(300.0, 84.0)
	_wave_banner_panel.pivot_offset = _wave_banner_panel.custom_minimum_size * 0.5

	# Frosted / airy plaque — low-alpha fill, thin soft border, no heavy “card” shadow
	var plaque := StyleBoxFlat.new()
	plaque.bg_color = Color(0.86, 0.76, 0.62, 0.26)
	plaque.border_color = Color(0.55, 0.36, 0.22, 0.38)
	plaque.set_border_width_all(1)
	plaque.set_corner_radius_all(22)
	plaque.shadow_color = Color(0.08, 0.05, 0.03, 0.18)
	plaque.shadow_size = 5
	plaque.content_margin_left = 22.0
	plaque.content_margin_right = 22.0
	plaque.content_margin_top = 14.0
	plaque.content_margin_bottom = 14.0
	_wave_banner_panel.add_theme_stylebox_override("panel", plaque)

	center.add_child(_wave_banner_panel)

	var inner := MarginContainer.new()
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wave_banner_panel.add_child(inner)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(v)

	_wave_banner_label = Label.new()
	_wave_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_wave_banner_label.text = "Wave 1"
	_wave_banner_label.add_theme_font_size_override("font_size", 40)
	_wave_banner_label.add_theme_color_override("font_color", Color(0.24, 0.15, 0.1, 0.88))
	_wave_banner_label.add_theme_color_override("font_outline_color", Color(0.98, 0.93, 0.86, 0.55))
	_wave_banner_label.add_theme_constant_override("outline_size", 5)
	v.add_child(_wave_banner_label)


func _connect_wave_manager() -> void:
	var wm: Node = get_parent().get_node_or_null("WaveManager")
	if wm == null:
		return
	if not wm.wave_started.is_connected(_on_wave_started):
		wm.wave_started.connect(_on_wave_started)


func _on_wave_started(wave_number: int) -> void:
	if _wave_banner_label == null or _wave_banner_root == null or _wave_banner_panel == null:
		return
	_wave_banner_label.text = "Wave %d" % wave_number
	_play_wave_banner_animation()


func _play_wave_banner_animation() -> void:
	if _wave_banner_tween != null:
		_wave_banner_tween.kill()

	_wave_banner_root.visible = true
	_wave_banner_root.modulate = Color(1, 1, 1, 1)
	_wave_banner_panel.scale = Vector2(0.94, 0.94)
	_wave_banner_panel.modulate = Color(1, 1, 1, 0)

	_wave_banner_tween = create_tween()
	_wave_banner_tween.set_parallel(true)
	_wave_banner_tween.tween_property(_wave_banner_panel, "modulate:a", 1.0, wave_banner_fade_in).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_wave_banner_tween.tween_property(_wave_banner_panel, "scale", Vector2.ONE, wave_banner_fade_in).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_wave_banner_tween.set_parallel(false)
	_wave_banner_tween.tween_interval(wave_banner_hold)
	_wave_banner_tween.tween_property(_wave_banner_panel, "modulate:a", 0.0, wave_banner_fade_out).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_wave_banner_tween.tween_callback(_hide_wave_banner_root)


func _hide_wave_banner_root() -> void:
	if _wave_banner_root:
		_wave_banner_root.visible = false
		_wave_banner_root.modulate = Color(1, 1, 1, 1)
	if _wave_banner_panel:
		_wave_banner_panel.modulate = Color(1, 1, 1, 1)
