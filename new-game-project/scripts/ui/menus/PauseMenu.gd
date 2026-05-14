extends CanvasLayer

# ─────────────────────────────────────────────
# PauseMenu — Placeholder
# Press ESC to toggle pause.
# This is a placeholder — replace with real art later.
#
# Scene setup needed:
#   CanvasLayer
#   └─ Panel
#      └─ VBoxContainer
#         ├─ Label ("Paused")
#         ├─ Button (name: "ResumeButton")
#         ├─ Button (name: "MenuButton")
#         └─ Button (name: "QuitButton")
# ─────────────────────────────────────────────

func _ready() -> void:
	visible = false  # Hidden at game start


func _input(event: InputEvent) -> void:
	# Listen for ESC key press
	if event.is_action_pressed("ui_cancel"):
		if _is_shop_blocking_pause():
			return
		toggle_pause()


func toggle_pause() -> void:
	if _is_shop_blocking_pause():
		return
	if GameManager.state == GameManager.GameState.PLAYING:
		pause()
	elif GameManager.state == GameManager.GameState.PAUSED:
		resume()


func pause() -> void:
	GameManager.state = GameManager.GameState.PAUSED
	get_tree().paused = true
	visible = true


func resume() -> void:
	GameManager.state = GameManager.GameState.PLAYING
	get_tree().paused = false
	visible = false


# Connect these to your Button nodes in the Inspector (or in _ready)
func _on_resume_button_pressed() -> void:
	resume()


func _on_menu_button_pressed() -> void:
	get_tree().paused = false
	GameManager.load_main_menu()


func _on_quit_button_pressed() -> void:
	GameManager.quit_game()


func _is_shop_blocking_pause() -> bool:
	var sm := get_tree().get_first_node_in_group("shop_manager")
	return sm != null and sm.is_shop_open
