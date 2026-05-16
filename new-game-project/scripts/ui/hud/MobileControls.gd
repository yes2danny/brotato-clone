extends CanvasLayer

@export var show_on_desktop_for_testing: bool = false

@onready var movement_joystick = $Root/MovementJoystick
@onready var dodge_button: Button = $Root/DodgeButton


func _ready() -> void:
	dodge_button.button_down.connect(_on_dodge_button_down)
	dodge_button.button_up.connect(_on_dodge_button_up)
	_update_visibility()


func _process(_delta: float) -> void:
	_update_visibility()

	if not visible:
		_release_movement_actions()
		Input.action_release("ui_accept")
		return

	var joystick_value: Vector2 = movement_joystick.get_value()
	_set_movement_actions(joystick_value)


func _exit_tree() -> void:
	_release_movement_actions()
	Input.action_release("ui_accept")


func _update_visibility() -> void:
	var touch_device_available := DisplayServer.is_touchscreen_available()
	visible = (touch_device_available or show_on_desktop_for_testing) and GameManager.state == GameManager.GameState.PLAYING


func _set_movement_actions(value: Vector2) -> void:
	_apply_action_strength("ui_left", maxf(-value.x, 0.0))
	_apply_action_strength("ui_right", maxf(value.x, 0.0))
	_apply_action_strength("ui_up", maxf(-value.y, 0.0))
	_apply_action_strength("ui_down", maxf(value.y, 0.0))


func _apply_action_strength(action_name: StringName, strength: float) -> void:
	if strength > 0.05:
		Input.action_press(action_name, strength)
	else:
		Input.action_release(action_name)


func _release_movement_actions() -> void:
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	Input.action_release("ui_up")
	Input.action_release("ui_down")


func _on_dodge_button_down() -> void:
	Input.action_press("ui_accept")


func _on_dodge_button_up() -> void:
	Input.action_release("ui_accept")
