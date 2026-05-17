extends CanvasLayer

# ─────────────────────────────────────────────
# ShopUI — Between-wave merchant UI (4 offers). Title + gold centered; rotating quips.
#
# Pixel UI & HUD — **Blue** outer frame + buttons, **Black** grid slots for contrast:
#   Panels/Blue/GridPanelFrame.png, GridPanel.png   ← outer shell uses blue theme
#   Grid/Black/GridSlot.png, GridSlotInactive.png   ← card slots stay black (Blue has no GridSlot)
#   Buttons/Blue/ButtonA_* / ButtonB_*              ← all buttons use blue variant
#
# Fits the panel to the window by setting **custom_minimum_size** only (capped to
# ~92% × 88% of viewport). Avoids custom_maximum_size — not available on all Control types.
# ShopManager.shop_slot_count should stay 4 for this layout (extras are ignored).
# ─────────────────────────────────────────────

const _PIXEL_PATCH_16 := 5

# ── Blue outer panels + buttons ──────────────────────────────────────────────
const _PIXEL_FRAME := "res://assets/ui/pixel_ui/Panels/Blue/GridPanelFrame.png"
const _PIXEL_PANEL_GRID := "res://assets/ui/pixel_ui/Panels/Blue/GridPanel.png"
# Grid/Blue only has selectors, not slot sprites — keep Black for the item cards
const _PIXEL_GRID_SLOT := "res://assets/ui/pixel_ui/Grid/Black/GridSlot.png"
const _PIXEL_GRID_SLOT_INACTIVE := "res://assets/ui/pixel_ui/Grid/Black/GridSlotInactive.png"
const _PIXEL_BTN_A := "res://assets/ui/pixel_ui/Buttons/Blue/ButtonA_%s.png"
const _PIXEL_BTN_B := "res://assets/ui/pixel_ui/Buttons/Blue/ButtonB_%s.png"
const _MEDIEVAL_PROP_ATLAS := "res://assets/ui/medieval_ui_paid/atlas.png"
const _QUIP_BOX_ATLAS := "res://assets/ui/tiny_rpg_mana_soul_gui/button_b_atlas.png"

## Turn off to use flat programmer-art panels (no pack files required).
@export var use_pixel_shop_ui: bool = true

## Minimum height for each offer card (width shares the row evenly).
@export var card_min_height: float = 220.0

const _SHOP_TITLE := "Rift Resupply"

## Rotates each time the shop opens (see _pick_coin_quip).
const _COIN_QUIPS: Array[String] = [
	"Coin's not buying anything sitting there. Spend it before something kills you for it.",
	"Cyclops doesn't care how broke you feel.",
	"Wave's almost here. Your gun won't ask what you saved.",
	"Skip the rifle this time. Tell me how that goes.",
	"You can save, or you can kill the big one. Pick.",
	"Miniboss shows up and everyone's shocked. Every time. Buy a stat.",
	"Spread now. Count later.",
	"Plenty of rich corpses out there. Boss didn't care about their gold either.",
	"Goblins come in groups. So should your bullets.",
	"Saving for a rainy day? Look up.",
	"Big gold number, small build. Not a flex.",
	"If your build needs help, help it.",
	"Rifle, SMG, revolver — I don't care what you carry. Just carry more of it.",
	"One more passive before the boss. Sure. That'll do it.",
	"Phase two's a bad time to find out you're broke.",
	"Red goblin and blue goblin agree — you hit soft.",
	"Dead things drop gold. Bought things make more dead things.",
	"That gun's barely a gun. I can fix that.",
	"Reload's slow. Gear isn't.",
	"Buy something nice. Wave isn't waiting.",
	"Rich corpses are still corpses.",
	"I don't make the waves. I just sell to the people who survive them.",
	"Hoarding gold is regret you haven't opened yet.",
	"Last run's gone. This one's still walking.",
	"Big eye. Big club. Small price tag. You do the math.",
	"Enemies don't read patch notes. They read what you're holding.",
	"One more item and you're set. You said that last wave.",
	"Mag dumps land better with damage behind them.",
	"Half a boss bar in, everyone wants to shop. Beat them here.",
	"Lot of small goblins out there. One bigger gun usually fixes it.",
	"Cyclops has one eye. You've got slots. Use them.",
	"Better gun. The room doesn't grade on effort.",
	"Miniboss is loud. You should be louder.",
	"Spray. Pray. Pay me.",
	"Clock's not slowing down. Neither am I.",
	"Waiting on the perfect roll. They're not waiting on you.",
	"Gold won't take a hit. Armor will.",
	"Goblins don't care what color they are. They care that you're squishy.",
	"Boss loot's a coin flip. My shelf isn't.",
	"You don't need a plan. You need more damage.",
	"Spend now. Cry less later.",
	"You call it balanced. The arena calls it lunch.",
	"Hot rifle, cold wallet. Let's even those out.",
	"Miniboss winds up. So does my pricing. Move.",
]

