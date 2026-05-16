extends Node

# ─────────────────────────────────────────────
# PoolState — Autoload Singleton
#
# Single source of truth for the **currently active enemy pool**.
# Starts empty at run start. Each wave applies a delta:
#   - `pool_additions` (Array[WaveSpawnEntry]) — upsert by scene path.
#       New scene → appended. Existing scene → replaced (weight / cap update).
#   - `pool_removals` (Array[PackedScene]) — retire any entry whose
#       `enemy_scene.resource_path` matches.
#
# EnemySpawner reads from `active_pool` instead of pulling the full list
# out of every WaveData. This means adding or retiring a type now touches
# **one wave file**, not all subsequent ones.
#
# Legacy fallback: if a wave file has both deltas empty AND populates the
# old `enemy_pool` field, that array is treated as a hard reset of the pool.
# Keeps older / hand-authored wave files functional.
# ─────────────────────────────────────────────

# Live pool, in insertion order. Read by EnemySpawner.
var active_pool: Array[WaveSpawnEntry] = []

# Last wave number the pool was advanced to (0 = before wave 1).
var current_wave: int = 0

## Emitted after every successful `apply_wave()` (including the initial wave 1
## bootstrap and any wave that produces no net change). `added` and `removed`
## are the *delta* relative to the previous state — useful for logging/UI.
signal pool_changed(active_pool: Array, added: Array, removed: Array)

## Emitted by `reset()` so listeners can re-sync at run start.
signal pool_reset


## Wipe the active pool. Call from `GameManager.begin_new_run()` so a new run
## starts from a clean slate regardless of where the prior run ended.
func reset() -> void:
	active_pool.clear()
	current_wave = 0
	emit_signal("pool_reset")
	emit_signal("pool_changed", _snapshot(), [], [])


## Apply one wave's pool deltas. Safe to call with a null WaveData
## (no-op except for advancing `current_wave`).
##
## Returns the new active pool (caller may ignore — it's also on `active_pool`).
func apply_wave(data: WaveData, wave_number: int) -> Array[WaveSpawnEntry]:
	current_wave = wave_number

	if data == null:
		emit_signal("pool_changed", _snapshot(), [], [])
		return active_pool

	var added: Array[WaveSpawnEntry] = []
	var removed: Array[WaveSpawnEntry] = []

	var has_deltas: bool = (not data.pool_additions.is_empty()) or (not data.pool_removals.is_empty())
	var legacy_full_pool: bool = (not has_deltas) and (not data.enemy_pool.is_empty())

	if legacy_full_pool:
		# Old-format wave file: treat `enemy_pool` as a full replacement.
		for entry in active_pool:
			if entry != null:
				removed.append(entry)
		active_pool.clear()
		for entry in data.enemy_pool:
			if entry == null or entry.enemy_scene == null:
				continue
			active_pool.append(entry)
			added.append(entry)
	else:
		# Apply removals first so an "add then remove" in the same wave
		# (rare) collapses to nothing instead of keeping the addition.
		for scene in data.pool_removals:
			if scene == null:
				continue
			var path: String = scene.resource_path
			if path.is_empty():
				continue
			for i in range(active_pool.size() - 1, -1, -1):
				var existing: WaveSpawnEntry = active_pool[i]
				if existing == null or existing.enemy_scene == null:
					continue
				if existing.enemy_scene.resource_path == path:
					removed.append(existing)
					active_pool.remove_at(i)

		# Upsert additions: same scene path → replace in place (weight / cap update).
		# Otherwise append.
		for entry in data.pool_additions:
			if entry == null or entry.enemy_scene == null:
				continue
			var path: String = entry.enemy_scene.resource_path
			var replaced: bool = false
			for i in range(active_pool.size()):
				var existing: WaveSpawnEntry = active_pool[i]
				if existing == null or existing.enemy_scene == null:
					continue
				if existing.enemy_scene.resource_path == path:
					active_pool[i] = entry
					replaced = true
					break
			if not replaced:
				active_pool.append(entry)
				added.append(entry)

	emit_signal("pool_changed", _snapshot(), added.duplicate(), removed.duplicate())
	_print_summary(wave_number, added, removed)
	return active_pool


## Read-only view of the active pool. Safe for spawners to iterate.
func get_pool() -> Array[WaveSpawnEntry]:
	return active_pool


func get_pool_size() -> int:
	return active_pool.size()


## True if any active entry's scene has the given `resource_path`.
func has_scene_path(scene_path: String) -> bool:
	if scene_path.is_empty():
		return false
	for entry in active_pool:
		if entry == null or entry.enemy_scene == null:
			continue
		if entry.enemy_scene.resource_path == scene_path:
			return true
	return false


## Human-readable dump — handy for DevDebug / logs.
func describe() -> String:
	if active_pool.is_empty():
		return "(empty pool, wave %d)" % current_wave
	var parts: Array[String] = []
	for entry in active_pool:
		if entry == null or entry.enemy_scene == null:
			continue
		var entry_name: String = entry.enemy_scene.resource_path.get_file().get_basename()
		var cap_text: String = ""
		if entry.max_alive > 0:
			cap_text = " cap=%d" % entry.max_alive
		parts.append("%s@%.0f%s" % [entry_name, entry.weight, cap_text])
	return "wave %d → [%s]" % [current_wave, ", ".join(parts)]


func _snapshot() -> Array[WaveSpawnEntry]:
	return active_pool.duplicate()


func _print_summary(wave_number: int, added: Array, removed: Array) -> void:
	if added.is_empty() and removed.is_empty():
		return
	var add_names: Array[String] = []
	for e in added:
		if e and e.enemy_scene:
			add_names.append(e.enemy_scene.resource_path.get_file().get_basename())
	var rem_names: Array[String] = []
	for e in removed:
		if e and e.enemy_scene:
			rem_names.append(e.enemy_scene.resource_path.get_file().get_basename())
	print("[PoolState] wave %d  +[%s]  -[%s]  → size=%d"
		% [wave_number, ", ".join(add_names), ", ".join(rem_names), active_pool.size()])
