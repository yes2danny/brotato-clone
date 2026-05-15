extends Node

# ─────────────────────────────────────────────
# ShopManager — Placeholder
#
# Handles the between-wave shop logic.
# Runs after each wave ends and before the next starts.
#
# Responsibilities:
#   - Generate a random selection of items (and optionally weapons) to sell
#   - Track player gold
#   - Apply purchased items to the player
#   - Signal ShopUI to display the current offerings
#
# PLACEHOLDER: Full implementation comes when we build the shop scene.
# ─────────────────────────────────────────────

# All available items/weapons to pull from (set these in the Inspector
# by dragging .tres files into these arrays)
@export var available_items: Array[ItemData] = []
@export var available_weapons: Array[WeaponData] = []

# How many slots the shop shows per visit
@export var shop_slot_count: int = 4

# Starting gold for a run (most income is enemy drops + wave visit bonus)
@export var starting_gold: int = 0

var player_gold: int = 0
var free_rerolls: int = 0
var guaranteed_high_rarity_shops: int = 0
var next_shop_price_percent: float = 0.0
## True while the between-wave shop is open (game tree paused).
var is_shop_open: bool = false

# The current shop offerings this wave
var current_offerings: Array[ShopItem] = []

signal shop_opened(offerings: Array)
signal shop_rerolled(offerings: Array)
signal shop_closed()
signal gold_changed(new_amount: int)
signal rerolls_changed(new_amount: int)


func _ready() -> void:
	player_gold = starting_gold
	add_to_group("shop_manager")


# Called by WaveManager at the end of each wave
func open_shop() -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return
	# Stipend so the first shop visit can buy at least one common (~75g) after wave 1 if they collected drops.
	var wave_bonus: int = 35 + GameManager.waves_completed * 10
	add_gold(wave_bonus)
	var price_percent: float = next_shop_price_percent
	var force_high_rarity: bool = guaranteed_high_rarity_shops > 0
	current_offerings = _generate_offerings(force_high_rarity, price_percent)
	if force_high_rarity:
		guaranteed_high_rarity_shops -= 1
	next_shop_price_percent = 0.0
	is_shop_open = true
	get_tree().paused = true
	emit_signal("shop_opened", current_offerings)


func close_shop() -> void:
	if not is_shop_open:
		return
	is_shop_open = false
	get_tree().paused = false
	emit_signal("shop_closed")


func add_gold(amount: int) -> void:
	player_gold += amount
	emit_signal("gold_changed", player_gold)


func add_free_rerolls(amount: int) -> void:
	free_rerolls = maxi(0, free_rerolls + amount)
	emit_signal("rerolls_changed", free_rerolls)


func try_reroll() -> bool:
	if not is_shop_open:
		return false
	if free_rerolls <= 0:
		return false
	free_rerolls -= 1
	emit_signal("rerolls_changed", free_rerolls)
	current_offerings = _generate_offerings()
	emit_signal("shop_rerolled", current_offerings)
	return true


func _generate_offerings(force_high_rarity: bool = false, price_percent: float = 0.0) -> Array[ShopItem]:
	var offerings: Array[ShopItem] = []

	# Pool all available items and weapons together, shuffle, pick top N
	var pool: Array = []
	pool.append_array(available_items)
	pool.append_array(available_weapons)
	pool.shuffle()

	if force_high_rarity:
		var high_rarity_entries: Array = []
		for entry in pool:
			if entry is ItemData and entry.rarity >= ItemData.Rarity.RARE:
				high_rarity_entries.append(entry)
		if not high_rarity_entries.is_empty():
			var guaranteed = high_rarity_entries.pick_random()
			pool.erase(guaranteed)
			pool.push_front(guaranteed)

	for i in min(shop_slot_count, pool.size()):
		var entry = pool[i]
		var slot = ShopItem.new()

		if entry is ItemData:
			slot.setup_from_item(entry)
		elif entry is WeaponData:
			slot.setup_from_weapon(entry)

		_apply_price_modifier(slot, price_percent)
		offerings.append(slot)

	# Pad with placeholder cards so the layout always fills the row
	var ph_index := 0
	while offerings.size() < shop_slot_count:
		var ph := ShopItem.new()
		ph.is_placeholder = true
		ph.display_name = "Mystery wares"
		ph.display_description = "Assign ItemData resources on ShopManager to replace these."
		ph.price = 15 + ph_index * 10
		_apply_price_modifier(ph, price_percent)
		ph_index += 1
		offerings.append(ph)

	return offerings


func _apply_price_modifier(slot: ShopItem, price_percent: float) -> void:
	if price_percent == 0.0:
		return
	slot.price = maxi(1, int(roundf(float(slot.price) * (1.0 + price_percent))))


# Called when the player clicks Buy on a shop slot
func try_purchase(slot: ShopItem) -> bool:
	if slot.is_purchased:
		return false
	if slot.is_placeholder:
		print("[Shop] Placeholder slot — hook real ItemData later.")
		return false
	if player_gold < slot.price:
		return false  # Can't afford it

	player_gold -= slot.price
	slot.is_purchased = true
	emit_signal("gold_changed", player_gold)

	_apply_to_player(slot)
	return true