var _shop_manager: Node = null
var _pixel_ui_ready: bool = false
var _last_coin_quip_idx: int = -1

var _dim: ColorRect = null
var _toast: Label = null
var _gold_label: Label = null
var _wave_label: Label = null
var _tagline: Label = null
var _item_row: HBoxContainer = null
var _reroll_btn: Button = null
var _continue_btn: Button = null
var _shop_shell: PanelContainer = null
var _flat_panel: PanelContainer = null
var _content_tabs: TabContainer = null
var _shop_tab: Control = null
var _spell_tree_ui: Control = null
var _inventory_tab: Control = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 24
	visible = false
	add_to_group("shop_ui")
	_pixel_ui_ready = (
		use_pixel_shop_ui
		and FileAccess.file_exists(_PIXEL_FRAME)
		and FileAccess.file_exists(_PIXEL_PANEL_GRID)
		and FileAccess.file_exists(_PIXEL_GRID_SLOT)
		and FileAccess.file_exists(_PIXEL_GRID_SLOT_INACTIVE)
		and FileAccess.file_exists(_PIXEL_BTN_A % "Unpressed")
		and FileAccess.file_exists(_PIXEL_BTN_B % "Unpressed")
	)
	if use_pixel_shop_ui and not _pixel_ui_ready:
		push_warning(
			"ShopUI: Black pixel UI missing under res://assets/ui/pixel_ui/ "
			+ "(Panels/Black, Grid/Black, Buttons/Black). Falling back to flat UI."
		)
	_build_ui()
	get_viewport().size_changed.connect(_apply_viewport_to_shop)

	_shop_manager = get_tree().get_first_node_in_group("shop_manager")
	if _shop_manager:
		_shop_manager.shop_opened.connect(_on_shop_opened)
		_shop_manager.shop_rerolled.connect(_on_shop_rerolled)
		_shop_manager.shop_closed.connect(_on_shop_closed)
		_shop_manager.gold_changed.connect(_on_gold_changed)
		_shop_manager.rerolls_changed.connect(_on_rerolls_changed)
		_on_gold_changed(_shop_manager.player_gold)
		_on_rerolls_changed(_shop_manager.free_rerolls)


func _shop_slot_count() -> int:
	if _shop_manager == null:
		return 4
	var n: int = int(_shop_manager.shop_slot_count)
	return clampi(n, 1, 8)


func _apply_viewport_to_shop() -> void:
	var vp := get_viewport().get_visible_rect().size
	var margin_x := 32.0
	var margin_y := 40.0
	var avail_w := maxf(240.0, vp.x - margin_x)
	var avail_h := maxf(220.0, vp.y - margin_y)
	var showing_spellbook := _content_tabs != null and _content_tabs.current_tab == 1

	# Let the between-wave modal breathe with the actual window size.
	# Shop stays around half-screen; Spellbook gets a much larger canvas because
	# the branching layout genuinely needs it.
	var desired_w := vp.x * (0.78 if showing_spellbook else 0.60)
	var desired_h := vp.y * (0.82 if showing_spellbook else 0.52)
	var min_w := 1180.0 if showing_spellbook else 900.0
	var min_h := 760.0 if showing_spellbook else 500.0
	var panel_w := minf(maxf(desired_w, min_w), avail_w)
	var panel_h := minf(maxf(desired_h, min_h), avail_h)
	var sz := Vector2(panel_w, panel_h)
	if _shop_shell:
		_shop_shell.custom_minimum_size = sz
	if _flat_panel:
		_flat_panel.custom_minimum_size = sz
	if _item_row:
		_item_row.custom_minimum_size = Vector2(maxf(120.0, panel_w - 72.0), 0.0)


