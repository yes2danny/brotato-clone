extends Control

# Main menu built from the existing pixel UI pack plus the local orc hero art.

const PATCH := 6

const PATH_PANEL_FRAME := "res://assets/ui/pixel_ui/Panels/Black/GridPanelFrame.png"
const PATH_PANEL_INNER := "res://assets/ui/pixel_ui/Panels/Black/GridPanel.png"
const PATH_GOLD_FRAME := "res://assets/ui/pixel_ui/Panels/Gold/GridPanelFrame.png"
const PATH_GOLD_INNER := "res://assets/ui/pixel_ui/Panels/Gold/GridPanel.png"
const PATH_PAPER_PANEL := "res://assets/ui/pixel_ui/Panels/Paper/PanelB.png"
const PATH_TITLE_BANNER := "res://assets/ui/pixel_ui/Banners/Gold/TitleBanner.png"
const PATH_DIVIDER := "res://assets/ui/pixel_ui/Decorators/Gold/DividerD.png"
const PATH_BACKGROUND_GRID := "res://assets/ui/pixel_ui/Arcade/BackgroundGrid.png"
const PATH_ORC_HERO := "res://assets/ui/main_menu/orc_hero.png"
const PATH_BTN_GOLD := "res://assets/ui/pixel_ui/Buttons/Gold/ButtonA_%s.png"
const PATH_BTN_BLACK := "res://assets/ui/pixel_ui/Buttons/Black/ButtonB_%s.png"

const MAIN_SCENE_PATH := "res://scenes/world/Main.tscn"

const COLOR_PAPER := Color(0.88, 0.78, 0.58)

var _pixel_ready := false
var _root_card: Control = null
var _play_button: Button = null
var _last_root_width := -1.0

# ── Overlay panels (settings / how-to-play) ───────────────────────────────────
# These are built lazily on first click and shown/hidden as needed.
var _settings_overlay  : Control = null
var _howtoplay_overlay : Control = null


func _ready() -> void:
	_pixel_ready = _check_pixel_assets()
	if not _pixel_ready:
		push_warning("MainMenu: missing some pixel UI art; using fallback styles.")
	_build_background()
	_build_layout()
	_build_version_stamp()
	call_deferred("_finish_first_layout")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_max_width()


func _check_pixel_assets() -> bool:
	var paths: Array[String] = [
		PATH_PANEL_FRAME,
		PATH_PANEL_INNER,
		PATH_GOLD_FRAME,
		PATH_GOLD_INNER,
		PATH_PAPER_PANEL,
		PATH_TITLE_BANNER,
		PATH_BTN_GOLD % "Unpressed",
		PATH_BTN_GOLD % "Highlighted",
		PATH_BTN_GOLD % "Pressed",
		PATH_BTN_BLACK % "Unpressed",
		PATH_ORC_HERO,
	]
	for path in paths:
		if not FileAccess.file_exists(path):
			return false
	return true


func _finish_first_layout() -> void:
	_apply_max_width()
	await get_tree().process_frame
	_apply_max_width()
	if is_instance_valid(_play_button):
		_play_button.grab_focus()


func _apply_max_width() -> void:
	if _root_card == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var next_width := maxf(360.0, minf(1080.0, viewport_size.x * 0.9))
	if is_equal_approx(next_width, _last_root_width):
		return
	_last_root_width = next_width
	_root_card.custom_minimum_size = Vector2(next_width, 0.0)


func _build_background() -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.045, 0.04, 0.055))
	gradient.set_color(1, Color(0.2, 0.16, 0.11))
	gradient.add_point(0.62, Color(0.105, 0.12, 0.09))

	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.08, 0.0)
	texture.fill_to = Vector2(1.0, 1.08)
	texture.width = 256
	texture.height = 256

	var backdrop := TextureRect.new()
	backdrop.name = "Backdrop"
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.texture = texture
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(backdrop)

	if FileAccess.file_exists(PATH_BACKGROUND_GRID):
		var grid := TextureRect.new()
		grid.name = "SubtleGrid"
		grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grid.set_anchors_preset(Control.PRESET_FULL_RECT)
		grid.texture = load(PATH_BACKGROUND_GRID) as Texture2D
		grid.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		grid.stretch_mode = TextureRect.STRETCH_TILE
		grid.modulate = Color(0.7, 0.9, 0.5, 0.055)
		add_child(grid)

	var shade := ColorRect.new()
	shade.name = "SoftShade"
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.23)
	add_child(shade)