func _apply_to_player(slot: ShopItem) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	if slot.item_data:
		var health = player.get_node_or_null("HealthSystem")
		var item = slot.item_data

		if health and item.bonus_max_health != 0:
			if health.has_method("add_max_health"):
				health.add_max_health(item.bonus_max_health, item.bonus_max_health > 0)
			else:
				health.max_health = maxi(1, health.max_health + item.bonus_max_health)
				if item.bonus_max_health > 0:
					health.heal(item.bonus_max_health)

		if health and item.bonus_max_health_percent != 0.0:
			var max_health_delta: int = int(roundf(float(health.max_health) * item.bonus_max_health_percent))
			if max_health_delta == 0:
				max_health_delta = 1 if item.bonus_max_health_percent > 0.0 else -1
			if health.has_method("add_max_health"):
				health.add_max_health(max_health_delta, max_health_delta > 0)
			else:
				health.max_health = maxi(1, health.max_health + max_health_delta)
				if max_health_delta > 0:
					health.heal(max_health_delta)

		if item.bonus_move_speed != 0:
			player.move_speed += item.bonus_move_speed

		if item.bonus_pickup_radius != 0:
			player.pickup_radius_bonus += item.bonus_pickup_radius

		if item.bonus_gold != 0:
			add_gold(item.bonus_gold)

		if item.bonus_free_rerolls != 0:
			add_free_rerolls(item.bonus_free_rerolls)

		if item.bonus_delayed_departure != 0 and player.has_method("add_delayed_departure"):
			player.add_delayed_departure(item.bonus_delayed_departure)

		if item.mystery_box_rolls > 0:
			_apply_mystery_box(player, health, item.mystery_box_rolls)

		if item.bonus_guaranteed_high_rarity_shops != 0:
			guaranteed_high_rarity_shops = maxi(0, guaranteed_high_rarity_shops + item.bonus_guaranteed_high_rarity_shops)

		if item.bonus_next_shop_price_percent != 0.0:
			next_shop_price_percent += item.bonus_next_shop_price_percent

		var weapon = player.get_node_or_null("WeaponController")
		if weapon:
			if item.bonus_damage > 0:
				weapon.upgrade_damage(item.bonus_damage)
			if item.bonus_fire_rate != 0:
				weapon.upgrade_fire_rate(1.0 + item.bonus_fire_rate)

		if health:
			if item.bonus_armor != 0:
				health.armor += item.bonus_armor
			if item.bonus_shield_hits > 0 and health.has_method("add_shield_hits"):
				health.add_shield_hits(item.bonus_shield_hits)

	elif slot.weapon_data:
		var weapon := player.get_node_or_null("WeaponController")
		if weapon and weapon.has_method("apply_from_weapon_data"):
			weapon.apply_from_weapon_data(slot.weapon_data)
		else:
			print("Weapon purchased: ", slot.weapon_data.weapon_name)


func _apply_mystery_box(player: Node, health: Node, rolls: int) -> void:
	for i in range(maxi(1, rolls)):
		_apply_random_mystery_positive(player, health)
		_apply_random_mystery_negative(player, health)


func _apply_random_mystery_positive(player: Node, health: Node) -> void:
	var weapon = player.get_node_or_null("WeaponController")
	var options: Array[String] = ["gold", "speed", "pickup"]
	if health:
		options.append_array(["health", "armor", "shield"])
	if weapon:
		options.append_array(["damage", "fire_rate"])

	match options.pick_random():
		"health":
			health.add_max_health(15, true)
		"speed":
			player.move_speed += 20.0
		"pickup":
			player.pickup_radius_bonus += 60.0
		"shield":
			if health.has_method("add_shield_hits"):
				health.add_shield_hits(1)
		"armor":
			health.armor += 1
		"damage":
			weapon.upgrade_damage(6)
		"fire_rate":
			weapon.upgrade_fire_rate(1.15)
		"gold":
			add_gold(25)


func _apply_random_mystery_negative(player: Node, health: Node) -> void:
	var weapon = player.get_node_or_null("WeaponController")
	var options: Array[String] = ["gold", "speed", "pickup"]
	if health:
		options.append_array(["health", "armor"])
	if weapon:
		options.append_array(["damage", "fire_rate"])

	match options.pick_random():
		"health":
			var delta: int = int(roundf(float(health.max_health) * -0.08))
			if delta == 0:
				delta = -1
			health.add_max_health(delta, false)
		"speed":
			player.move_speed = maxf(40.0, player.move_speed - 15.0)
		"pickup":
			player.pickup_radius_bonus = maxf(-120.0, player.pickup_radius_bonus - 40.0)
		"armor":
			health.armor = maxi(0, health.armor - 1)
		"damage":
			weapon.upgrade_damage(-4)
		"fire_rate":
			weapon.upgrade_fire_rate(0.9)
		"gold":
			var loss: int = mini(20, player_gold)
			player_gold -= loss
			emit_signal("gold_changed", player_gold)
