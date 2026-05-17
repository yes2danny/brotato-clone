extends CanvasLayer

# ─────────────────────────────────────────────
# WaveSummaryUI
# Shows a brief "Wave X Cleared!" recap screen between waves.
# Appears BEFORE the shop opens so the player can see how they did.
#
# How it fits into the flow:
#   Wave ends → WaveManager calls show_summary() on this node
#                → player clicks "ENTER THE SHOP"
#                   → this node emits summary_dismissed
#                      → WaveManager opens the shop
#
# Add this as a CanvasLayer child of Main.tscn, attach this script.
# No child nodes needed — everything is built in code below.
# ─────────────────────────────────────────────

# Emitted when the player clicks "ENTER THE SHOP".
# WaveManager listens for this before opening the shop.
signal summary_dismissed

# ── Asset paths (same pack as MainMenu / ShopUI) ──────────────────────────────
const PATH_PANEL_FRAME  := "res://assets/ui/pixel_ui/Panels/Black/GridPanelFrame.png"
const PATH_PANEL_INNER  := "res://assets/ui/pixel_ui/Panels/Black/GridPanel.png"
const PATH_GOLD_FRAME   := "res://assets/ui/pixel_ui/Panels/Gold/GridPanelFrame.png"
const PATH_TITLE_BANNER := "res://assets/ui/pixel_ui/Banners/Gold/TitleBanner.png"
const PATH_BTN_GOLD     := "res://assets/ui/pixel_ui/Buttons/Gold/ButtonA_%s.png"
const PATH_BTN_BLACK    := "res://assets/ui/pixel_ui/Buttons/Black/ButtonB_%s.png"
const PATH_DIVIDER      := "res://assets/ui/pixel_ui/Decorators/Gold/DividerD.png"
const PATH_GRID_BG      := "res://assets/ui/pixel_ui/Arcade/BackgroundGrid.png"
const PATCH             := 6

# ── Colors (matching MainMenu / ShopUI palette) ───────────────────────────────
const COLOR_GOLD      := Color(0.98, 0.86, 0.42)
const COLOR_PAPER     := Color(0.88, 0.78, 0.58)
const COLOR_TEXT_MAIN := Color(0.94, 0.95, 1.0)
const COLOR_DIM_BG    := Color(0.0, 0.0, 0.0, 0.82)

# ── Internal state ─────────────────────────────────────────────────────────────
var _pixel_ready  := false   # true if pixel_ui assets are present
var _main_panel   : Control = null   # the centered card we animate
var _overlay      : ColorRect = null # dark background dimmer
var _title_label  : Label = null
var _stat_kills   : Label = null
var _stat_gold    : Label = null
var _stat_next    : Label = null
var _continue_btn : Button = null


func _ready() -> void:
	# Register in a group so WaveManager can find us without a direct node path.
	add_to_group("wave_summary")
	visible = false   # hidden until a wave ends

	_pixel_ready = _check_assets()
	if not _pixel_ready:
		push_warning("WaveSummaryUI: pixel_ui assets missing — using fallback styles.")

	_build_ui()


# ── Public API ─────────────────────────────────────────────────────────────────

## Called by WaveManager right after a wave ends.
## wave_num   — the wave that just finished (before incrementing)
## kills      — enemies killed DURING this wave only
## gold_delta — gold gained during this wave (pick-ups minus spending; can be 0 if tracking not set up)
## next_wave  — the wave number coming up next
func show_summary(wave_num: int, kills: int, gold_delta: int, next_wave: int) -> void:
	# Populate the dynamic labels
	_title_label.text  = "WAVE %d  CLEARED!" % wave_num
	_stat_kills.text   = "%d  enemies defeated" % kills
	# Show a + sign for gold so it reads as a reward, not just a number
	_stat_gold.text    = "+%d  gold collected" % maxi(gold_delta, 0)
	_stat_next.text    = "Next threat: Wave %d" % next_wave

	visible = true
	_animate_in()