func _build_version_stamp() -> void:
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
	add_child(margin)

	var label := Label.new()
	label.name = "VersionStamp"
	label.text = BuildInfo.display_text()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72, 0.32))
	margin.add_child(label)


func _build_layout() -> void:
	var safe_area := MarginContainer.new()
	safe_area.name = "SafeArea"
	safe_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	safe_area.add_theme_constant_override("margin_left", 32)
	safe_area.add_theme_constant_override("margin_right", 32)
	safe_area.add_theme_constant_override("margin_top", 28)
	safe_area.add_theme_constant_override("margin_bottom", 28)
	add_child(safe_area)

	var center := CenterContainer.new()
	center.name = "Center"
	safe_area.add_child(center)

	_root_card = _panel(PATH_PANEL_FRAME, PATH_PANEL_INNER, Color(0.08, 0.075, 0.09, 0.96), Color(0.46, 0.35, 0.18))
	center.add_child(_root_card)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 24)
	pad.add_theme_constant_override("margin_right", 24)
	pad.add_theme_constant_override("margin_top", 22)
	pad.add_theme_constant_override("margin_bottom", 22)
	_root_card.add_child(pad)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	pad.add_child(v)

	v.add_child(_build_title_band())

	var body := HBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 22)
	v.add_child(body)

	body.add_child(_build_hero_panel())
	body.add_child(_build_menu_panel())

	v.add_child(_build_footer_note())


func _build_title_band() -> Control:
	var wrap := PanelContainer.new()
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.custom_minimum_size = Vector2(0, 104)
	if _pixel_ready:
		var banner := _stylebox_texture(PATH_TITLE_BANNER, 12, 12, 12, 12)
		banner.content_margin_left = 18
		banner.content_margin_right = 18
		banner.content_margin_top = 10
		banner.content_margin_bottom = 10
		wrap.add_theme_stylebox_override("panel", banner)
	else:
		wrap.add_theme_stylebox_override("panel", _flat_panel(Color(0.26, 0.18, 0.08, 0.96), Color(0.8, 0.58, 0.22)))

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 3)
	wrap.add_child(v)

	var title := Label.new()
	title.text = "RIFT SURVIVOR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(0.15, 0.08, 0.04))
	title.add_theme_color_override("font_outline_color", Color(1.0, 0.9, 0.58, 0.75))
	title.add_theme_constant_override("outline_size", 5)
	v.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Loot fast. Shoot faster. Leave before the rift learns your name."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.33, 0.2, 0.08))
	subtitle.add_theme_color_override("font_outline_color", Color(1.0, 0.88, 0.58, 0.35))
	subtitle.add_theme_constant_override("outline_size", 2)
	v.add_child(subtitle)
	return wrap


func _build_hero_panel() -> Control:
	var panel := _panel(PATH_GOLD_FRAME, PATH_PANEL_INNER, Color(0.1, 0.1, 0.085, 0.94), Color(0.84, 0.61, 0.24))
	panel.custom_minimum_size = Vector2(400, 430)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 18)
	pad.add_theme_constant_override("margin_right", 18)
	pad.add_theme_constant_override("margin_top", 16)
	pad.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(pad)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 12)
	pad.add_child(v)

	var nameplate := _paper_label("Champion File", 16, Color(0.24, 0.14, 0.06))
	v.add_child(nameplate)

	var hero_wrap := CenterContainer.new()
	hero_wrap.custom_minimum_size = Vector2(0, 246)
	v.add_child(hero_wrap)

	var hero_back := PanelContainer.new()
	hero_back.custom_minimum_size = Vector2(250, 230)
	hero_back.add_theme_stylebox_override("panel", _flat_panel(Color(0.045, 0.06, 0.055, 0.72), Color(0.32, 0.42, 0.24)))
	hero_wrap.add_child(hero_back)

	var hero_center := CenterContainer.new()
	hero_back.add_child(hero_center)

	var hero := TextureRect.new()
	if FileAccess.file_exists(PATH_ORC_HERO):
		hero.texture = load(PATH_ORC_HERO) as Texture2D
	hero.custom_minimum_size = Vector2(220, 220)
	hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.modulate = Color(1.0, 1.0, 1.0, 1.0)
	hero_center.add_child(hero)

	var copy := Label.new()
	copy.text = "Built for ugly odds: quick feet, cheap weapons, and enough nerve to bargain between waves."
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.add_theme_font_size_override("font_size", 13)
	copy.add_theme_color_override("font_color", Color(0.84, 0.78, 0.64))
	copy.add_theme_color_override("font_outline_color", Color(0.02, 0.018, 0.02, 0.85))
	copy.add_theme_constant_override("outline_size", 2)
	v.add_child(copy)
	return panel


