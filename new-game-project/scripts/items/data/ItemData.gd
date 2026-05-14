extends Resource

# ─────────────────────────────────────────────
# ItemData — Resource Definition
#
# Defines a passive item that the player can buy in the shop
# or pick up in the world. Create one .tres per item in
# resources/items/passive/ or resources/items/weapons/.
#
# HOW TO USE:
#   1. Right-click resources/items/passive/ → New Resource → ItemData
#   2. Fill in stats in the Inspector
#   3. ShopManager reads these to populate the shop
# ─────────────────────────────────────────────

class_name ItemData

enum Rarity { COMMON, UNCOMMON, RARE, LEGENDARY }

# ── Identity ──
@export var item_name: String = "Unknown Item"
@export var description: String = ""                 # Shown on the shop card
@export var icon: Texture2D = null                   # Shop card art

# ── Shop ──
@export var cost: int = 50                           # Gold cost in the shop
@export var max_stack: int = 1                       # How many the player can hold (1 = unique)
@export var is_unlocked: bool = true                 # Future: unlock system
@export var rarity: Rarity = Rarity.COMMON

# ── Stat Modifiers ──
# These are FLAT additions applied when the item is picked up.
# Set to 0 if the item doesn't affect that stat.
@export var bonus_max_health: int = 0
@export var bonus_max_health_percent: float = 0.0
@export var bonus_move_speed: float = 0.0
@export var bonus_damage: int = 0
@export var bonus_fire_rate: float = 0.0             # Multiplier added (e.g. 0.1 = +10%)
@export var bonus_armor: int = 0
@export var bonus_pickup_radius: float = 0.0         # Increases XP gem attract range
@export var bonus_gold: int = 0
@export var bonus_shield_hits: int = 0
@export var bonus_free_rerolls: int = 0
@export var bonus_delayed_departure: int = 0
@export var mystery_box_rolls: int = 0
@export var bonus_guaranteed_high_rarity_shops: int = 0
@export var bonus_next_shop_price_percent: float = 0.0

# ── Item Type ──
enum ItemType { PASSIVE, ACTIVE, CONSUMABLE }
@export var item_type: ItemType = ItemType.PASSIVE
