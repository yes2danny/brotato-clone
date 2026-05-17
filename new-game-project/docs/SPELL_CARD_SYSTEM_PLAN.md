# Spell Card Unlock System — Implementation Plan

Date: 2026-05-17

## What We're Building

A Vampire Survivors-style level-up card picker for spells. Every time the
player levels up, the game pauses and shows 3 cards. Each card is one of:

- A spell the player does not have yet (unlock it)
- A spell upgrade for a spell they already own (unlock the next tier)
- A stat boost (health, speed, damage, fire rate)

The player picks one card, it gets applied, and the game resumes. That's it.
No currencies. No mastery conditions. No separate spell tree UI needed.

## Why This Works For Our Game

- We already have `XPSystem` with a `level_up` signal
- We already have `UpgradeManager` that shows cards and pauses the game
- We already have `SpellTreeData` with prereq chains that naturally model tiers
- We already have 3 hotbar slots which creates a natural tension:
  "do I grab a new spell or upgrade what I have?"

The only things we are removing are the auto-unlock behavior in
`SpellController` and the `unlock_level` gating from `SpellTreeData`.
The spellbook tree UI can stay in the project — we just won't use it
for unlocking anymore.

---

## What Already Exists (Audit)

### XPSystem.gd
- Emits `level_up(new_level: int)` every time the player levels up
- Has `SHOW_LEVEL_UP_UPGRADE_CARDS` const set to `false` right now
- When set to `true` it calls `upgrade_manager.show_upgrades()`

### UpgradeManager.gd
- Already a working card picker UI
- Shows 4 random stat cards, player picks one
- Already pauses the game and resumes after pick
- We will expand this to include spell cards and reduce to 3 cards

### SpellController.gd
- `_on_level_up()` currently calls `SpellTreeData.get_unlocks_for_level()`
  and auto-unlocks spells silently — THIS IS WHAT WE'RE REMOVING
- `_reset_spell_progression()` also loops up to current level and
  auto-unlocks everything — THIS LOOP GETS REMOVED TOO
- `equip_spell()`, `unlocked_spell_ids`, and slot logic all stay

### SpellTreeData.gd
- 26 spells defined across 5 schools: Fire, Shock, Poison, Water, Dark/Blood
- Every spell has a `prerequisites` list already (e.g. explosive_fireball
  requires ["fireball"])
- This prereq chain is exactly what we use to build the "available" pool

---

## Phase 1 — Stop Auto-Unlocking Spells

**File: `scripts/spells/SpellController.gd`**

### Change 1: Disable the level-up auto-unlock hook

Find this in `_ready()`:
```gdscript
if not XPSystem.level_up.is_connected(_on_level_up):
    XPSystem.level_up.connect(_on_level_up)
```
Delete those lines. We no longer want `SpellController` listening to
`level_up` at all — the `UpgradeManager` will handle that instead.

### Change 2: Clean up `_reset_spell_progression()`

Find this block (near the bottom of the function):
```gdscript
for level in range(2, XPSystem.current_level + 1):
    for spell_id in SpellTreeData.get_unlocks_for_level(level):
        _unlock_spell(spell_id, true, level)
```
Delete that entire `for level` loop. The function should now just
set everything to null and equip the starting fireball. Nothing else.

After these two changes the player starts with only fireball, and leveling
up does NOT auto-give any new spells. The card picker will take over that job.

**What `_reset_spell_progression()` should look like after the edit:**
```gdscript
func _reset_spell_progression() -> void:
    unlocked_spell_ids.clear()
    for i in MAX_SPELL_SLOTS:
        equipped_spells[i] = null
        _cooldowns[i] = 0.0

    var initial_spell_id := starting_spell_id
    var initial_spell := SpellTreeData.get_spell(initial_spell_id)
    if initial_spell == null and starting_spell != null:
        initial_spell = starting_spell
        initial_spell_id = _spell_id_for(starting_spell)

    if initial_spell != null:
        _unlock_spell_resource(initial_spell_id, initial_spell, 1, true, false)

    loadout_changed.emit()
```

---

## Phase 2 — Turn On The Card Picker

**File: `scripts/systems/XPSystem.gd`**

Change:
```gdscript
const SHOW_LEVEL_UP_UPGRADE_CARDS := false
```
To:
```gdscript
const SHOW_LEVEL_UP_UPGRADE_CARDS := true
```

