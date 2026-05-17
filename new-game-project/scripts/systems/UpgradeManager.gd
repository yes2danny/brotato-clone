extends Control

# ─────────────────────────────────────────────
# UpgradeManager
# Place this as a Control node in your main UI layer.
# When the player levels up, the game pauses and 3 cards appear.
# Cards can be stat boosts OR spell unlocks/upgrades.
# The player picks one, it gets applied, and the game resumes.
#
# This is the Vampire Survivors-style card picker system.
# Spell availability is determined by SpellTreeData prerequisites —
# if you have fireball, explosive_fireball will show up as an upgrade card.
#
# Add this node to the "upgrade_manager" group in the Inspector!
# ─────────────────────────────────────────────

# ── Card types ────────────────────────────────────────────────────────────────
enum CardType {
	# Stat boosts
	MAX_HEALTH,
	MOVE_SPEED,
	DAMAGE,
	FIRE_RATE,
	# Spell cards — these carry a spell_id in the offer Dictionary
	SPELL_NEW,      # A root spell with no prerequisites (new branch)
	SPELL_UPGRADE,  # A spell that builds on one the player already owns
}

# ── School colors for spell cards ─────────────────────────────────────────────
# Each magic school gets its own card color so the player can instantly read
# what type of spell they're looking at.
const SCHOOL_COLORS := {
	# SpellData.School enum values → Color
	0: Color(0.85, 0.25, 0.10),  # FIRE   — deep red-orange
	1: Color(0.20, 0.45, 0.90),  # SHOCK  — electric blue
	2: Color(0.25, 0.65, 0.20),  # POISON — toxic green
	3: Color(0.20, 0.60, 0.80),  # WATER  — cool teal
	4: Color(0.35, 0.15, 0.55),  # DARK   — deep purple
	5: Color(0.60, 0.08, 0.15),  # BLOOD  — dark crimson
}

const SCHOOL_NAMES := {
	0: "Fire",
	1: "Lightning",
	2: "Poison",
	3: "Water",
	4: "Dark",
	5: "Blood",
}

# Stat card color — neutral grey-blue
const STAT_CARD_COLOR := Color(0.18, 0.22, 0.30)

# Number of cards shown per level-up (and per wave-end reward)
const CARD_COUNT := 3

# Emitted after the player picks a card — WaveManager listens for this
# so it knows when to open the shop after a wave-end card offer.
signal cards_dismissed

# ── Node references ───────────────────────────────────────────────────────────
var _player: Node = null
var _weapon: Node = null
var _spell_controller: Node = null  # SpellController on the player

# ── Offer state ───────────────────────────────────────────────────────────────
# Each entry is a Dictionary:
#   { "card_type": CardType, "spell_id": String }
# spell_id is "" for stat cards.
var _current_offers: Array[Dictionary] = []

# ── UI nodes (built in code, no scene needed) ─────────────────────────────────
var _card_panels: Array[PanelContainer] = []
var _card_buttons: Array[Button] = []
var _card_school_labels: Array[Label] = []
var _card_desc_labels: Array[Label] = []
var _title_label: Label = null


func _ready() -> void:
	add_to_group("upgrade_manager")
	# Must keep processing even while game tree is paused (level-up overlay)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var p: Node = get_parent()
	if p:
		p.process_mode = Node.PROCESS_MODE_ALWAYS
	var layer: Node = p
	while layer != null and not (layer is CanvasLayer):
		layer = layer.get_parent()
	if layer:
		layer.process_mode = Node.PROCESS_MODE_ALWAYS

	_build_ui()
	visible = false


# ── UI Construction ───────────────────────────────────────────────────────────

func _build_ui() -> void:
	# Dark semi-transparent backdrop that blocks clicks on the game world
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = Color(0.02, 0.03, 0.08, 0.82)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	# Center everything on screen
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	# Outer wrapper for the whole picker
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 16)
	center.add_child(outer)

	# "Level Up — choose one" title
	_title_label = Label.new()
	_title_label.text = "LEVEL UP — Choose one"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 22)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.60))
	outer.add_child(_title_label)

	# Row of cards side by side
	var card_row := HBoxContainer.new()
	card_row.add_theme_constant_override("separation", 14)
	card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(card_row)

	for i in CARD_COUNT:
		var card := _build_card(i)
		card_row.add_child(card)

	# Keyboard hint at the bottom
	var hint := Label.new()
	hint.text = "Press 1 / 2 / 3  or  click a card"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	outer.add_child(hint)


