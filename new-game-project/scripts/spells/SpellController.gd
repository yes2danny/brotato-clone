extends Node
class_name SpellController

const MAX_SPELL_SLOTS: int = 3

@export var starting_spell_id: String = "fireball"
@export var starting_spell: SpellData

var equipped_spells: Array = [null, null, null]
var unlocked_spell_ids: Array[String] = []
var _cooldowns: Array[float] = [0.0, 0.0, 0.0]

signal spell_cast(slot_index: int, spell: SpellData)
signal spell_unlocked(spell_id: String, spell: SpellData, unlock_level: int)
signal loadout_changed


func _ready() -> void:
	add_to_group("spell_controller")
	# NOTE: We no longer connect to XPSystem.level_up here.
	# Spell unlocks now happen through the UpgradeManager card picker,
	# which fires when the player levels up and offers 3 cards to choose from.
	_reset_spell_progression()


func _process(delta: float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return
	for i in MAX_SPELL_SLOTS:
		if _cooldowns[i] > 0.0:
			_cooldowns[i] = maxf(0.0, _cooldowns[i] - delta)


func request_cast_slot(slot: int) -> bool:
	if GameManager.state != GameManager.GameState.PLAYING:
		return false
	if slot < 0 or slot >= MAX_SPELL_SLOTS:
		return false
	var spell: SpellData = equipped_spells[slot]
	if spell == null or _cooldowns[slot] > 0.0:
		return false
	return _try_cast(slot, spell)


func equip_spell(spell: SpellData) -> bool:
	if spell == null:
		return false
	var spell_id := _spell_id_for(spell)
	if spell_id.is_empty():
		return _equip_resource_to_first_open_slot(spell)
	if not is_unlocked(spell_id):
		unlocked_spell_ids.append(spell_id)
	return equip_spell_to_slot(spell_id, _first_open_slot())


func equip_spell_to_slot(spell_id: String, slot: int) -> bool:
	if slot < 0 or slot >= MAX_SPELL_SLOTS:
		return false
	if not is_unlocked(spell_id):
		return false
	var spell := SpellTreeData.get_spell(spell_id)
	if spell == null:
		return false

	var existing_slot := get_equipped_slot(spell_id)
	if existing_slot == slot:
		return true
	if existing_slot >= 0:
		equipped_spells[existing_slot] = null
		_cooldowns[existing_slot] = 0.0

	equipped_spells[slot] = spell
	_cooldowns[slot] = 0.0
	loadout_changed.emit()
	return true


func replace_spell(slot: int, new_spell: SpellData) -> void:
	if slot < 0 or slot >= MAX_SPELL_SLOTS or new_spell == null:
		return
	var spell_id := _spell_id_for(new_spell)
	if not spell_id.is_empty() and not is_unlocked(spell_id):
		unlocked_spell_ids.append(spell_id)
	equipped_spells[slot] = new_spell
	_cooldowns[slot] = 0.0
	loadout_changed.emit()


func remove_spell(slot: int) -> void:
	if slot < 0 or slot >= MAX_SPELL_SLOTS:
		return
	equipped_spells[slot] = null
	_cooldowns[slot] = 0.0
	loadout_changed.emit()


func equipped_count() -> int:
	var count := 0
	for spell in equipped_spells:
		if spell != null:
			count += 1
	return count


func is_ready(slot: int) -> bool:
	return slot >= 0 and slot < MAX_SPELL_SLOTS and _cooldowns[slot] <= 0.0


func is_unlocked(spell_id: String) -> bool:
	return unlocked_spell_ids.has(spell_id)


func is_equipped(spell_id: String) -> bool:
	return get_equipped_slot(spell_id) >= 0


func get_equipped_slot(spell_id: String) -> int:
	for i in MAX_SPELL_SLOTS:
		var spell := equipped_spells[i] as SpellData
		if spell == null:
			continue
		if _spell_id_for(spell) == spell_id:
			return i
	return -1


func get_spell_in_slot(slot: int) -> SpellData:
	if slot < 0 or slot >= MAX_SPELL_SLOTS:
		return null
	return equipped_spells[slot]


func get_unlocked_count() -> int:
	return unlocked_spell_ids.size()


func get_unlocked_spell_ids() -> Array[String]:
	return unlocked_spell_ids.duplicate()


func get_cooldown_progress(slot: int) -> float:
	var spell: SpellData = equipped_spells[slot]
	if spell == null or spell.cooldown <= 0.0:
		return 1.0
	return 1.0 - (_cooldowns[slot] / spell.cooldown)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				request_cast_slot(0)
			KEY_2:
				request_cast_slot(1)
			KEY_3:
				request_cast_slot(2)


func _try_cast(slot: int, spell: SpellData) -> bool:
	match spell.cast_type:
		SpellData.CastType.SELF_CAST:
			return _cast_self(slot, spell)
		SpellData.CastType.AUTO_TARGET:
			var target := _get_nearest_enemy(spell.detection_range)
			if target != null:
				return _cast_at_target(slot, spell, target)
			return false
		SpellData.CastType.DIRECTIONAL:
			return _cast_directional(slot, spell)
	return false


func _cast_self(slot: int, spell: SpellData) -> bool:
	if spell.spell_scene == null:
		push_warning("[SpellController] Spell '%s' has no spell_scene assigned!" % spell.spell_name)
		return false
	var player := _get_player()
	if player == null:
		return false
	var instance = spell.spell_scene.instantiate()
	instance.global_position = player.global_position
	if instance.has_method("setup"):
		instance.setup(spell)
	get_tree().current_scene.add_child(instance)
	_cooldowns[slot] = spell.cooldown
	spell_cast.emit(slot, spell)
	return true


func _cast_at_target(slot: int, spell: SpellData, target: Node2D) -> bool:
	if spell.spell_scene == null:
		push_warning("[SpellController] Spell '%s' has no spell_scene assigned!" % spell.spell_name)
		return false
	var player := _get_player()
	if player == null:
		return false
	var instance = spell.spell_scene.instantiate()
	instance.global_position = player.global_position
	if instance.has_method("setup"):
		instance.setup(spell, target)
	get_tree().current_scene.add_child(instance)
	_cooldowns[slot] = spell.cooldown
	spell_cast.emit(slot, spell)
	return true


func _cast_directional(slot: int, spell: SpellData) -> bool:
	if spell.spell_scene == null:
		push_warning("[SpellController] Spell '%s' has no spell_scene assigned!" % spell.spell_name)
		return false
	var player := _get_player()
	if player == null:
		return false
	var cast_direction := _get_directional_cast_direction(player)
	var instance = spell.spell_scene.instantiate()
	instance.global_position = player.global_position
	if instance.has_method("setup"):
		instance.setup(spell, null, cast_direction)
	get_tree().current_scene.add_child(instance)
	_cooldowns[slot] = spell.cooldown
	spell_cast.emit(slot, spell)
	return true


func _get_nearest_enemy(range_limit: float) -> Node2D:
	var player := _get_player()
	if player == null:
		return null
	var nearest: Node2D = null
	var nearest_dist: float = range_limit if range_limit > 0.0 else INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var dist: float = player.global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest


func _get_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		return players[0] as Node2D
	return null


func _get_directional_cast_direction(player: Node2D) -> Vector2:
	if player != null and player.has_method("get_last_move_direction"):
		var move_direction: Vector2 = player.get_last_move_direction()
		if move_direction.length_squared() > 0.0001:
			return move_direction.normalized()

	var weapon := player.get_node_or_null("WeaponController")
	if weapon != null and weapon.has_method("get_aim_direction"):
		var aim_direction: Vector2 = weapon.get_aim_direction()
		if aim_direction.length_squared() > 0.0001:
			return aim_direction.normalized()

	var mouse_direction := player.get_global_mouse_position() - player.global_position
	if mouse_direction.length_squared() > 64.0:
		return mouse_direction.normalized()

	return Vector2.RIGHT


func _reset_spell_progression() -> void:
	unlocked_spell_ids.clear()
	for i in MAX_SPELL_SLOTS:
		equipped_spells[i] = null
		_cooldowns[i] = 0.0

	# Give the player their starting spell (fireball by default).
	# Everything else is earned through the level-up card picker — nothing
	# auto-unlocks based on level anymore.
	var initial_spell_id := starting_spell_id
	var initial_spell := SpellTreeData.get_spell(initial_spell_id)
	if initial_spell == null and starting_spell != null:
		initial_spell = starting_spell
		initial_spell_id = _spell_id_for(starting_spell)

	if initial_spell != null:
		_unlock_spell_resource(initial_spell_id, initial_spell, 1, true, false)

	loadout_changed.emit()


func _unlock_spell(spell_id: String, auto_equip: bool, unlock_level: int) -> bool:
	if spell_id.is_empty() or is_unlocked(spell_id):
		return false
	var spell := SpellTreeData.get_spell(spell_id)
	if spell == null:
		return false
	return _unlock_spell_resource(spell_id, spell, unlock_level, auto_equip, true)


func _unlock_spell_resource(
	spell_id: String,
	spell: SpellData,
	unlock_level: int,
	auto_equip: bool,
	emit_unlock_signal: bool
) -> bool:
	var normalized_id := spell_id if not spell_id.is_empty() else _spell_id_for(spell)
	if normalized_id.is_empty():
		return false
	if is_unlocked(normalized_id):
		return false

	unlocked_spell_ids.append(normalized_id)
	if auto_equip:
		_equip_resource_to_first_open_slot(spell)
	if emit_unlock_signal:
		spell_unlocked.emit(normalized_id, spell, unlock_level)
	loadout_changed.emit()
	return true


func _equip_resource_to_first_open_slot(spell: SpellData) -> bool:
	var slot := _first_open_slot()
	if slot < 0:
		return false
	equipped_spells[slot] = spell
	_cooldowns[slot] = 0.0
	return true


func _first_open_slot() -> int:
	for i in MAX_SPELL_SLOTS:
		if equipped_spells[i] == null:
			return i
	return -1


func _spell_id_for(spell: SpellData) -> String:
	if spell == null:
		return ""
	if not spell.spell_id.is_empty():
		return spell.spell_id
	if not spell.resource_path.is_empty():
		var basename := spell.resource_path.get_file().get_basename()
		return basename.trim_prefix("spell_")
	return spell.spell_name.to_snake_case()