func _build_ui() -> void:
	_dim = ColorRect.new()
	_dim.name = "ShopDim"
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0.02, 0.02, 0.05, 0.9)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)

	var root := MarginContainer.new()
	root.name = "ShopRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 16)
	root.add_theme_constant_override("margin_right", 16)
	root.add_theme_constant_override("margin_top", 20)
	root.add_theme_constant_override("margin_bottom", 20)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var panel: PanelContainer = null
	if _pixel_ui_ready:
		var shell := PanelContainer.new()
		shell.name = "ShopShell"
		_shop_shell = shell
		var frame_sb := _ninepatch_from_path(_PIXEL_FRAME, _PIXEL_PATCH_16, _PIXEL_PATCH_16, _PIXEL_PATCH_16, _PIXEL_PATCH_16)
		frame_sb.content_margin_left = 12.0
		frame_sb.content_margin_right = 12.0
		frame_sb.content_margin_top = 12.0
		frame_sb.content_margin_bottom = 12.0
		shell.add_theme_stylebox_override("panel", frame_sb)
		center.add_child(shell)

		var pad := MarginContainer.new()
		pad.add_theme_constant_override("margin_left", 8)
		pad.add_theme_constant_override("margin_right", 8)
		pad.add_theme_constant_override("margin_top", 8)
		pad.add_theme_constant_override("margin_bottom", 8)
		shell.add_child(pad)

		panel = PanelContainer.new()
		panel.name = "ShopPanel"
		var grid_sb := _ninepatch_from_path(_PIXEL_PANEL_GRID, _PIXEL_PATCH_16, _PIXEL_PATCH_16, _PIXEL_PATCH_16, _PIXEL_PATCH_16)
		grid_sb.content_margin_left = 16.0
		grid_sb.content_margin_right = 16.0
		grid_sb.content_margin_top = 14.0
		grid_sb.content_margin_bottom = 14.0
		panel.add_theme_stylebox_override("panel", grid_sb)
		pad.add_child(panel)
	else:
		_shop_shell = null
		panel = PanelContainer.new()
		panel.name = "ShopPanel"
		_flat_panel = panel
		var flat := StyleBoxFlat.new()
		flat.bg_color = Color(0.12, 0.12, 0.16, 0.98)
		flat.border_color = Color(0.45, 0.48, 0.58, 0.85)
		flat.set_border_width_all(2)
		flat.set_corner_radius_all(10)
		flat.content_margin_left = 16.0
		flat.content_margin_right = 16.0
		flat.content_margin_top = 14.0
		flat.content_margin_bottom = 14.0
		panel.add_theme_stylebox_override("panel", flat)
		center.add_child(panel)

	_content_tabs = TabContainer.new()
	_content_tabs.tabs_visible = true
	_content_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_tabs.tab_changed.connect(_on_tab_changed)
	panel.add_child(_content_tabs)

	_shop_tab = VBoxContainer.new()
	_shop_tab.name = "Shop"
	_shop_tab.add_theme_constant_override("separation", 10)
	_content_tabs.add_child(_shop_tab)

	var spell_tab := Control.new()
	spell_tab.name = "Spellbook"
	_content_tabs.add_child(spell_tab)

	var SpellTreeUIScene := preload("res://scenes/ui/menus/SpellTreeUI.tscn")
	_spell_tree_ui = SpellTreeUIScene.instantiate()
	_spell_tree_ui.name = "SpellTreeUI"
	_spell_tree_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	spell_tab.add_child(_spell_tree_ui)

	_inventory_tab = VBoxContainer.new()
	_inventory_tab.name = "Inventory"
	_inventory_tab.alignment = BoxContainer.ALIGNMENT_CENTER
	_inventory_tab.add_theme_constant_override("separation", 10)
	_content_tabs.add_child(_inventory_tab)

	var inv_title := Label.new()
	inv_title.text = "Inventory"
	inv_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inv_title.add_theme_font_size_override("font_size", 24)
	inv_title.add_theme_color_override("font_color", Color(0.94, 0.95, 1.0))
	_inventory_tab.add_child(inv_title)

	var inv_body := Label.new()
	inv_body.text = "Inventory system coming later.\nThis tab is reserved for your current build, equipped items, and future loadout details."
	inv_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inv_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inv_body.custom_minimum_size = Vector2(420, 0)
	inv_body.add_theme_font_size_override("font_size", 14)
	inv_body.add_theme_color_override("font_color", Color(0.72, 0.76, 0.86))
	_inventory_tab.add_child(inv_body)

	var outer := _shop_tab as VBoxContainer

	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 14)
	outer.add_child(title_row)

	var left_lantern := _shop_prop(_MEDIEVAL_PROP_ATLAS, Rect2(0, 0, 32, 32), Vector2(24, 24))
	title_row.add_child(left_lantern)

	var title := Label.new()
	title.name = "ShopTitle"
	title.text = _SHOP_TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.92, 0.94, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.1, 0.75))
	title.add_theme_constant_override("outline_size", 3)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.custom_minimum_size = Vector2(220, 0)
	title.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	title_row.add_child(title)

	var right_lantern := _shop_prop(_MEDIEVAL_PROP_ATLAS, Rect2(0, 0, 32, 32), Vector2(24, 24))
	title_row.add_child(right_lantern)

	var header_row := HBoxContainer.new()
	header_row.alignment = BoxContainer.ALIGNMENT_CENTER
	header_row.add_theme_constant_override("separation", 16)
	outer.add_child(header_row)

	_wave_label = Label.new()
	_wave_label.name = "WaveLabel"
	_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_label.add_theme_font_size_override("font_size", 18)
	_wave_label.add_theme_color_override("font_color", Color(0.72, 0.76, 0.88))
	_wave_label.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.1, 0.7))
	_wave_label.add_theme_constant_override("outline_size", 2)
	header_row.add_child(_wave_label)

	_gold_label = Label.new()
	_gold_label.name = "GoldLabel"
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_label.add_theme_font_size_override("font_size", 20)
	_gold_label.add_theme_color_override("font_color", Color(0.98, 0.86, 0.42))
	_gold_label.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.02, 0.75))
	_gold_label.add_theme_constant_override("outline_size", 3)
	header_row.add_child(_gold_label)

	_item_row = HBoxContainer.new()
	_item_row.name = "ItemRow"
	_item_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_item_row.add_theme_constant_override("separation", 18)
	_item_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(_item_row)

	var bottom := CenterContainer.new()
	bottom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.custom_minimum_size = Vector2(0, 44)
	outer.add_child(bottom)

	var bottom_row := HBoxContainer.new()
	bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_row.add_theme_constant_override("separation", 10)
	bottom.add_child(bottom_row)

	_reroll_btn = Button.new()
	_reroll_btn.name = "RerollButton"
	_reroll_btn.custom_minimum_size = Vector2(140, 36)
	if _pixel_ui_ready:
		_style_pixel_muted_button(_reroll_btn)
	else:
		_style_muted_button(_reroll_btn)
	_reroll_btn.pressed.connect(_on_reroll_pressed)
	bottom_row.add_child(_reroll_btn)

	_continue_btn = Button.new()
	_continue_btn.name = "ContinueButton"
	_continue_btn.text = "Continue"
	_continue_btn.custom_minimum_size = Vector2(140, 36)
	if _pixel_ui_ready:
		_style_pixel_primary_button(_continue_btn)
	else:
		_style_primary_button(_continue_btn)
	_continue_btn.pressed.connect(_on_continue_pressed)
	bottom_row.add_child(_continue_btn)

	var quip_center := CenterContainer.new()
	quip_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(quip_center)

	var quip_panel := PanelContainer.new()
	quip_panel.name = "ShopQuipPanel"
	quip_panel.custom_minimum_size = Vector2(560, 40)
	# Use a flat stylebox so the quip banner scales cleanly without stretching
	# a tiny sprite across hundreds of pixels. Dark blue tint matches the new theme.
	var quip_style := StyleBoxFlat.new()
	quip_style.bg_color = Color(0.10, 0.14, 0.28, 0.88)   # deep navy, slightly transparent
	quip_style.border_color = Color(0.32, 0.52, 0.82, 0.65) # soft blue border
	quip_style.set_border_width_all(1)
	quip_style.set_corner_radius_all(6)
	quip_style.content_margin_left = 14
	quip_style.content_margin_right = 14
	quip_style.content_margin_top = 7
	quip_style.content_margin_bottom = 7
	quip_panel.add_theme_stylebox_override("panel", quip_style)
	quip_center.add_child(quip_panel)

	_tagline = Label.new()
	_tagline.name = "ShopTagline"
	_tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tagline.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tagline.max_lines_visible = 2
	_tagline.add_theme_font_size_override("font_size", 11)
	_tagline.add_theme_color_override("font_color", Color(0.78, 0.86, 1.0))  # slightly brighter on navy
	_tagline.add_theme_constant_override("line_spacing", -1)
	_tagline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tagline.custom_minimum_size = Vector2(520, 0)
	quip_panel.add_child(_tagline)

	_toast = Label.new()
	_toast.name = "Toast"
	_toast.visible = false
	_toast.add_theme_font_size_override("font_size", 15)
	_toast.add_theme_color_override("font_color", Color(0.95, 0.9, 0.82))
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.position = Vector2(-200, -72)
	_toast.custom_minimum_size = Vector2(400, 32)
	add_child(_toast)

	call_deferred("_apply_viewport_to_shop")