func _build_card(index: int) -> PanelContainer:
	# Each card is a PanelContainer so we can color its background
	var panel := PanelContainer.new()
	panel.name = "Card%d" % (index + 1)
	panel.custom_minimum_size = Vector2(200, 260)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# School / type badge at the top (e.g. "Fire" or "Stat Boost")
	var school_label := Label.new()
	school_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	school_label.add_theme_font_size_override("font_size", 11)
	school_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.70))
	vbox.add_child(school_label)
	_card_school_labels.append(school_label)

	# Separator line
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Main card button — shows the spell/upgrade name
	var btn := Button.new()
	btn.name = "CardButton%d" % (index + 1)
	btn.custom_minimum_size = Vector2(176, 50)
	btn.focus_mode = Control.FOCUS_ALL
	btn.pressed.connect(_on_card_chosen.bind(index))
	vbox.add_child(btn)
	_card_buttons.append(btn)

	# Description text below the button
	var desc := Label.new()
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", Color(0.80, 0.80, 0.80))
	desc.custom_minimum_size = Vector2(176, 80)
	vbox.add_child(desc)
	_card_desc_labels.append(desc)

	_card_panels.append(panel)
	return panel


# ── Show / Hide ───────────────────────────────────────────────────────────────

# Called by XPSystem when the player levels up
func show_upgrades() -> void:
	get_tree().paused = true
	visible = true

	# Grab player, weapon, and spell controller references
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]
		_weapon = _player.get_node_or_null("WeaponController")
		_spell_controller = _player.get_node_or_null("SpellController")

	# Fallback: find SpellController by group if it isn't a direct child
	if _spell_controller == null:
		var controllers := get_tree().get_nodes_in_group("spell_controller")
		if not controllers.is_empty():
			_spell_controller = controllers[0]

	# Build this level's 3 card offers
	_current_offers = _build_offer_pool()

	# Populate each card panel with the offer data
	for i in _card_panels.size():
		if i < _current_offers.size():
			_populate_card(i, _current_offers[i])
			_card_panels[i].visible = true
			_card_buttons[i].disabled = false
		else:
			_card_panels[i].visible = false

	_card_buttons[0].grab_focus()


## Called by WaveManager after the wave summary is dismissed.
## Shows one guaranteed card offer before the shop opens.
## Identical to show_upgrades() but with a different title so the player
## knows this is a wave reward, not a level-up reward.
func show_wave_reward() -> void:
	_title_label.text = "WAVE COMPLETE — Choose a reward"
	show_upgrades()


# ── Offer Pool Builder ────────────────────────────────────────────────────────

# Builds the list of CARD_COUNT offers for this level-up.
# Always at least 1 stat card. Always at least 1 spell card when available.
func _build_offer_pool() -> Array[Dictionary]:
	var offers: Array[Dictionary] = []

	# Get spells the player can currently unlock (prereqs met, not owned)
	var available_spell_ids := _get_available_spell_ids()
	available_spell_ids.shuffle()

	# Stat pool — all 4 stat types shuffled
	var stat_pool: Array = [
		CardType.MAX_HEALTH,
		CardType.MOVE_SPEED,
		CardType.DAMAGE,
		CardType.FIRE_RATE,
	]
	stat_pool.shuffle()

	# Add up to 2 spell cards from the available pool
	var spell_cards_added := 0
	for spell_id in available_spell_ids:
		if spell_cards_added >= 2:
			break
		var spell_def := SpellTreeData.get_spell_definition(spell_id)
		var prereqs: Array = spell_def.get("prerequisites", [])
		# SPELL_UPGRADE if it has a prerequisite (it builds on something owned)
		# SPELL_NEW if it has no prerequisites (a fresh branch root)
		var card_type := CardType.SPELL_UPGRADE if prereqs.size() > 0 else CardType.SPELL_NEW
		offers.append({ "card_type": card_type, "spell_id": spell_id })
		spell_cards_added += 1

	# Fill remaining slots with stat cards
	for stat_type in stat_pool:
		if offers.size() >= CARD_COUNT:
			break
		offers.append({ "card_type": stat_type, "spell_id": "" })

	# Shuffle so spell cards don't always appear first
	offers.shuffle()
	return offers


# Returns spell IDs where:
#   - All prerequisites are already in the player's unlocked list
#   - The spell itself is NOT already unlocked
func _get_available_spell_ids() -> Array[String]:
	if _spell_controller == null:
		return []

	var available: Array[String] = []
	var all_defs := SpellTreeData.get_spell_definitions()

	for spell_id in all_defs.keys():
		# Skip spells the player already owns
		if _spell_controller.is_unlocked(spell_id):
			continue

		# Check every prerequisite is already unlocked
		var spell_def: Dictionary = SpellTreeData.get_spell_definition(spell_id)
		var prereqs: Array = spell_def.get("prerequisites", [])
		var prereqs_met := true
		for prereq_id in prereqs:
			if not _spell_controller.is_unlocked(prereq_id):
				prereqs_met = false
				break

		if prereqs_met:
			available.append(spell_id)

	return available


# ── Card Population ───────────────────────────────────────────────────────────