func _build_menu_panel() -> Control:
	var panel := _panel(PATH_PANEL_FRAME, PATH_PANEL_INNER, Color(0.085, 0.08, 0.095, 0.96), Color(0.42, 0.32, 0.18))
	panel.custom_minimum_size = Vector2(330, 430)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 22)
	pad.add_theme_constant_override("margin_right", 22)
	pad.add_theme_constant_override("margin_top", 20)
	pad.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(pad)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	pad.add_child(v)

	var header := Label.new()
	header.text = "Expedition"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 23)
	header.add_theme_color_override("font_color", Color(0.95, 0.82, 0.44))
	header.add_theme_color_override("font_outline_color", Color(0.035, 0.028, 0.04, 0.95))
	header.add_theme_constant_override("outline_size", 4)
	v.add_child(header)

	_add_divider(v)

	_play_button = Button.new()
	_play_button.text = "ENTER THE RIFT"
	_play_button.custom_minimum_size = Vector2(0, 50)
	_style_button(_play_button, PATH_BTN_GOLD, true)
	_play_button.pressed.connect(_on_play_pressed)
	v.add_child(_play_button)

	var settings_btn := Button.new()
	settings_btn.text = "SETTINGS"
	settings_btn.custom_minimum_size = Vector2(0, 44)
	_style_button(settings_btn, PATH_BTN_BLACK, false)
	settings_btn.pressed.connect(_on_settings_pressed)
	v.add_child(settings_btn)

	var howto_btn := Button.new()
	howto_btn.text = "HOW TO PLAY"
	howto_btn.custom_minimum_size = Vector2(0, 44)
	_style_button(howto_btn, PATH_BTN_BLACK, false)
	howto_btn.pressed.connect(_on_howtoplay_pressed)
	v.add_child(howto_btn)

	var quit := Button.new()
	quit.text = "LEAVE HALL"
	quit.custom_minimum_size = Vector2(0, 44)
	_style_button(quit, PATH_BTN_BLACK, false)
	quit.pressed.connect(_on_quit_pressed)
	v.add_child(quit)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 14)
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)

	var stats := _build_stat_strip()
	v.add_child(stats)

	var tip := Label.new()
	tip.text = "Gold buys upgrades. Panic spends them."
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.add_theme_font_size_override("font_size", 12)
	tip.add_theme_color_override("font_color", Color(0.72, 0.78, 0.62))
	tip.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.025, 0.7))
	tip.add_theme_constant_override("outline_size", 2)
	v.add_child(tip)
	return panel


func _build_stat_strip() -> Control:
	var strip := HBoxContainer.new()
	strip.alignment = BoxContainer.ALIGNMENT_CENTER
	strip.add_theme_constant_override("separation", 8)
	strip.add_child(_stat_chip("WAVES", "20"))
	strip.add_child(_stat_chip("SHOP", "READY"))
	strip.add_child(_stat_chip("ODDS", "BAD"))
	return strip


func _stat_chip(label_text: String, value_text: String) -> Control:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(84, 54)
	chip.add_theme_stylebox_override("panel", _flat_panel(Color(0.08, 0.075, 0.065, 0.92), Color(0.42, 0.34, 0.18)))

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 0)
	chip.add_child(v)

	var top := Label.new()
	top.text = label_text
	top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_theme_font_size_override("font_size", 9)
	top.add_theme_color_override("font_color", Color(0.6, 0.68, 0.48))
	v.add_child(top)

	var value := Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.add_theme_font_size_override("font_size", 13)
	value.add_theme_color_override("font_color", COLOR_PAPER)
	value.add_theme_color_override("font_outline_color", Color(0.02, 0.018, 0.02, 0.85))
	value.add_theme_constant_override("outline_size", 2)
	v.add_child(value)
	return chip