func _ninepatch_from_path(path: String, ml: int, mt: int, mr: int, mb: int) -> StyleBoxTexture:
	var tex: Texture2D = load(path) as Texture2D
	if tex == null:
		push_error("ShopUI: missing or invalid texture at %s" % path)
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = ml
	sb.texture_margin_top = mt
	sb.texture_margin_right = mr
	sb.texture_margin_bottom = mb
	sb.set_expand_margin_all(0)
	return sb


func _slot_stylebox(use_active_slot: bool) -> StyleBoxTexture:
	var path := _PIXEL_GRID_SLOT if use_active_slot else _PIXEL_GRID_SLOT_INACTIVE
	return _ninepatch_from_path(path, _PIXEL_PATCH_16, _PIXEL_PATCH_16, _PIXEL_PATCH_16, _PIXEL_PATCH_16)


func _shop_prop(atlas_path: String, region: Rect2, display_size: Vector2) -> TextureRect:
	var texture := TextureRect.new()
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture.custom_minimum_size = display_size
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if FileAccess.file_exists(atlas_path):
		var atlas := AtlasTexture.new()
		atlas.atlas = load(atlas_path) as Texture2D
		atlas.region = region
		texture.texture = atlas
	return texture


func _stylebox_from_atlas(
	atlas_path: String,
	region: Rect2,
	left: int,
	top: int,
	right: int,
	bottom: int
) -> StyleBoxTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = load(atlas_path) as Texture2D
	atlas.region = region
	var style := StyleBoxTexture.new()
	style.texture = atlas
	style.texture_margin_left = left
	style.texture_margin_top = top
	style.texture_margin_right = right
	style.texture_margin_bottom = bottom
	style.content_margin_left = 10
	style.content_margin_top = 6
	style.content_margin_right = 10
	style.content_margin_bottom = 6
	return style