That's the only change needed here. The existing `_level_up()` function
already calls `upgrade_manager.show_upgrades()` when this is true.

---

## Phase 3 — Rebuild UpgradeManager With Spell Cards

This is the main work. We are replacing the current 4-stat-card logic with
a smarter 3-card system that mixes spells and stats.

**File: `scripts/systems/UpgradeManager.gd`**

### New Card Type Enum

Replace the current enum:
```gdscript
enum UpgradeType {
    MAX_HEALTH,
    MOVE_SPEED,
    DAMAGE,
    FIRE_RATE
}
```

With this expanded version:
```gdscript
enum UpgradeType {
    # Stat cards
    MAX_HEALTH,
    MOVE_SPEED,
    DAMAGE,
    FIRE_RATE,
    # Spell cards — these store extra data (see _current_offers)
    SPELL_NEW,    # A spell the player does not have yet
    SPELL_UPGRADE # A spell that upgrades one they already own (next tier in chain)
}
```

### New Variables

Add these at the top alongside `_player` and `_weapon`:
```gdscript
var _spell_controller: SpellController = null

# Each offer entry is a Dictionary:
#   { "type": UpgradeType, "spell_id": String (only set for SPELL cards) }
# Using a Dictionary instead of a plain UpgradeType lets us attach
# the spell id to a card without a separate parallel array.
var _current_offers: Array[Dictionary] = []
```

### New: `_get_available_spell_ids()` Helper

Add this new function. It asks SpellTreeData for all spells and returns only
the ones the player can unlock right now (all prerequisites met, not already
owned). This is how we build the spell card pool.

```gdscript
# Returns spell IDs where all prerequisites are already unlocked
# and the spell itself is not yet owned by the player.
func _get_available_spell_ids() -> Array[String]:
    if _spell_controller == null:
        return []

    var available: Array[String] = []
    var all_spells := SpellTreeData.get_spell_definitions()

    for spell_id in all_spells.keys():
        # Skip spells the player already has
        if _spell_controller.is_unlocked(spell_id):
            continue

        # Check every prerequisite is already unlocked
        var spell_def: Dictionary = SpellTreeData.get_spell_definition(spell_id)
        var prereqs: Array = spell_def.get("prerequisites", [])
        var prereqs_met := true
        for prereq_id in prereqs:
            if not _spell_controller.is_unlocked(prereq_id):
                prereqs_met = false
                break

        if prereqs_met:
            available.append(spell_id)

    return available
```

### New: `_build_offer_pool()` Function

This builds the 3 card offers for a level up:
```gdscript
# Builds a list of 3 card offers, mixing spell cards and stat cards.
# Rule: always at least 1 stat card, always at least 1 spell card
# when spells are available. Shuffle to keep things fresh.
func _build_offer_pool() -> Array[Dictionary]:
    var offers: Array[Dictionary] = []

    var available_spell_ids := _get_available_spell_ids()
    available_spell_ids.shuffle()

    # Stat pool — all 4 stat types shuffled
    var stat_pool := [
        UpgradeType.MAX_HEALTH,
        UpgradeType.MOVE_SPEED,
        UpgradeType.DAMAGE,
        UpgradeType.FIRE_RATE
    ]
    stat_pool.shuffle()

    # Add up to 2 spell cards
    var spell_cards_added := 0
    for spell_id in available_spell_ids:
        if spell_cards_added >= 2:
            break
        var spell_def := SpellTreeData.get_spell_definition(spell_id)
        var prereqs: Array = spell_def.get("prerequisites", [])
        # Label it SPELL_UPGRADE if it builds on something the player has,
        # SPELL_NEW if it has no prerequisites (fresh branch starter)
        var card_type := UpgradeType.SPELL_UPGRADE if prereqs.size() > 0 else UpgradeType.SPELL_NEW
        offers.append({ "type": card_type, "spell_id": spell_id })
        spell_cards_added += 1

    # Fill remaining slots with stat cards until we have 3 total
    for stat_type in stat_pool:
        if offers.size() >= 3:
            break
        offers.append({ "type": stat_type, "spell_id": "" })

    # If we got fewer than 3 (e.g. no spells available and stat pool small),
    # just return what we have — the UI will hide unused card buttons.
    offers.shuffle()
    return offers
```

