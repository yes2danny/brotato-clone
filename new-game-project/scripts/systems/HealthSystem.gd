extends Node

# ─────────────────────────────────────────────
# HealthSystem — Component Script
# Attach this as a child node to any entity that has health:
# the Player, Enemies, whatever.
# Parent node calls take_damage() / heal(), and listens to signals.
# ─────────────────────────────────────────────

@export var max_health: int = 100  # Set this in the Inspector per entity
@export var armor: int = 0         # Flat damage reduction, clamped so hits still hurt

var current_health: int = 0
var is_dead: bool = false  # Prevents death from triggering more than once
var shield_hits: int = 0
var _invulnerability_timer: float = 0.0

# Signals — the parent node (Player/Enemy) connects to these
signal health_changed(current: int, maximum: int)  # For updating UI / health bars
signal died()                                       # For triggering death logic
signal damage_taken(amount: int)                    # Fires with the ACTUAL damage dealt (after armor), used by DamageNumbers to spawn floating text


func _ready() -> void:
	# Fill to full health when the node enters the scene
	current_health = max_health


func _process(delta: float) -> void:
	if _invulnerability_timer > 0.0:
		_invulnerability_timer = maxf(_invulnerability_timer - delta, 0.0)


# Call this to deal damage to this entity.
# amount should be a positive number.
func take_damage(amount: int) -> void:
	if is_dead:
		return  # Already dead, ignore further hits
	if _invulnerability_timer > 0.0:
		return
	if shield_hits > 0:
		shield_hits -= 1
		emit_signal("health_changed", current_health, max_health)
		return

	var reduced_amount: int = maxi(1, amount - armor)
	current_health -= reduced_amount
	current_health = max(current_health, 0)  # Clamp so health never goes below 0

	emit_signal("damage_taken", reduced_amount)   # DamageNumbers listens to this to spawn a floating number
	emit_signal("health_changed", current_health, max_health)

	if current_health <= 0:
		_die()


# Call this to restore health (e.g. from a pickup or upgrade)
func heal(amount: int) -> void:
	if is_dead:
		return

	current_health += amount
	current_health = min(current_health, max_health)  # Clamp so health never exceeds max

	emit_signal("health_changed", current_health, max_health)


func add_max_health(amount: int, heal_positive_amount: bool = true) -> void:
	if is_dead:
		return
	max_health = maxi(1, max_health + amount)
	if amount > 0 and heal_positive_amount:
		current_health += amount
	current_health = clampi(current_health, 0, max_health)
	emit_signal("health_changed", current_health, max_health)


func add_shield_hits(amount: int) -> void:
	shield_hits += maxi(0, amount)
	emit_signal("health_changed", current_health, max_health)


func start_invulnerability(duration: float) -> void:
	_invulnerability_timer = maxf(_invulnerability_timer, duration)


# Internal — fires the died signal and flags this entity as dead
func _die() -> void:
	is_dead = true
	emit_signal("died")