func _style_primary_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.28, 0.42, 0.62)
	normal.set_corner_radius_all(8)
	normal.content_margin_left = 14.0
	normal.content_margin_right = 14.0
	normal.content_margin_top = 8.0
	normal.content_margin_bottom = 8.0
	btn.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = Color(0.34, 0.5, 0.72)
	btn.add_theme_stylebox_override("hover", hover)


func _style_pixel_primary_button(btn: Button) -> void:
	var ml := 11
	var mt := 6
	var mr := 11
	var mb := 6
	var n := _ninepatch_from_path(_PIXEL_BTN_A % "Unpressed", ml, mt, mr, mb)
	var h := _ninepatch_from_path(_PIXEL_BTN_A % "Highlighted", ml, mt, mr, mb)
	var p := _ninepatch_from_path(_PIXEL_BTN_A % "Pressed", ml, mt, mr, mb)
	for s in [n, h, p]:
		s.content_margin_left = 12.0
		s.content_margin_right = 12.0
		s.content_margin_top = 6.0
		s.content_margin_bottom = 6.0
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_stylebox_override("focus", h)
	var d := n.duplicate()
	d.modulate_color = Color(1, 1, 1, 0.55)
	btn.add_theme_stylebox_override("disabled", d)


func _style_pixel_muted_button(btn: Button) -> void:
	var ml := 10
	var mt := 5
	var mr := 10
	var mb := 5
	var n := _ninepatch_from_path(_PIXEL_BTN_B % "Unpressed", ml, mt, mr, mb)
	var h := _ninepatch_from_path(_PIXEL_BTN_B % "Highlighted", ml, mt, mr, mb)
	var p := _ninepatch_from_path(_PIXEL_BTN_B % "Pressed", ml, mt, mr, mb)
	for s in [n, h, p]:
		s.content_margin_left = 8.0
		s.content_margin_right = 8.0
		s.content_margin_top = 5.0
		s.content_margin_bottom = 5.0
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_stylebox_override("focus", h)
	var d := n.duplicate()
	d.modulate_color = Color(1, 1, 1, 0.55)
	btn.add_theme_stylebox_override("disabled", d)