### Updated `_card_buttons` Count

Change the card count from 4 to 3 in `_build_upgrade_ui()`:
```gdscript
# Change: for i in 4  →  for i in 3
for i in 3:
    var btn := Button.new()
    ...
```

Also update the title label text:
```gdscript
title.text = "Level Up — pick one"
```

### Updated `show_upgrades()`

Replace the current `show_upgrades()` with this version:
```gdscript
func show_upgrades() -> void:
    get_tree().paused = true
    visible = true

    var players := get_tree().get_nodes_in_group("player")
    if players.size() > 0:
        _player = players[0]
        _weapon = _player.get_node_or_null("WeaponController")

    # Find SpellController — it lives on the player node
    _spell_controller = _player.get_node_or_null("SpellController") if _player else null
    # Fallback: search by group
    if _spell_controller == null:
        var controllers := get_tree().get_nodes_in_group("spell_controller")
        if not controllers.is_empty():
            _spell_controller = controllers[0]

    # Build the 3-card offer pool
    _current_offers = _build_offer_pool()

    for i in _card_buttons.size():
        if i < _current_offers.size():
            var offer: Dictionary = _current_offers[i]
            _card_buttons[i].text = _offer_label(offer)
            _card_buttons[i].tooltip_text = _offer_tooltip(offer)
            _card_buttons[i].visible = true
            _card_buttons[i].disabled = false
        else:
            _card_buttons[i].visible = false

    _card_buttons[0].grab_focus()
```

### New: `_offer_label()` Helper

This builds the text shown on each card:
```gdscript
# Returns the button label for a card offer.
func _offer_label(offer: Dictionary) -> String:
    var type: UpgradeType = offer["type"]
    match type:
        UpgradeType.MAX_HEALTH:
            return "❤ Max Health +20"
        UpgradeType.MOVE_SPEED:
            return "⚡ Move Speed +30"
        UpgradeType.DAMAGE:
            return "🗡 Bullet Damage +10"
        UpgradeType.FIRE_RATE:
            return "🔥 Fire Rate +25%"
        UpgradeType.SPELL_NEW, UpgradeType.SPELL_UPGRADE:
            var spell := SpellTreeData.get_spell(offer["spell_id"])
            if spell == null:
                return "Unknown Spell"
            var prefix := "✨ NEW: " if type == UpgradeType.SPELL_NEW else "⬆ UPGRADE: "
            return prefix + spell.spell_name
    return "???"
```

### New: `_offer_tooltip()` Helper

Shows the spell description on hover (great for learning what spells do):
```gdscript
func _offer_tooltip(offer: Dictionary) -> String:
    var type: UpgradeType = offer["type"]
    if type == UpgradeType.SPELL_NEW or type == UpgradeType.SPELL_UPGRADE:
        var spell := SpellTreeData.get_spell(offer["spell_id"])
        if spell != null:
            return spell.description
    return ""
```

### Updated `_on_upgrade_chosen()`

The current version calls `_apply_upgrade(chosen)` where `chosen` is an
UpgradeType enum. We now pass the full Dictionary instead:
```gdscript
func _on_upgrade_chosen(index: int) -> void:
    if index >= _current_offers.size():
        return

    var offer: Dictionary = _current_offers[index]
    _apply_offer(offer)

    visible = false
    get_tree().paused = false
```

### New: `_apply_offer()` (replaces `_apply_upgrade()`)

```gdscript
func _apply_offer(offer: Dictionary) -> void:
    var type: UpgradeType = offer["type"]

    match type:
        UpgradeType.MAX_HEALTH:
            if _player:
                var health = _player.get_node_or_null("HealthSystem")
                if health:
                    health.max_health += 20
                    health.heal(20)

        UpgradeType.MOVE_SPEED:
            if _player:
                _player.move_speed += 30

        UpgradeType.DAMAGE:
            if _weapon:
                _weapon.upgrade_damage(10)

        UpgradeType.FIRE_RATE:
            if _weapon:
                _weapon.upgrade_fire_rate(1.25)

        UpgradeType.SPELL_NEW, UpgradeType.SPELL_UPGRADE:
            _apply_spell_card(offer["spell_id"])
```

### New: `_apply_spell_card()`