func _build_footer_note() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 70)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _pixel_ready:
		var paper := _stylebox_texture(PATH_PAPER_PANEL, 5, 5, 5, 5)
		paper.content_margin_left = 18
		paper.content_margin_right = 18
		paper.content_margin_top = 10
		paper.content_margin_bottom = 10
		panel.add_theme_stylebox_override("panel", paper)
	else:
		panel.add_theme_stylebox_override("panel", _flat_panel(Color(0.72, 0.62, 0.42, 0.92), Color(0.88, 0.68, 0.32)))

	var label := Label.new()
	label.text = "Current contract: survive the arena, collect gold, and return with enough scraps to make the next run less embarrassing."
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.23, 0.15, 0.08))
	panel.add_child(label)
	return panel


func _paper_label(text: String, font_size: int, font_color: Color) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 42)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _pixel_ready:
		var paper := _stylebox_texture(PATH_PAPER_PANEL, 5, 5, 5, 5)
		paper.content_margin_left = 12
		paper.content_margin_right = 12
		paper.content_margin_top = 7
		paper.content_margin_bottom = 7
		panel.add_theme_stylebox_override("panel", paper)
	else:
		panel.add_theme_stylebox_override("panel", _flat_panel(Color(0.76, 0.66, 0.44, 0.94), Color(0.82, 0.62, 0.28)))

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	panel.add_child(label)
	return panel


func _add_divider(parent: Control) -> void:
	if FileAccess.file_exists(PATH_DIVIDER):
		var divider := TextureRect.new()
		divider.texture = load(PATH_DIVIDER) as Texture2D
		divider.custom_minimum_size = Vector2(0, 18)
		divider.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		divider.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		divider.modulate = Color(1.0, 0.86, 0.38, 0.9)
		parent.add_child(divider)
	else:
		var line := ColorRect.new()
		line.custom_minimum_size = Vector2(0, 2)
		line.color = Color(0.72, 0.54, 0.22, 0.85)
		parent.add_child(line)