func _style_muted_button(btn: Button) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.22, 0.24, 0.3)
	n.set_corner_radius_all(6)
	n.content_margin_top = 5
	n.content_margin_bottom = 5
	btn.add_theme_stylebox_override("normal", n)
	var h := n.duplicate()
	h.bg_color = Color(0.3, 0.34, 0.44)
	btn.add_theme_stylebox_override("hover", h)


func _pick_coin_quip() -> String:
	var n: int = _COIN_QUIPS.size()
	if n == 0:
		return ""
	var idx := randi() % n
	if n > 1:
		var guard := 0
		while idx == _last_coin_quip_idx and guard < 12:
			idx = randi() % n
			guard += 1
	_last_coin_quip_idx = idx
	return _COIN_QUIPS[idx]


func _on_shop_opened(offerings: Array) -> void:
	_apply_viewport_to_shop()
	if _tagline:
		_tagline.text = _pick_coin_quip()
	if _wave_label and _shop_manager:
		_wave_label.text = "Wave %d" % (GameManager.waves_completed + 1)
	visible = true
	if _content_tabs:
		_content_tabs.current_tab = 0
	if _spell_tree_ui and _spell_tree_ui.has_method("close_tree"):
		_spell_tree_ui.close_tree()
	_rebuild_row(offerings)
	if _shop_manager:
		_on_rerolls_changed(_shop_manager.free_rerolls)
	_animate_shop_open()


func _on_tab_changed(_tab_index: int) -> void:
	_apply_viewport_to_shop()
	if _spell_tree_ui == null:
		return
	var showing_spellbook := _content_tabs != null and _content_tabs.current_tab == 1
	if showing_spellbook and _spell_tree_ui.has_method("open_tree"):
		_spell_tree_ui.open_tree()
	elif not showing_spellbook and _spell_tree_ui.has_method("close_tree"):
		_spell_tree_ui.close_tree()


func _on_shop_rerolled(offerings: Array) -> void:
	_rebuild_row(offerings)
	_show_toast("Shelf rerolled")


func _on_shop_closed() -> void:
	if _spell_tree_ui and _spell_tree_ui.has_method("close_tree"):
		_spell_tree_ui.close_tree()
	visible = false
	_clear_row()


func _on_gold_changed(amount: int) -> void:
	if _gold_label:
		_gold_label.text = "🪙 %d" % amount


