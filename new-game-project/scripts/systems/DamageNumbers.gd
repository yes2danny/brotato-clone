extends Node

# ─────────────────────────────────────────────
# DamageNumbers — Autoload Singleton
#
# A global helper that spawns floating damage numbers anywhere in the world.
# Any script can call:   DamageNumbers.spawn(global_position, amount)
# For heals:             DamageNumbers.spawn_heal(global_position, amount)
#
# HOW TO REGISTER AS AN AUTOLOAD (one-time setup in Godot):
#   1. Go to Project → Project Settings → Autoload tab
#   2. Click the folder icon and select this file:
#      res://scripts/systems/DamageNumbers.gd
#   3. Set the Node Name to:  DamageNumbers
#   4. Click Add — it will now be accessible from any script as DamageNumbers
# ─────────────────────────────────────────────

# Preload the DamageNumber script so we can instantiate it efficiently.
# (Using a script directly avoids needing a .tscn scene file.)
const DamageNumberScript = preload("res://scripts/ui/hud/DamageNumber.gd")

# ── Color palette ─────────────────────────────
# These are the colors used for different kinds of number popups.
const COLOR_NORMAL: Color = Color(1.0, 1.0, 1.0)      # White  — standard damage
const COLOR_CRIT:   Color = Color(1.0, 0.85, 0.1)     # Yellow — critical hits
const COLOR_HEAL:   Color = Color(0.35, 1.0, 0.45)    # Green  — healing / pickups


## Spawn a damage number at a world position.
##
## world_pos  — the enemy's global_position (world space, not screen space)
## amount     — damage dealt after armor reduction (comes from HealthSystem.damage_taken signal)
## is_crit    — pass true for a bigger yellow number (hook up later when you add crits)
func spawn(world_pos: Vector2, amount: int, is_crit: bool = false) -> void:
	# Pick the right color: yellow for crits, white for normal hits
	var color: Color = COLOR_CRIT if is_crit else COLOR_NORMAL

	_create_number(world_pos, amount, color, is_crit)


## Spawn a green healing number (for potions, lifesteal, regen, etc.)
func spawn_heal(world_pos: Vector2, amount: int) -> void:
	_create_number(world_pos, amount, COLOR_HEAL, false)


# ── Internal ──────────────────────────────────

func _create_number(world_pos: Vector2, amount: int, color: Color, is_crit: bool) -> void:
	# Don't spawn if there's no active scene (e.g. during transitions)
	if get_tree().current_scene == null:
		return

	# Instantiate a new DamageNumber node
	var number: Node2D = DamageNumberScript.new()

	# Configure it BEFORE adding to the tree (setup() must run before _ready())
	number.setup(amount, color, is_crit)

	# Add to the current scene so it lives in world space.
	# Numbers in world space naturally stay near the enemy as the camera moves,
	# which is exactly the Brotato-style feel we want.
	get_tree().current_scene.add_child(number)

	# Position it at the enemy with a small random horizontal offset
	# so rapid hits on the same enemy don't all stack on top of each other.
	number.global_position = world_pos + Vector2(randf_range(-12.0, 12.0), -16.0)