This is where the spell actually gets unlocked and equipped:
```gdscript
func _apply_spell_card(spell_id: String) -> void:
    if _spell_controller == null:
        return

    # Unlock the spell in SpellController
    # equip_spell() handles both unlocking and finding the first open slot
    var spell := SpellTreeData.get_spell(spell_id)
    if spell == null:
        return

    # If there's an open slot, equip it directly
    if _spell_controller.equipped_count() < SpellController.MAX_SPELL_SLOTS:
        _spell_controller.equip_spell(spell)
        return

    # All 3 slots are full — for now we replace slot 0 as a safe fallback.
    # Phase 4 (see below) upgrades this to a slot-picker prompt.
    _spell_controller.replace_spell(0, spell)
    if not _spell_controller.is_unlocked(spell_id):
        _spell_controller.unlocked_spell_ids.append(spell_id)
```

### Update `_unhandled_input()` Key Bindings

Change from 4 keys to 3:
```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if not visible:
        return
    if event is InputEventKey and event.pressed and not event.echo:
        var k := (event as InputEventKey).keycode
        match k:
            KEY_1:
                _on_upgrade_chosen(0)
            KEY_2:
                _on_upgrade_chosen(1)
            KEY_3:
                _on_upgrade_chosen(2)
            # KEY_4 removed — we only have 3 cards now
```

---

## Phase 4 — Slot Picker When All Slots Are Full (Polish Step)

This is optional for the first pass but makes the system feel complete.

When `_apply_spell_card()` detects all 3 slots are full, instead of silently
replacing slot 0 it should:

1. Keep the game paused
2. Hide the card picker panel
3. Show a second small panel: "Which spell do you want to replace?"
4. Show 3 buttons, one per equipped spell (with their names)
5. Player picks → that slot gets replaced → game resumes

This is a new sub-panel added to `UpgradeManager` with its own show/hide
logic. Build it the same way `_build_upgrade_ui()` works — create nodes in
code. Wire up `_on_slot_chosen(slot_index)` which calls `replace_spell()`.

---

## Phase 5 — Starting Spell Choice (Nice To Have, Later)

Right now fireball is always the starting spell (hardcoded in
`SpellController` via `starting_spell_id = "fireball"`).

Later we can show a one-time 3-card offer at run start using the same
card picker UI. The offer would show 3 root spells (spells with no
prerequisites) for the player to pick their starting branch fantasy.

To do this:
- Call `upgrade_manager.show_upgrades()` from `_ready()` in the main
  game scene before `WaveManager` starts wave 1
- Filter `_get_available_spell_ids()` to only `prerequisites.is_empty()`
  spells for that first offer
- Do NOT give fireball by default — start with empty slots and let the
  card resolve slot 0

---

## Summary: Files To Change

| File | What Changes |
|---|---|
| `scripts/spells/SpellController.gd` | Remove `_on_level_up` connection; remove level loop in `_reset_spell_progression()` |
| `scripts/systems/XPSystem.gd` | Set `SHOW_LEVEL_UP_UPGRADE_CARDS` to `true` |
| `scripts/systems/UpgradeManager.gd` | Full rewrite of card logic (new enums, spell pool builder, new apply function) |

## Files We Are NOT Touching

| File | Why |
|---|---|
| `SpellTreeData.gd` | All 26 spells and their prereq chains stay as-is — we reuse them |
| `WaveManager.gd` | Between-wave shop flow is unchanged |
| `GameManager.gd` | No changes needed |
| `SpellTreeUI.gd` | Spellbook UI can stay in the project unused for now |
| `XPSystem.gd` (signals) | `level_up` signal already does exactly what we need |

---

## Recommended Build Order

1. Phase 1 — stop auto-unlocking (10 min, 2 small edits)
2. Phase 2 — flip the card picker on (1 line change)
3. Phase 3 — rebuild UpgradeManager (the main coding session)
4. Test: level up, pick a spell, verify it appears in hotbar
5. Phase 4 — slot picker when full (next session)
6. Phase 5 — starting spell choice (later session)

## What This Replaces

The old `SPELL_BRANCH_UNLOCK_PLAN.md` described a two-currency, mastery-
condition, permanent-unlock system. That plan is good design but too complex
for our current scope. This plan gives us 80% of the fun for 20% of the work
by leaning on systems we already have.
