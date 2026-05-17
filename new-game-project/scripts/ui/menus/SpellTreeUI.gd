extends Control
class_name SpellTreeUI

@onready var _subtitle: Label = $Subtitle
@onready var _detail_title: Label = $DetailPanel/DetailBox/Title
@onready var _detail_body: Label = $DetailPanel/DetailBox/Body
@onready var _detail_box: VBoxContainer = $DetailPanel/DetailBox
@onready var _detail_panel: PanelContainer = $DetailPanel
@onready var _canvas: Control = $Canvas
@onready var _nodes_root: Control = $Canvas/Nodes

const CANVAS_SIZE := Vector2(1060.0, 730.0)
const CANVAS_TOP := 88.0
const CANVAS_MIN_LEFT := 28.0
const DETAIL_PANEL_MARGIN := 18.0
const DETAIL_PANEL_SIZE := Vector2(372.0, 236.0)
const DETAIL_PANEL_TOP_OFFSET := 262.0

var _selected_node: SpellNode = null
var _spell_controller: SpellController = null
var _status_label: Label = null
var _equip_buttons: Array[Button] = []
var _node_by_spell_id: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not resized.is_connected(_on_resized):
		resized.connect(_on_resized)

	_detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_body.custom_minimum_size = Vector2(320.0, 0.0)

	for child in _nodes_root.get_children():
		var node := child as SpellNode
		if node == null:
			continue
		_node_by_spell_id[node.spell_id] = node
		node.set_unlocked(false)
		node.set_equipped(false)
		if not node.hovered.is_connected(_on_node_hovered):
			node.hovered.connect(_on_node_hovered)
		if not node.clicked.is_connected(_on_node_clicked):
			node.clicked.connect(_on_node_clicked)

	_build_detail_controls()
	call_deferred("_connect_spell_controller")
	visible = false


func open_tree() -> void:
	visible = true
	_refresh_tree_state()
	call_deferred("_layout_spellbook")


func close_tree() -> void:
	visible = false


func _on_node_hovered(node: SpellNode) -> void:
	_update_detail(node)


func _on_node_clicked(node: SpellNode) -> void:
	if _selected_node != null:
		_selected_node.set_selected(false)
	_selected_node = node
	_selected_node.set_selected(true)
	_update_detail(node)


func _on_resized() -> void:
	call_deferred("_layout_spellbook")


func _layout_spellbook() -> void:
	if _canvas == null or _detail_panel == null:
		return
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var available_h: float = size.y - CANVAS_TOP - 8.0
	var available_w: float = size.x - CANVAS_MIN_LEFT * 2.0
	var scale_h: float = available_h / CANVAS_SIZE.y
	var scale_w: float = available_w / CANVAS_SIZE.x
	var canvas_scale: float = minf(1.0, minf(scale_h, scale_w))
	_canvas.scale = Vector2(canvas_scale, canvas_scale)

	var scaled_w: float = CANVAS_SIZE.x * canvas_scale
	var canvas_x: float = (size.x - scaled_w) * 0.5
	if canvas_x < CANVAS_MIN_LEFT:
		canvas_x = CANVAS_MIN_LEFT
	_canvas.position = Vector2(canvas_x, CANVAS_TOP)
	_canvas.size = CANVAS_SIZE

	var panel_w: float = DETAIL_PANEL_SIZE.x
	var panel_h: float = DETAIL_PANEL_SIZE.y
	var preferred_panel_x: float = canvas_x + scaled_w + DETAIL_PANEL_MARGIN
	var max_panel_x: float = size.x - DETAIL_PANEL_MARGIN - panel_w
	var min_panel_x: float = DETAIL_PANEL_MARGIN
	var panel_x: float = preferred_panel_x
	if panel_x < min_panel_x:
		panel_x = min_panel_x
	if max_panel_x < min_panel_x:
		max_panel_x = min_panel_x
	if panel_x > max_panel_x:
		panel_x = max_panel_x

	var scaled_top_offset: float = DETAIL_PANEL_TOP_OFFSET * canvas_scale + CANVAS_TOP
	var max_panel_y: float = size.y - DETAIL_PANEL_MARGIN - panel_h
	if max_panel_y < DETAIL_PANEL_MARGIN:
		max_panel_y = DETAIL_PANEL_MARGIN
	var panel_y: float = scaled_top_offset
	if panel_y < DETAIL_PANEL_MARGIN:
		panel_y = DETAIL_PANEL_MARGIN
	if panel_y > max_panel_y:
		panel_y = max_panel_y

	_detail_panel.position = Vector2(panel_x, panel_y)
	_detail_panel.size = Vector2(panel_w, panel_h)


func _build_detail_controls() -> void:
	if _status_label != null:
		return

	_status_label = Label.new()
	_status_label.name = "Status"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 12)
	_status_label.add_theme_color_override("font_color", Color(0.96, 0.84, 0.5))
	_detail_box.add_child(_status_label)

	var equip_row := HBoxContainer.new()
	equip_row.name = "EquipButtons"
	equip_row.add_theme_constant_override("separation", 8)
	_detail_box.add_child(equip_row)

	for slot_index in SpellController.MAX_SPELL_SLOTS:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(92, 28)
		btn.focus_mode = Control.FOCUS_NONE
		btn.text = "Equip %d" % (slot_index + 1)
		btn.pressed.connect(_on_equip_pressed.bind(slot_index))
		equip_row.add_child(btn)
		_equip_buttons.append(btn)


