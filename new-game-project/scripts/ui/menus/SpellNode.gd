@tool
extends Control
class_name SpellNode

# One hand-placeable spell node inside the authored Spellbook scene.
# The scene owns the layout; this script only owns behavior and visuals.

signal hovered(node: SpellNode)
signal unhovered(node: SpellNode)
signal clicked(node: SpellNode)

const NODE_ROOT := "res://assets/ui/pixel_ui/SkillTree/"

@export var spell_id: String = ""
@export var display_name: String = "Spell"
@export var branch_name: String = ""
@export_enum("Blue", "Grey", "Purple", "Red", "White", "Yellow") var color_name: String = "White"
@export var has_art: bool = true
@export var is_side_spell: bool = false

const SELECTION_FILL_COLORS := {
	"Blue": Color(0.33, 0.7, 1.0, 0.82),
	"Grey": Color(0.68, 0.72, 0.8, 0.78),
	"Purple": Color(0.72, 0.48, 1.0, 0.82),
	"Red": Color(1.0, 0.43, 0.32, 0.82),
	"White": Color(0.95, 0.9, 0.72, 0.8),
	"Yellow": Color(1.0, 0.82, 0.3, 0.84),
}

@onready var _frame: TextureRect = $Frame
@onready var _selection_fill: ColorRect = $SelectionFill
@onready var _selector: TextureRect = $Selector
@onready var _title: Label = $Title

var _selected: bool = false
var _unlocked: bool = false
var _equipped: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)
	_refresh_visuals()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)
		accept_event()


func set_selected(value: bool) -> void:
	_selected = value
	_refresh_selection_state()


func set_unlocked(value: bool) -> void:
	_unlocked = value
	_refresh_selection_state()


func set_equipped(value: bool) -> void:
	_equipped = value
	_refresh_selection_state()


func _refresh_visuals() -> void:
	if not is_node_ready():
		return
	var texture_name := "SkillSlotRoundPlaceholder.png" if not has_art else "SkillSlotRound.png"
	_frame.texture = load(NODE_ROOT + color_name + "/" + texture_name)
	_title.text = display_name
	_title.add_theme_font_size_override("font_size", 10 if is_side_spell else 11)
	_title.add_theme_color_override(
		"font_color",
		Color(0.95, 0.92, 0.84) if has_art else Color(0.58, 0.6, 0.68)
	)
	_refresh_selection_state()


func _refresh_selection_state() -> void:
	if not is_node_ready():
		return
	var placeholder_suffix := "Placeholder" if not has_art else ""
	_selector.texture = load(NODE_ROOT + color_name + "/Selector%s.png" % placeholder_suffix)
	_selector.visible = _selected or _equipped

	var fill_color: Color = SELECTION_FILL_COLORS.get(color_name, Color(0.95, 0.9, 0.72, 0.8))
	if _selected:
		_selection_fill.color = fill_color
		_selection_fill.visible = true
	elif _equipped:
		var equipped_fill: Color = fill_color
		equipped_fill.a = 0.45
		_selection_fill.color = equipped_fill
		_selection_fill.visible = true
	else:
		_selection_fill.visible = false

	if not _unlocked:
		_frame.modulate = Color(0.5, 0.52, 0.58, 0.5)
		_title.add_theme_color_override("font_color", Color(0.46, 0.48, 0.54))
	elif _selected:
		_frame.modulate = Color(1.12, 1.12, 1.12, 1.0)
		_title.add_theme_color_override("font_color", Color(0.98, 0.95, 0.86))
	elif _equipped:
		_frame.modulate = Color(1.06, 1.06, 0.96, 1.0)
		_title.add_theme_color_override("font_color", Color(0.92, 0.9, 0.78))
	else:
		_frame.modulate = Color(1, 1, 1, 1)
		_title.add_theme_color_override(
			"font_color",
			Color(0.95, 0.92, 0.84) if has_art else Color(0.58, 0.6, 0.68)
		)


func _on_mouse_entered() -> void:
	hovered.emit(self)


func _on_mouse_exited() -> void:
	unhovered.emit(self)
