extends Resource

# ─────────────────────────────────────────────
# WeaponData — Resource Definition
#
# Defines a weapon's base stats.
# Create one .tres per weapon in resources/items/weapons/
# (e.g. pistol.tres, shotgun.tres, laser.tres)
#
# WeaponController reads this at runtime to configure itself.
#
# One .tres = one gun "profile" (sprite crop + stats). Duplicate a .tres per gun;
# the shop / DevDebug equip / apply_from_weapon_data swaps profiles at runtime — no new game scene.
# ─────────────────────────────────────────────

class_name WeaponData

# ── Identity ──
@export var weapon_name: String = "Unknown Weapon"
@export var description: String = ""
@export var icon: Texture2D = null                   # Shop / inventory icon
@export var bullet_sprite: Texture2D = null          # Projectile art (wired to Bullet when firing)

# ── Shop ──
@export var cost: int = 75
@export var is_unlocked: bool = true

## Paste scratch-tool clipboard here (one .tres per gun — there is no single “all guns” field).
@export_group("Sprite crop (weapons.png)")
## On: paste Rect2 into Sprite Region Rect below. Off: use Spritesheet Cell Index (2×33×32 grid).
@export var use_sprite_region_rect: bool = false
@export var sprite_region_rect: Rect2 = Rect2(0, 0, 33, 32)
@export_range(0, 43) var spritesheet_cell_index: int = 0
@export var weapon_sprite_scale: Vector2 = Vector2(1.3, 1.3)

# ── Combat Stats ──
@export var damage: int = 20                         # Damage per bullet
@export var fire_rate: float = 1.0                   # Shots per second
@export var bullet_speed: float = 400.0              # Pixels per second
@export var bullet_lifetime: float = 2.0             # Seconds before bullet despawns
@export var detection_range: float = 300.0           # Max range to lock on to enemies
@export var projectile_count: int = 1                # Bullets per shot (future: shotgun)
@export var spread_angle: float = 0.0               # Degrees of random spread (0 = perfectly accurate)

# ── Scaling ──
# Multipliers applied when the weapon is upgraded in the shop
@export var damage_scale: float = 1.15               # +15% damage per upgrade
@export var fire_rate_scale: float = 1.1             # +10% fire rate per upgrade