func _connect_spell_controller() -> void:
	var controllers := get_tree().get_nodes_in_group("spell_controller")
	if controllers.is_empty():
		push_warning("[SpellTreeUI] No SpellController found.")
		_refresh_tree_state()
		return
	_spell_controller = controllers[0] as SpellController
	if _spell_controller == null:
		_refresh_tree_state()
		return
	if not _spell_controller.loadout_changed.is_connected(_refresh_tree_state):
		_spell_controller.loadout_changed.connect(_refresh_tree_state)
	if not _spell_controller.spell_unlocked.is_connected(_on_spell_unlocked):
		_spell_controller.spell_unlocked.connect(_on_spell_unlocked)
	_refresh_tree_state()


func _on_spell_unlocked(spell_id: String, _spell: SpellData, _unlock_level: int) -> void:
	if _node_by_spell_id.has(spell_id):
		var node := _node_by_spell_id[spell_id] as SpellNode
		if _selected_node == null:
			_selected_node = node
			_selected_node.set_selected(true)
	_update_detail(_selected_node)
	_refresh_tree_state()


func _refresh_tree_state() -> void:
	var unlocked_count := 0
	var total_spells := SpellTreeData.get_spell_ids_in_unlock_order().size()
	for spell_id in _node_by_spell_id.keys():
		var node := _node_by_spell_id[spell_id] as SpellNode
		var unlocked := _spell_controller != null and _spell_controller.is_unlocked(spell_id)
		var equipped := _spell_controller != null and _spell_controller.is_equipped(spell_id)
		if unlocked:
			unlocked_count += 1
		node.set_unlocked(unlocked)
		node.set_equipped(equipped)

	if _subtitle:
		var level_text := XPSystem.current_level if Engine.is_editor_hint() == false else 1
		_subtitle.text = "Level %d - %d/%d spells unlocked. Equip any unlocked spell into slots 1-3." % [
			level_text,
			unlocked_count,
			total_spells,
		]

	if _selected_node == null and _node_by_spell_id.has("fireball"):
		_selected_node = _node_by_spell_id["fireball"]
		_selected_node.set_selected(true)
	_update_detail(_selected_node)


func _update_detail(node: SpellNode) -> void:
	if node == null:
		_detail_title.text = "Hover a spell"
		_detail_body.text = "Pick a node to inspect what it does and when it unlocks."
		_status_label.text = ""
		for btn in _equip_buttons:
			btn.disabled = true
		return

	var spell_def := SpellTreeData.get_spell_definition(node.spell_id)
	var spell := SpellTreeData.get_spell(node.spell_id)
	var title: String = node.display_name.replace("\n", " ")
	if not spell_def.is_empty():
		title = str(spell_def.get("name", title))
	_detail_title.text = title

	var unlock_level: int = SpellTreeData.get_unlock_level(node.spell_id)
	var unlocked: bool = _spell_controller != null and _spell_controller.is_unlocked(node.spell_id)
	var equipped_slot: int = _spell_controller.get_equipped_slot(node.spell_id) if _spell_controller != null else -1

	if spell == null:
		_detail_body.text = "This node still has no spell data behind it."
		_status_label.text = "Unwired"
		for btn in _equip_buttons:
			btn.disabled = true
		return

	var cast_text: String = _cast_type_text(spell.cast_type)
	var range_text: String = "Radius %.0f" % spell.effect_radius if spell.cast_type == SpellData.CastType.SELF_CAST else "Range %.0f" % spell.detection_range
	_detail_body.text = "%s\n\nUnlocks at level %d.\n%s | Damage %d | Cooldown %.1fs | %s" % [
		spell.description,
		unlock_level,
		cast_text,
		spell.base_damage,
		spell.cooldown,
		range_text,
	]

	if equipped_slot >= 0:
		_status_label.text = "Equipped in slot %d" % (equipped_slot + 1)
	elif unlocked:
		_status_label.text = "Unlocked and ready to equip."
	else:
		_status_label.text = "Locked. Reach level %d to unlock this spell." % unlock_level

	for slot_index in _equip_buttons.size():
		var btn := _equip_buttons[slot_index]
		var slot_spell := _spell_controller.get_spell_in_slot(slot_index) if _spell_controller != null else null
		if not unlocked:
			btn.text = "Level %d" % unlock_level
			btn.disabled = true
			continue
		if slot_spell != null and _spell_controller.get_equipped_slot(node.spell_id) == slot_index:
			btn.text = "Slot %d" % (slot_index + 1)
			btn.disabled = true
		elif slot_spell == null:
			btn.text = "Equip %d" % (slot_index + 1)
			btn.disabled = false
		else:
			btn.text = "Replace %d" % (slot_index + 1)
			btn.disabled = false


func _on_equip_pressed(slot_index: int) -> void:
	if _selected_node == null or _spell_controller == null:
		return
	if _spell_controller.equip_spell_to_slot(_selected_node.spell_id, slot_index):
		_refresh_tree_state()


func _cast_type_text(cast_type: SpellData.CastType) -> String:
	match cast_type:
		SpellData.CastType.SELF_CAST:
			return "Self cast"
		SpellData.CastType.AUTO_TARGET:
			return "Auto target"
		SpellData.CastType.DIRECTIONAL:
			return "Directional"
	return "Spell"