# ── Build UI ───────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	# ── Dark overlay fills the whole screen ──────────────────────────────────
	_overlay = ColorRect.new()
	_overlay.name = "DimOverlay"
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = COLOR_DIM_BG
	add_child(_overlay)

	# Optional: subtle grid texture behind the panel (same trick as ShopUI)
	if FileAccess.file_exists(PATH_GRID_BG):
		var grid := TextureRect.new()
		grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grid.set_anchors_preset(Control.PRESET_FULL_RECT)
		grid.texture = load(PATH_GRID_BG) as Texture2D
		grid.expand_mode   = TextureRect.EXPAND_IGNORE_SIZE
		grid.stretch_mode  = TextureRect.STRETCH_TILE
		grid.modulate      = Color(0.6, 0.8, 1.0, 0.04)
		add_child(grid)

	# ── Centered card container ───────────────────────────────────────────────
	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# The outer panel frame (Black pixel_ui panel, same as the shop outer frame)
	_main_panel = _panel(PATH_PANEL_FRAME, PATH_PANEL_INNER,
			Color(0.06, 0.055, 0.075, 0.97), Color(0.42, 0.32, 0.18))
	_main_panel.name = "SummaryCard"
	_main_panel.custom_minimum_size = Vector2(480, 0)
	center.add_child(_main_panel)

	# Inner padding container
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left",   28)
	pad.add_theme_constant_override("margin_right",  28)
	pad.add_theme_constant_override("margin_top",    24)
	pad.add_theme_constant_override("margin_bottom", 24)
	_main_panel.add_child(pad)

	# Vertical stack: title → divider → stat rows → divider → button
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	pad.add_child(v)

	# ── Title banner ─────────────────────────────────────────────────────────
	v.add_child(_build_title_banner())

	_add_divider(v)

	# ── Stat rows ─────────────────────────────────────────────────────────────
	var stats_panel := _build_stats_panel()
	v.add_child(stats_panel)

	_add_divider(v)

	# ── Continue button ───────────────────────────────────────────────────────
	_continue_btn = Button.new()
	_continue_btn.name = "ContinueBtn"
	_continue_btn.text = "ENTER THE SHOP"
	_continue_btn.custom_minimum_size = Vector2(0, 52)
	_style_button(_continue_btn, PATH_BTN_GOLD, true)
	_continue_btn.pressed.connect(_on_continue_pressed)
	v.add_child(_continue_btn)


func _build_title_banner() -> Control:
	# Outer panel using the gold title banner texture (same as MainMenu header)
	var wrap := PanelContainer.new()
	wrap.name = "TitleWrap"
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.custom_minimum_size   = Vector2(0, 82)
	if _pixel_ready and FileAccess.file_exists(PATH_TITLE_BANNER):
		var sb := _stylebox_texture(PATH_TITLE_BANNER, 12, 12, 12, 12)
		sb.content_margin_left   = 16
		sb.content_margin_right  = 16
		sb.content_margin_top    = 10
		sb.content_margin_bottom = 10
		wrap.add_theme_stylebox_override("panel", sb)
	else:
		wrap.add_theme_stylebox_override("panel",
				_flat_panel(Color(0.26, 0.18, 0.08, 0.96), Color(0.8, 0.58, 0.22)))

	var center := CenterContainer.new()
	wrap.add_child(center)

	# _title_label is updated each time show_summary() is called
	_title_label = Label.new()
	_title_label.text = "WAVE ? CLEARED!"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 32)
	_title_label.add_theme_color_override("font_color", Color(0.14, 0.08, 0.03))
	_title_label.add_theme_color_override("font_outline_color", Color(1.0, 0.92, 0.55, 0.7))
	_title_label.add_theme_constant_override("outline_size", 5)
	center.add_child(_title_label)

	return wrap


