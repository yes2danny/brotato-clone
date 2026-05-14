extends Control

# ─────────────────────────────────────────────
# UpgradeManager
# Place this as a Control node in your main UI layer.
# When the player levels up, the game pauses and 4 random
# upgrade cards appear. The player picks one, it gets applied,
# and then the game resumes.
#
# Add this node to the "upgrade_manager" group in the Inspector!
# (Select the node → Groups tab → add "upgrade_manager")
# ─────────────────────────────────────────────

# The 4 possible upgrade types
enum UpgradeType {
	MAX_HEALTH,
	MOVE_SPEED,
	DAMAGE,
	FIRE_RATE
}

# Human-readable names for displaying on cards
const UPGRADE_NAMES = {
	UpgradeType.MAX_HEALTH: "Max Health +20",
	UpgradeType.MOVE_SPEED: "Move Speed +30",
	UpgradeType.DAMAGE:     "Bullet Damage +10",
	UpgradeType.FIRE_RATE:  "Fire Rate +25%"
}

# We'll populate these references when the upgrade screen is shown
var _player: Node = null
var _weapon: Node = null

# Holds the 4 upgrades currently being offered
var _current_offers: Array = []

var _card_buttons: Array[Button] = []


func _ready() -> void:
	add_to_group("upgrade_manager")
	# Still receive input while the scene tree is paused (level-up overlay)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var p: Node = get_parent()
	if p:
		p.process_mode = Node.PROCESS_MODE_ALWAYS
	# CanvasLayer is not a Control; when wrapped in UpgradeRoot, unpause input on the layer too
	var layer: Node = p
	while layer != null and not (layer is CanvasLayer):
		layer = layer.get_parent()
	if layer:
		layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_build_upgrade_ui()
	visible = false  # Hidden at game start


func _build_upgrade_ui() -> void:
	if not _card_buttons.is_empty():
		return

	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = Color(0.02, 0.03, 0.06, 0.78)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.grow_horizontal = Control.GROW_DIRECTION_BOTH
	backdrop.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(backdrop)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "Level up — pick one upgrade"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	for i in 4:
		var btn := Button.new()
		btn.name = "UpgradeCard%d" % (i + 1)
		btn.custom_minimum_size = Vector2(320, 44)
		btn.focus_mode = Control.FOCUS_ALL
		btn.pressed.connect(_on_upgrade_chosen.bind(i))
		vbox.add_child(btn)
		_card_buttons.append(btn)


# Called by XPSystem when the player levels up
func show_upgrades() -> void:
	# Pause the game — freezes _process() / physics on PAUSABLE nodes
	get_tree().paused = true
	visible = true

	# Find player and weapon so we can apply upgrades to them
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]
		_weapon = _player.get_node_or_null("WeaponController")

	# Pick 4 random unique upgrades to offer
	_current_offers = _pick_random_upgrades(4)

	for i in _card_buttons.size():
		if i < _current_offers.size():
			var ut: UpgradeType = _current_offers[i]
			_card_buttons[i].text = UPGRADE_NAMES[ut]
			_card_buttons[i].visible = true
			_card_buttons[i].disabled = false
		else:
			_card_buttons[i].visible = false

	_card_buttons[0].grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k := (event as InputEventKey).keycode
		match k:
			KEY_1:
				_on_upgrade_chosen(0)
			KEY_2:
				_on_upgrade_chosen(1)
			KEY_3:
				_on_upgrade_chosen(2)
			KEY_4:
				_on_upgrade_chosen(3)


# Pick `count` random unique upgrades from the full pool
func _pick_random_upgrades(count: int) -> Array:
	var all_upgrades = [
		UpgradeType.MAX_HEALTH,
		UpgradeType.MOVE_SPEED,
		UpgradeType.DAMAGE,
		UpgradeType.FIRE_RATE
	]
	all_upgrades.shuffle()  # Randomize the order
	return all_upgrades.slice(0, count)  # Take the first `count` items


# Call this when the player clicks a card.
# index = 0, 1, 2, or 3 (which card they picked)
func _on_upgrade_chosen(index: int) -> void:
	if index >= _current_offers.size():
		return

	var chosen = _current_offers[index]
	_apply_upgrade(chosen)

	# Hide the upgrade screen and resume the game
	visible = false
	get_tree().paused = false


func _apply_upgrade(upgrade: UpgradeType) -> void:
	match upgrade:
		UpgradeType.MAX_HEALTH:
			# Increase max health and also heal the player by that amount
			if _player:
				var health = _player.get_node_or_null("HealthSystem")
				if health:
					health.max_health += 20
					health.heal(20)

		UpgradeType.MOVE_SPEED:
			# Directly increase the player's move_speed variable
			if _player:
				_player.move_speed += 30

		UpgradeType.DAMAGE:
			if _weapon:
				_weapon.upgrade_damage(10)

		UpgradeType.FIRE_RATE:
			# 1.25 = 25% faster fire rate
			if _weapon:
				_weapon.upgrade_fire_rate(1.25)