func _panel(frame_path: String, inner_path: String, fallback_bg: Color, fallback_border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	if _pixel_ready and FileAccess.file_exists(frame_path):
		panel.add_theme_stylebox_override("panel", _stylebox_texture(frame_path, PATCH, PATCH, PATCH, PATCH))
	elif _pixel_ready and FileAccess.file_exists(inner_path):
		panel.add_theme_stylebox_override("panel", _stylebox_texture(inner_path, PATCH, PATCH, PATCH, PATCH))
	else:
		panel.add_theme_stylebox_override("panel", _flat_panel(fallback_bg, fallback_border))
	return panel


func _stylebox_texture(path: String, left: int, top: int, right: int, bottom: int) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(path) as Texture2D
	style.texture_margin_left = left
	style.texture_margin_top = top
	style.texture_margin_right = right
	style.texture_margin_bottom = bottom
	return style


func _flat_panel(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _style_button(button: Button, path_template: String, primary: bool) -> void:
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 16 if primary else 14)

	if _pixel_ready and FileAccess.file_exists(path_template % "Unpressed"):
		var normal := _button_box(path_template % "Unpressed")
		var hover := _button_box(path_template % "Highlighted")
		var pressed := _button_box(path_template % "Pressed")
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", pressed)
		button.add_theme_stylebox_override("focus", hover)
	else:
		var normal_flat := _flat_panel(Color(0.28, 0.2, 0.12, 0.95), Color(0.84, 0.62, 0.26))
		var hover_flat := normal_flat.duplicate() as StyleBoxFlat
		hover_flat.bg_color = Color(0.36, 0.27, 0.16, 0.98)
		button.add_theme_stylebox_override("normal", normal_flat)
		button.add_theme_stylebox_override("hover", hover_flat)

	if primary:
		button.add_theme_color_override("font_color", Color(0.13, 0.075, 0.035))
		button.add_theme_color_override("font_outline_color", Color(1.0, 0.88, 0.45, 0.55))
	else:
		button.add_theme_color_override("font_color", Color(0.86, 0.78, 0.62))
		button.add_theme_color_override("font_outline_color", Color(0.02, 0.018, 0.02, 0.85))
	button.add_theme_constant_override("outline_size", 2)


func _button_box(path: String) -> StyleBoxTexture:
	var style := _stylebox_texture(path, 11, 6, 11, 6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style


func _on_play_pressed() -> void:
	GameManager.begin_new_run()
	var err := get_tree().change_scene_to_file(MAIN_SCENE_PATH)
	if err != OK:
		push_error("MainMenu: failed to load gameplay scene at %s (error %d)." % [MAIN_SCENE_PATH, err])


func _on_settings_pressed() -> void:
	# Build the overlay once, then just toggle visibility
	if _settings_overlay == null:
		_settings_overlay = _build_settings_overlay()
		add_child(_settings_overlay)
	_settings_overlay.visible = true


func _on_howtoplay_pressed() -> void:
	if _howtoplay_overlay == null:
		_howtoplay_overlay = _build_howtoplay_overlay()
		add_child(_howtoplay_overlay)
	_howtoplay_overlay.visible = true


func _on_quit_pressed() -> void:
	GameManager.quit_game()


# ─────────────────────────────────────────────────────────────────────────────
# Settings overlay
# Shows master / music / SFX volume sliders and a fullscreen toggle.
# Built programmatically so it matches the main-menu visual style exactly.
# ─────────────────────────────────────────────────────────────────────────────

func _build_settings_overlay() -> Control:
	# Full-screen dim + centred card (same pattern as WaveSummaryUI / ShopUI)
	var root := Control.new()
	root.name = "SettingsOverlay"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP   # block clicks behind it

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.80)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var card := _panel(PATH_PANEL_FRAME, PATH_PANEL_INNER,
			Color(0.07, 0.065, 0.085, 0.97), Color(0.42, 0.32, 0.18))
	card.custom_minimum_size = Vector2(440, 0)
	center.add_child(card)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left",   28)
	pad.add_theme_constant_override("margin_right",  28)
	pad.add_theme_constant_override("margin_top",    24)
	pad.add_theme_constant_override("margin_bottom", 24)
	card.add_child(pad)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	pad.add_child(v)

	# Title
	var title := Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.44))
	title.add_theme_color_override("font_outline_color", Color(0.035, 0.028, 0.04, 0.95))
	title.add_theme_constant_override("outline_size", 4)
	v.add_child(title)

	_add_divider(v)

	# ── Volume sliders ────────────────────────────────────────────────────────
	# Godot uses AudioServer buses: 0 = Master, higher indices = named buses.
	# We try to find "Music" and "SFX" buses by name; fall back to Master only.
	_add_volume_row(v, "Master Volume", "Master")
	_add_volume_row(v, "Music Volume",  "Music")
	_add_volume_row(v, "SFX Volume",    "SFX")

	_add_divider(v)

	# ── Fullscreen toggle ─────────────────────────────────────────────────────
	var fs_row := HBoxContainer.new()
	fs_row.add_theme_constant_override("separation", 14)
	v.add_child(fs_row)

	var fs_label := Label.new()
	fs_label.text = "Fullscreen"
	fs_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fs_label.add_theme_font_size_override("font_size", 15)
	fs_label.add_theme_color_override("font_color", COLOR_PAPER)
	fs_row.add_child(fs_label)

	var fs_btn := CheckButton.new()
	fs_btn.text = ""
	# Set the toggle to match the current window mode
	fs_btn.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN or
							 DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	fs_btn.toggled.connect(_on_fullscreen_toggled)
	fs_row.add_child(fs_btn)

	_add_divider(v)

	# ── Back button ───────────────────────────────────────────────────────────
	var back := Button.new()
	back.text = "BACK"
	back.custom_minimum_size = Vector2(0, 46)
	_style_button(back, PATH_BTN_BLACK, false)
	back.pressed.connect(func(): root.visible = false)
	v.add_child(back)

	return root


## Adds one labelled HSlider row that controls an AudioServer bus by name.
func _add_volume_row(parent: VBoxContainer, label_text: String, bus_name: String) -> void:
	# If the bus doesn't exist in this project, skip the row rather than error
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx < 0:
		return

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	parent.add_child(row)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(130, 0)
	lbl.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", COLOR_PAPER)
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.min_value  = 0.0
	slider.max_value  = 1.0
	slider.step       = 0.01
	# AudioServer volumes are in linear scale; convert from dB
	slider.value      = db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	# Store bus index in metadata so the signal handler knows which bus to change
	slider.set_meta("bus_idx", bus_idx)
	slider.value_changed.connect(_on_volume_changed.bind(bus_idx))
	row.add_child(slider)

	# Percentage readout next to the slider
	var pct := Label.new()
	pct.custom_minimum_size = Vector2(40, 0)
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pct.add_theme_font_size_override("font_size", 13)
	pct.add_theme_color_override("font_color", Color(0.72, 0.78, 0.62))
	pct.text = "%d%%" % int(slider.value * 100)
	row.add_child(pct)

	# Keep the percentage label in sync as the slider moves
	slider.value_changed.connect(func(v: float): pct.text = "%d%%" % int(v * 100))