func _build_stats_panel() -> Control:
	# Gold-framed inner panel holds the three stat rows
	var outer := PanelContainer.new()
	outer.name = "StatsPanel"
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _pixel_ready and FileAccess.file_exists(PATH_GOLD_FRAME):
		outer.add_theme_stylebox_override("panel",
				_stylebox_texture(PATH_GOLD_FRAME, PATCH, PATCH, PATCH, PATCH))
	else:
		outer.add_theme_stylebox_override("panel",
				_flat_panel(Color(0.08, 0.07, 0.045, 0.95), Color(0.84, 0.61, 0.24)))

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left",   20)
	pad.add_theme_constant_override("margin_right",  20)
	pad.add_theme_constant_override("margin_top",    16)
	pad.add_theme_constant_override("margin_bottom", 16)
	outer.add_child(pad)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	pad.add_child(v)

	# Each stat row: icon chip on the left, value label on the right
	_stat_kills = _build_stat_row(v, "⚔",  "0  enemies defeated", Color(0.95, 0.45, 0.35))
	_stat_gold  = _build_stat_row(v, "🪙", "+0  gold collected",  COLOR_GOLD)
	_stat_next  = _build_stat_row(v, "▶",  "Next threat: Wave 2",  Color(0.72, 0.88, 1.0))

	return outer


## Adds one stat row to `parent` and returns the value Label so we can update it later.
func _build_stat_row(parent: VBoxContainer, icon: String, initial_text: String,
		value_color: Color) -> Label:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)

	# Icon badge — small dark pill with a colored icon
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(40, 40)
	badge.add_theme_stylebox_override("panel",
			_flat_panel(Color(0.05, 0.05, 0.06, 0.9), Color(0.28, 0.28, 0.36)))
	row.add_child(badge)

	var icon_lbl := Label.new()
	icon_lbl.text = icon
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 18)
	badge.add_child(icon_lbl)

	# Value label — grows to fill the rest of the row
	var value := Label.new()
	value.text = initial_text
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
	value.add_theme_font_size_override("font_size", 18)
	value.add_theme_color_override("font_color", value_color)
	value.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.025, 0.9))
	value.add_theme_constant_override("outline_size", 2)
	row.add_child(value)

	return value   # caller stores this reference to update text later


# ── Animation ─────────────────────────────────────────────────────────────────

func _animate_in() -> void:
	# Start from invisible + slightly scaled-down, then pop to full size.
	# Matches the ShopUI open animation feel.
	_main_panel.scale   = Vector2(0.92, 0.92)
	_main_panel.modulate = Color(1, 1, 1, 0.0)
	_overlay.modulate    = Color(1, 1, 1, 0.0)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)

	# Fade in overlay
	tw.tween_property(_overlay, "modulate", Color(1, 1, 1, 1.0), 0.22) \
			.set_trans(Tween.TRANS_QUAD)

	# Scale + fade in the panel
	tw.tween_property(_main_panel, "scale",   Vector2(1.0, 1.0), 0.30)
	tw.tween_property(_main_panel, "modulate", Color(1, 1, 1, 1.0), 0.25)

	# Grab focus on the button after animation so keyboard/gamepad works
	tw.chain().tween_callback(_continue_btn.grab_focus)


func _animate_out_then_dismiss() -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_QUAD)

	tw.tween_property(_main_panel, "scale",    Vector2(0.94, 0.94), 0.18)
	tw.tween_property(_main_panel, "modulate", Color(1, 1, 1, 0.0), 0.18)
	tw.tween_property(_overlay,    "modulate", Color(1, 1, 1, 0.0), 0.20)

	# Hide the whole CanvasLayer once the fade is done, then signal WaveManager
	tw.chain().tween_callback(_emit_dismissed)


func _emit_dismissed() -> void:
	visible = false
	emit_signal("summary_dismissed")


# ── Button callback ────────────────────────────────────────────────────────────

func _on_continue_pressed() -> void:
	_continue_btn.disabled = true    # prevent double-clicks during fade
	_animate_out_then_dismiss()


