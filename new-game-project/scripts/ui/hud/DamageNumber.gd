extends Node2D

# ─────────────────────────────────────────────
# DamageNumber
#
# A single floating damage number that pops up when an entity takes damage.
# Spawned by the DamageNumbers autoload — you don't place this manually.
#
# HOW IT WORKS:
#   1. DamageNumbers.spawn() creates this node and calls setup() with the damage amount.
#   2. The node is added to the scene at the enemy's world position.
#   3. Each frame it floats upward, then fades out and deletes itself.
#
# No .tscn scene file is needed — the Label child is built entirely in code.
# ─────────────────────────────────────────────

# ── Tuning constants ──────────────────────────
const LIFETIME: float       = 0.75   # Total seconds before disappearing
const FLOAT_SPEED: float    = 55.0   # Pixels per second it drifts upward
const FADE_START_AT: float  = 0.45   # Fraction of LIFETIME when fading begins (0–1)
const FONT_SIZE_NORMAL: int = 16     # Font size for regular hits
const FONT_SIZE_CRIT: int   = 22     # Font size for critical hits (bigger = more dramatic)

# ── State ─────────────────────────────────────
var _amount: int    = 0
var _color: Color   = Color.WHITE
var _font_size: int = FONT_SIZE_NORMAL
var _time: float    = 0.0
var _label: Label   = null


## Call this right after creating the node, before adding it to the scene.
## amount   — damage dealt (after armor reduction)
## color    — text color (white for normal, yellow for crit, green for heal)
## is_crit  — if true, uses a larger font size for extra drama
func setup(amount: int, color: Color = Color.WHITE, is_crit: bool = false) -> void:
	_amount    = amount
	_color     = color
	_font_size = FONT_SIZE_CRIT if is_crit else FONT_SIZE_NORMAL


func _ready() -> void:
	# Build the Label child purely in code — no scene file needed
	_label = Label.new()
	_label.text = str(_amount)

	# Style overrides: these apply per-node so they don't affect other Labels
	_label.add_theme_color_override("font_color", _color)
	_label.add_theme_font_size_override("font_size", _font_size)

	# Center the text horizontally around this node's origin
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER

	# Add outline so numbers are readable over any background
	_label.add_theme_constant_override("outline_size", 3)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)

	add_child(_label)


func _process(delta: float) -> void:
	_time += delta

	# Float upward — negative Y is up in Godot's coordinate system
	position.y -= FLOAT_SPEED * delta

	# Fade out during the tail end of the lifetime
	var fade_start: float = LIFETIME * FADE_START_AT
	if _time >= fade_start:
		# Goes from 1.0 (fully visible) to 0.0 (invisible) over the fade window
		var fade_progress: float = (_time - fade_start) / (LIFETIME - fade_start)
		modulate.a = clampf(1.0 - fade_progress, 0.0, 1.0)

	# Self-destruct once the lifetime is over
	if _time >= LIFETIME:
		queue_free()