func _on_rerolls_changed(amount: int) -> void:
	if _reroll_btn == null:
		return
	_reroll_btn.text = "Reroll (%d)" % amount
	_reroll_btn.disabled = amount <= 0


func _on_reroll_pressed() -> void:
	if not _shop_manager:
		return
	if not _shop_manager.try_reroll():
		_show_toast("No free rerolls")
		return

	# Play the dice sequence: grab → shake → roll
	# Delays are in seconds — tweak these if the timing feels off
	AudioManager.play_sequence(
		["shop/reroll/dice_grab", "shop/reroll/dice_shake_3", "shop/reroll/dice_roll_3"],
		[0.0, 0.2, 0.55]
	)


func _on_continue_pressed() -> void:
	if _shop_manager:
		_shop_manager.close_shop()


func _animate_shop_open() -> void:
	if _dim:
		_dim.modulate.a = 0.0
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_dim, "modulate:a", 0.9, 0.25).from(0.0)
	var panel := _shop_shell if _shop_shell else _flat_panel
	if panel:
		panel.pivot_offset = panel.size * 0.5
		panel.scale = Vector2(0.92, 0.92)
		panel.modulate.a = 0.0
		var tw := create_tween().set_parallel(true)
		tw.tween_property(panel, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(panel, "modulate:a", 1.0, 0.2)

func _clear_row() -> void:
	for c in _item_row.get_children():
		c.queue_free()


func _normalized_offerings(offerings: Array) -> Array:
	var cap := _shop_slot_count()
	var out: Array = []
	for o in offerings:
		if o is ShopItem:
			out.append(o)
		if out.size() >= cap:
			break
	while out.size() < cap:
		out.append(null)
	return out


func _rebuild_row(offerings: Array) -> void:
	_clear_row()
	var slots := _normalized_offerings(offerings)
	for i in slots.size():
		var cell := _make_slot_cell(slots[i])
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.size_flags_stretch_ratio = 1.0
		_item_row.add_child(cell)


func _make_slot_cell(offer: Variant) -> Control:
	var wrap := MarginContainer.new()
	wrap.add_theme_constant_override("margin_left", 1)
	wrap.add_theme_constant_override("margin_right", 1)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, maxf(card_min_height, 230.0))
	card.mouse_filter = Control.MOUSE_FILTER_STOP

	if offer == null:
		var sb_in := _slot_stylebox(false)
		sb_in.content_margin_left = 8.0
		sb_in.content_margin_right = 8.0
		sb_in.content_margin_top = 8.0
		sb_in.content_margin_bottom = 8.0
		card.add_theme_stylebox_override("panel", sb_in)
		wrap.add_child(card)
		var empty := Label.new()
		empty.text = "—"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.set_anchors_preset(Control.PRESET_FULL_RECT)
		empty.add_theme_font_size_override("font_size", 20)
		empty.add_theme_color_override("font_color", Color(0.5, 0.54, 0.62, 0.75))
		card.add_child(empty)
		return wrap

	var offer_item: ShopItem = offer
	var use_active := not offer_item.is_purchased
	if offer_item.is_purchased:
		card.modulate = Color(1, 1, 1, 0.45)
	var sb := _slot_stylebox(use_active)
	sb.content_margin_left = 8.0
	sb.content_margin_right = 8.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	card.add_theme_stylebox_override("panel", sb)
	wrap.add_child(card)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(v)

	var rarity_bar := ColorRect.new()
	rarity_bar.color = _rarity_color(offer_item.rarity)
	rarity_bar.custom_minimum_size = Vector2(0, 8)
	rarity_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(rarity_bar)

	var top := VBoxContainer.new()
	top.add_theme_constant_override("separation", 5)
	top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(top)

	var icon_area := CenterContainer.new()
	icon_area.custom_minimum_size = Vector2(72, 72)
	if offer_item.display_icon:
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(64, 64)
		icon.texture = offer_item.display_icon
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_area.add_child(icon)
	else:
		var ph := Label.new()
		ph.text = "?"
		ph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ph.custom_minimum_size = Vector2(52, 52)
		ph.add_theme_font_size_override("font_size", 26)
		ph.add_theme_color_override("font_color", Color(0.55, 0.58, 0.68))
		icon_area.add_child(ph)
	top.add_child(icon_area)

	var name_row := HBoxContainer.new()
	name_row.alignment = BoxContainer.ALIGNMENT_CENTER
	name_row.add_theme_constant_override("separation", 6)
	top.add_child(name_row)

	var name_l := Label.new()
	name_l.text = offer_item.display_name
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_l.max_lines_visible = 2
	name_l.add_theme_font_size_override("font_size", 15)
	name_l.add_theme_color_override("font_color", Color(0.94, 0.95, 1.0))
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_l)

	if offer_item.is_weapon():
		var badge := Label.new()
		badge.text = "WPN"
		badge.add_theme_font_size_override("font_size", 9)
		badge.add_theme_color_override("font_color", Color(0.98, 0.62, 0.18))
		badge.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.02, 0.8))
		badge.add_theme_constant_override("outline_size", 2)
		name_row.add_child(badge)

	var desc := Label.new()
	desc.text = offer_item.display_description if offer_item.display_description != "" else " "
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.max_lines_visible = 3
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.7, 0.74, 0.84))
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(desc)

	var price := Label.new()
	price.text = "%d gold" % offer_item.price
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price.add_theme_font_size_override("font_size", 14)
	price.add_theme_color_override("font_color", Color(0.98, 0.82, 0.4))
	top.add_child(price)

	var buy_row := CenterContainer.new()
	buy_row.custom_minimum_size = Vector2(0, 34)
	buy_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(buy_row)

	var buy := Button.new()
	buy.text = "Sold" if offer_item.is_purchased else "Buy"
	buy.disabled = offer_item.is_purchased
	buy.custom_minimum_size = Vector2(108, 32)
	if _pixel_ui_ready:
		_style_pixel_muted_button(buy)
	else:
		_style_muted_button(buy)
	if not offer_item.is_purchased:
		buy.pressed.connect(_on_buy_pressed.bind(offer_item))
	buy_row.add_child(buy)

	card.mouse_entered.connect(_on_card_hovered.bind(card, true))
	card.mouse_exited.connect(_on_card_hovered.bind(card, false))

	return wrap