# ── Helper: UI construction utilities ─────────────────────────────────────────
# These are identical to the helpers in MainMenu.gd / ShopUI.gd so the visual
# style stays 100% consistent across all screens.

func _check_assets() -> bool:
	var paths := [PATH_PANEL_FRAME, PATH_PANEL_INNER,
				  PATH_GOLD_FRAME, PATH_TITLE_BANNER,
				  PATH_BTN_GOLD % "Unpressed"]
	for p in paths:
		if not FileAccess.file_exists(p):
			return false
	return true


func _panel(frame: String, inner: String, fallback_bg: Color,
		fallback_border: Color) -> PanelContainer:
	var p := PanelContainer.new()
	if _pixel_ready and FileAccess.file_exists(frame):
		p.add_theme_stylebox_override("panel",
				_stylebox_texture(frame, PATCH, PATCH, PATCH, PATCH))
	elif _pixel_ready and FileAccess.file_exists(inner):
		p.add_theme_stylebox_override("panel",
				_stylebox_texture(inner, PATCH, PATCH, PATCH, PATCH))
	else:
		p.add_theme_stylebox_override("panel", _flat_panel(fallback_bg, fallback_border))
	return p


func _stylebox_texture(path: String, l: int, t: int, r: int, b: int) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = load(path) as Texture2D
	s.texture_margin_left   = l
	s.texture_margin_top    = t
	s.texture_margin_right  = r
	s.texture_margin_bottom = b
	return s


func _flat_panel(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color     = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(8)
	s.content_margin_left   = 12
	s.content_margin_right  = 12
	s.content_margin_top    = 10
	s.content_margin_bottom = 10
	return s


func _add_divider(parent: Control) -> void:
	if FileAccess.file_exists(PATH_DIVIDER):
		var d := TextureRect.new()
		d.texture      = load(PATH_DIVIDER) as Texture2D
		d.custom_minimum_size = Vector2(0, 16)
		d.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		d.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		d.modulate     = Color(1.0, 0.86, 0.38, 0.85)
		parent.add_child(d)
	else:
		var line := ColorRect.new()
		line.custom_minimum_size = Vector2(0, 2)
		line.color = Color(0.72, 0.54, 0.22, 0.8)
		parent.add_child(line)


func _style_button(button: Button, path_template: String, primary: bool) -> void:
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 16 if primary else 14)

	if _pixel_ready and FileAccess.file_exists(path_template % "Unpressed"):
		var normal  := _button_box(path_template % "Unpressed")
		var hover   := _button_box(path_template % "Highlighted")
		var pressed := _button_box(path_template % "Pressed")
		button.add_theme_stylebox_override("normal",  normal)
		button.add_theme_stylebox_override("hover",   hover)
		button.add_theme_stylebox_override("pressed", pressed)
		button.add_theme_stylebox_override("focus",   hover)
	else:
		var n := _flat_panel(Color(0.28, 0.2, 0.12, 0.95), Color(0.84, 0.62, 0.26))
		var h := n.duplicate() as StyleBoxFlat
		h.bg_color = Color(0.36, 0.27, 0.16, 0.98)
		button.add_theme_stylebox_override("normal", n)
		button.add_theme_stylebox_override("hover",  h)

	if primary:
		button.add_theme_color_override("font_color",         Color(0.13, 0.075, 0.035))
		button.add_theme_color_override("font_outline_color", Color(1.0, 0.88, 0.45, 0.55))
	else:
		button.add_theme_color_override("font_color",         Color(0.86, 0.78, 0.62))
		button.add_theme_color_override("font_outline_color", Color(0.02, 0.018, 0.02, 0.85))
	button.add_theme_constant_override("outline_size", 2)


func _button_box(path: String) -> StyleBoxTexture:
	var s := _stylebox_texture(path, 11, 6, 11, 6)
	s.content_margin_left   = 12
	s.content_margin_right  = 12
	s.content_margin_top    = 7
	s.content_margin_bottom = 7
	return s
