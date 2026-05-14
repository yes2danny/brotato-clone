extends Resource

# ─────────────────────────────────────────────
# ShopItem — Runtime Shop Slot
#
# This represents ONE slot in the shop during a between-wave break.
# It wraps either an ItemData or WeaponData, tracks price,
# and whether it's already been purchased this round.
#
# ShopManager creates an array of these each wave and
# passes them to ShopUI to display.
# ─────────────────────────────────────────────

class_name ShopItem

# The actual item or weapon being sold.
# Only ONE of these should be set per ShopItem.
var item_data: ItemData = null
var weapon_data: WeaponData = null

# Runtime state
var is_purchased: bool = false
var is_locked: bool = false   # Future: player can "lock" an item to keep it next wave (like Brotato)
## Filler card when no ItemData/WeaponData is assigned — clickable for layout tests only.
var is_placeholder: bool = false

# Computed at creation time
var display_name: String = ""
var display_description: String = ""
var display_icon: Texture2D = null
var price: int = 0
var rarity: int = ItemData.Rarity.COMMON


# Call this after setting item_data or weapon_data to populate display fields
func setup_from_item(data: ItemData) -> void:
	item_data = data
	display_name = data.item_name
	display_description = data.description
	display_icon = data.icon
	price = data.cost
	rarity = data.rarity


func setup_from_weapon(data: WeaponData) -> void:
	weapon_data = data
	display_name = data.weapon_name
	display_description = data.description
	display_icon = data.icon
	price = data.cost


# Returns true if this is a weapon slot (vs a passive item slot)
func is_weapon() -> bool:
	return weapon_data != null