# Fills a card panel with the correct text and color for one offer.
func _populate_card(index: int, offer: Dictionary) -> void:
	var card_type: CardType = offer["card_type"]
	var spell_id: String = offer["spell_id"]
	var panel := _card_panels[index]
	var btn := _card_buttons[index]
	var school_lbl := _card_school_labels[index]
	var desc_lbl := _card_desc_labels[index]

	if card_type == CardType.SPELL_NEW or card_type == CardType.SPELL_UPGRADE:
		var spell := SpellTreeData.get_spell(spell_id)
		if spell == null:
			btn.text = "???"
			school_lbl.text = ""
			desc_lbl.text = ""
			return

		# School badge text
		var school_int := int(spell.school)
		school_lbl.text = SCHOOL_NAMES.get(school_int, "Spell").to_upper()
		if card_type == CardType.SPELL_UPGRADE:
			school_lbl.text += "  ▲ UPGRADE"

		# Button name — the spell name
		btn.text = spell.spell_name

		# Description
		desc_lbl.text = spell.description

		# Color the card by school
		_set_card_color(panel, SCHOOL_COLORS.get(school_int, Color(0.3, 0.3, 0.3)))

	else:
		# Stat card
		school_lbl.text = "STAT BOOST"
		btn.text = _stat_label(card_type)
		desc_lbl.text = _stat_description(card_type)
		_set_card_color(panel, STAT_CARD_COLOR)


# Sets a PanelContainer's background color via a StyleBoxFlat.
func _set_card_color(panel: PanelContainer, color: Color) -> void:
	var style := StyleBoxFlat.new()
	# Slightly lighter border on top for a nice card edge feel
	style.bg_color = color
	style.border_color = color.lightened(0.25)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)


# ── Stat Card Helpers ─────────────────────────────────────────────────────────

func _stat_label(card_type: CardType) -> String:
	match card_type:
		CardType.MAX_HEALTH: return "Max Health +20"
		CardType.MOVE_SPEED: return "Move Speed +30"
		CardType.DAMAGE:     return "Bullet Damage +10"
		CardType.FIRE_RATE:  return "Fire Rate +25%"
	return "???"


func _stat_description(card_type: CardType) -> String:
	match card_type:
		CardType.MAX_HEALTH: return "Increase your maximum health and heal for the same amount."
		CardType.MOVE_SPEED: return "Move faster. Great for kiting enemies and repositioning."
		CardType.DAMAGE:     return "Your weapon hits harder every shot."
		CardType.FIRE_RATE:  return "Shoot 25% faster. Stacks with other fire rate bonuses."
	return ""


# ── Input ─────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).keycode:
			KEY_1: _on_card_chosen(0)
			KEY_2: _on_card_chosen(1)
			KEY_3: _on_card_chosen(2)


# ── Apply Logic ───────────────────────────────────────────────────────────────

func _on_card_chosen(index: int) -> void:
	if index >= _current_offers.size():
		return
	_apply_offer(_current_offers[index])
	visible = false
	get_tree().paused = false
	# Signal to anyone listening (e.g. WaveManager) that the card screen is done
	cards_dismissed.emit()


func _apply_offer(offer: Dictionary) -> void:
	var card_type: CardType = offer["card_type"]

	match card_type:
		CardType.MAX_HEALTH:
			# Raise max health and immediately heal by the same amount
			if _player:
				var health := _player.get_node_or_null("HealthSystem")
				if health:
					health.max_health += 20
					health.heal(20)

		CardType.MOVE_SPEED:
			# Directly bump the player's movement speed variable
			if _player:
				_player.move_speed += 30

		CardType.DAMAGE:
			# Tell the WeaponController to increase bullet damage
			if _weapon:
				_weapon.upgrade_damage(10)

		CardType.FIRE_RATE:
			# 1.25 means 25% faster — WeaponController handles the math
			if _weapon:
				_weapon.upgrade_fire_rate(1.25)

		CardType.SPELL_NEW, CardType.SPELL_UPGRADE:
			_apply_spell_card(offer["spell_id"])


func _apply_spell_card(spell_id: String) -> void:
	if _spell_controller == null:
		return

	var spell := SpellTreeData.get_spell(spell_id)
	if spell == null:
		return

	# If there's an open hotbar slot, equip it there directly.
	# equip_spell() handles both registering the spell as unlocked
	# and placing it in the first empty slot.
	if _spell_controller.equipped_count() < SpellController.MAX_SPELL_SLOTS:
		_spell_controller.equip_spell(spell)
		return

	# All 3 slots are full — replace slot 0 as a safe fallback.
	# A future "slot picker" panel can let the player choose which slot to swap.
	# For now this keeps things working without crashing.
	_spell_controller.replace_spell(0, spell)
	# Make sure the spell is also registered as unlocked
	if not _spell_controller.is_unlocked(spell_id):
		_spell_controller.unlocked_spell_ids.append(spell_id)