func _on_card_hovered(card: PanelContainer, hovered: bool) -> void:
	if card.modulate.a < 0.5:
		return
	var tw := create_tween().set_parallel(true)
	if hovered:
		tw.tween_property(card, "scale", Vector2(1.04, 1.04), 0.12).set_ease(Tween.EASE_OUT)
		tw.tween_property(card, "modulate", Color(1, 1, 1, 1.0), 0.12)
	else:
		tw.tween_property(card, "scale", Vector2.ONE, 0.12).set_ease(Tween.EASE_OUT)
		tw.tween_property(card, "modulate", Color(1, 1, 1, 1.0), 0.12)


func _rarity_color(rarity: int) -> Color:
	match rarity:
		ItemData.Rarity.UNCOMMON:
			return Color(0.35, 0.9, 0.42, 0.95)
		ItemData.Rarity.RARE:
			return Color(0.35, 0.58, 1.0, 0.95)
		ItemData.Rarity.LEGENDARY:
			return Color(0.98, 0.62, 0.18, 0.95)
		_:
			return Color(0.72, 0.72, 0.76, 0.85)


func _on_buy_pressed(offer: ShopItem) -> void:
	if not _shop_manager:
		return
	if offer.is_purchased:
		return
	if offer.is_placeholder:
		_show_toast("Assign real ItemData on ShopManager — placeholder only.")
		return
	if _shop_manager.try_purchase(offer):
		_rebuild_row(_shop_manager.current_offerings)
	else:
		_show_toast("Can't afford that yet")


func _show_toast(msg: String) -> void:
	if _toast == null:
		return
	_toast.text = msg
	_toast.visible = true
	var tw := create_tween()
	tw.tween_property(_toast, "modulate:a", 1.0, 0.12).from(0.35)
	tw.tween_interval(1.1)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func(): _toast.visible = false; _toast.modulate.a = 1.0)
