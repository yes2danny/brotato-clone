extends Node

# ─────────────────────────────────────────────
# XPSystem — Autoload Singleton
# Tracks the player's XP and level globally.
# Any script can call XPSystem.add_xp(amount) to give the player XP.
# ─────────────────────────────────────────────

## If true, leveling pauses the game and opens UpgradeManager (pick-a-buff cards).
## If false, level and XP bar still advance — no overlay, no pause.
const SHOW_LEVEL_UP_UPGRADE_CARDS := true

var current_xp: int = 0
var current_level: int = 1
# XP needed for level 2. Raised from 20 → 100 so a wave has ~1-2 level-ups
# instead of 3+ in the first 15 seconds. Each gem gives 5 XP so this means
# you need to collect ~20 gems before your first card offer.
var xp_to_next_level: int = 100

# Signals so the UI can update whenever XP or level changes
signal xp_changed(current: int, required: int)
signal level_up(new_level: int)


# Call when starting a new run (new game, restart, main menu → play)
func reset_run() -> void:
	current_xp = 0
	current_level = 1
	xp_to_next_level = 20
	emit_signal("xp_changed", current_xp, xp_to_next_level)


# Call this when a gem is collected
func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	current_xp += amount

	while current_xp >= xp_to_next_level:
		_level_up()
	emit_signal("xp_changed", current_xp, xp_to_next_level)


func _level_up() -> void:
	# Carry over any overflow XP (e.g. got 25 XP when only 20 was needed → keep 5)
	current_xp -= xp_to_next_level
	current_level += 1

	# Each level requires 30% more XP than the last (up from 20%).
	# This keeps late-game level-ups feeling hard to earn — by wave 10+
	# you're grinding toward each card rather than getting them every minute.
	xp_to_next_level = maxi(int(roundf(float(xp_to_next_level) * 1.3)), xp_to_next_level + 1)

	emit_signal("level_up", current_level)

	if not SHOW_LEVEL_UP_UPGRADE_CARDS:
		return
	# Tell the UpgradeManager to show the upgrade cards and pause the game.
	# We use call_deferred so the signal fully finishes before pausing.
	# UpgradeManager must be in the scene tree for this to work.
	var upgrade_manager = get_tree().get_first_node_in_group("upgrade_manager")
	if upgrade_manager:
		upgrade_manager.show_upgrades()