func _on_volume_changed(value: float, bus_idx: int) -> void:
	# value is 0.0–1.0 linear; AudioServer wants dB
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))


func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


# ─────────────────────────────────────────────────────────────────────────────
# How to Play overlay
# Quick reference card for movement, shooting, spells, and shop.
# ─────────────────────────────────────────────────────────────────────────────

func _build_howtoplay_overlay() -> Control:
	var root := Control.new()
	root.name = "HowToPlayOverlay"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.82)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var card := _panel(PATH_GOLD_FRAME, PATH_PANEL_INNER,
			Color(0.07, 0.065, 0.05, 0.97), Color(0.84, 0.61, 0.24))
	card.custom_minimum_size = Vector2(520, 0)
	center.add_child(card)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left",   30)
	pad.add_theme_constant_override("margin_right",  30)
	pad.add_theme_constant_override("margin_top",    24)
	pad.add_theme_constant_override("margin_bottom", 24)
	card.add_child(pad)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	pad.add_child(v)

	# Title
	var title := Label.new()
	title.text = "HOW TO PLAY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.44))
	title.add_theme_color_override("font_outline_color", Color(0.035, 0.028, 0.04, 0.95))
	title.add_theme_constant_override("outline_size", 4)
	v.add_child(title)

	_add_divider(v)

	# Each section: a small header + two-column grid of key → action
	_add_howto_section(v, "Movement & Combat", [
		["WASD / Arrow Keys", "Move your character"],
		["Spacebar",           "Dodge roll (i-frames!)"],
		["Weapon auto-fires",  "Targets nearest enemy"],
	])

	_add_howto_section(v, "Spells", [
		["1 / 2 / 3",          "Cast equipped spells"],
		["Unlock spells",      "By levelling up in-run"],
		["Cooldown shown",     "In the hotbar bottom-left"],
	])

	_add_howto_section(v, "Waves & Shop", [
		["Survive the wave",   "Timer counts down top-left"],
		["Wave ends → Shop",   "Buy upgrades between waves"],
		["Gold from enemies",  "Spend in the shop to grow"],
	])

	_add_howto_section(v, "Progression", [
		["Kill enemies → XP", "Level up for upgrade choices"],
		["20 waves to win",   "Difficulty scales each wave"],
		["Go fast",           "The rift doesn't wait"],
	])

	_add_divider(v)

	var back := Button.new()
	back.text = "BACK"
	back.custom_minimum_size = Vector2(0, 46)
	_style_button(back, PATH_BTN_BLACK, false)
	back.pressed.connect(func(): root.visible = false)
	v.add_child(back)

	return root


## Adds a labelled section with rows of [key, description] pairs.
func _add_howto_section(parent: VBoxContainer, heading: String,
		rows: Array) -> void:
	var header := Label.new()
	header.text = heading
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", Color(0.72, 0.88, 1.0))
	header.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.04, 0.9))
	header.add_theme_constant_override("outline_size", 2)
	parent.add_child(header)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 4)
	parent.add_child(grid)

	for row in rows:
		# Key / binding label — highlighted in gold
		var key_lbl := Label.new()
		key_lbl.text = row[0]
		key_lbl.custom_minimum_size = Vector2(180, 0)
		key_lbl.add_theme_font_size_override("font_size", 13)
		key_lbl.add_theme_color_override("font_color", COLOR_PAPER)
		key_lbl.add_theme_color_override("font_outline_color", Color(0.02, 0.018, 0.02, 0.75))
		key_lbl.add_theme_constant_override("outline_size", 1)
		grid.add_child(key_lbl)

		# Description — dimmer text
		var desc_lbl := Label.new()
		desc_lbl.text = row[1]
		desc_lbl.add_theme_font_size_override("font_size", 13)
		desc_lbl.add_theme_color_override("font_color", Color(0.68, 0.72, 0.62))
		grid.add_child(desc_lbl)
