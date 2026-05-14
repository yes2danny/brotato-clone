extends CanvasLayer

# ─────────────────────────────────────────────
# GameOverUI — Placeholder
# Shows game over or victory screen with run stats.
# This is a placeholder — replace with real art later.
#
# Scene setup needed:
#   CanvasLayer
#   └─ Panel
#      └─ VBoxContainer
#         ├─ Label (name: "TitleLabel")
#         ├─ Label (name: "StatsLabel")
#         ├─ Button (name: "RestartButton")
#         └─ Button (name: "QuitButton")
# ─────────────────────────────────────────────

var title_label: Label = null
var stats_label: Label = null


func _ready() -> void:
	visible = false

	# Safely find UI nodes — won't crash if not built yet
	title_label = get_node_or_null("Panel/VBoxContainer/TitleLabel")
	stats_label = get_node_or_null("Panel/VBoxContainer/StatsLabel")

	GameManager.game_over_triggered.connect(_on_game_over)
	GameManager.victory_triggered.connect(_on_victory)


func _on_game_over(kills: int, waves: int, time: float) -> void:
	show_screen("GAME OVER", kills, waves, time, false)


func _on_victory(kills: int, waves: int, time: float) -> void:
	show_screen("YOU WIN!", kills, waves, time, true)


func show_screen(title: String, kills: int, waves: int, time: float, is_victory: bool = false) -> void:
	visible = true
	var total_seconds: int = int(time)
	var minutes: int = floori(float(total_seconds) / 60.0)
	var seconds: int = total_seconds % 60
	if title_label:
		title_label.text = title
	if stats_label:
		var stats_text := "Enemies killed: %d\nWaves survived: %d\nTime: %02d:%02d" % [
			kills, waves, minutes, seconds
		]
		if is_victory and GameManager.last_run_meta_awarded > 0:
			stats_text += "\nMeta earned (placeholder): +%d" % GameManager.last_run_meta_awarded
		stats_label.text = stats_text


# Connect these to your Button nodes in the Inspector (or in _ready)
func _on_restart_button_pressed() -> void:
	GameManager.restart_game()


func _on_quit_button_pressed() -> void:
	GameManager.quit_game()
