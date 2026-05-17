# Spell Branch Unlock Plan

Date: 2026-05-17

## Goal

Turn the current spellbook from a mostly auto-leveling showcase into a real
progression system where:

- each branch feels like a meaningful fantasy
- late spells feel difficult and valuable
- a 20-wave run has real spell choices instead of handing out everything
- the existing Spellbook UI, hotbar, XP hooks, and between-wave shop flow can
  be reused instead of thrown away

This plan is based on the live repo state plus inspiration from other games
with strong class, specialization, or skill-unlock identity:

- Last Epoch: visible skill unlock requirements, specialization trees, and a
  limited action bar
- Guild Wars 2: elite specializations cost a dedicated currency and only one can
  be actively equipped at a time
- Path of Exile: major subclass power comes from challenge gates, not from
  ordinary leveling alone
- Final Fantasy XIV: important abilities are often attached to milestone quests,
  not just raw level
- Diablo IV: deeper branches are most satisfying when they noticeably change how
  a skill plays, not when they only add bigger numbers

Sources:

- [Last Epoch Support - Unlocking Skills](https://support.lastepoch.com/hc/en-us/articles/46363194853915-Unlocking-Skills)
- [Guild Wars 2 Support - Using Elite Specializations](https://help.guildwars2.com/hc/en-us/articles/4417183530387-Using-Elite-Specializations)
- [Path of Exile - Ascendancy Classes](https://www.pathofexile.com/ascendancy/classes)
- [FFXIV Jobs Wiki Page](https://ffxiv.consolegameswiki.com/wiki/Jobs)
- [Xbox Wire - Diablo IV Skill Tree Overhaul](https://news.xbox.com/en-us/2026/04/22/diablo-4-skill-tree-overhaul/)

## Current Repo Audit

### What exists already

- `SpellTreeData.gd` defines 26 spells across 5 visible branches plus the Blood
  side path.
- `SpellController.gd` supports 3 active spell slots and already handles manual
  casting on `1`, `2`, and `3`.
- `SpellTreeUI.gd` already draws the Spellbook and lets the player inspect and
  equip unlocked spells.
- `ShopUI.gd` already contains a Spellbook tab during the between-wave screen.
- `GameUI.gd` already shows unlock popups when a spell is unlocked.
- `XPSystem.gd` already emits `level_up`, but level-up cards are currently
  disabled.
- `GameManager.gd` already has a placeholder future meta-reward hook that can
  become the permanent spell-progression save layer later.

### Spell branches currently defined

#### Fire

- Main path: `fireball -> explosive_fireball -> pillar_fireball`
- Side spells: `ring_of_fire`, `fire_bomb`, `small_meteor`

#### Lightning

- Main path: `spark_bolt -> chain_lightning -> lightning_strike -> electric_burst -> electric_field`
- Side spell: `pulse_beam`

#### Poison

- Main path: `acid_glob -> toxic_burst -> poison_cloud -> green_vortex`

#### Water

- Main path: `water_drop -> splash_burst -> wave -> water_whirl`

#### Dark / Blood

- Main path: `dark_bolt -> void_orb -> smoke_curse -> black_hole`
- Side spells: `skull_shot`, `blood_explosion`

### What is misleading right now

- The Spellbook looks like a branching progression system, but progression is
  still mostly `reach level X -> auto unlock spell`.
- Unlock levels currently run from 1 to 26 even though the game is a 20-wave
  run and the level system is still early.
- The current implementation can technically unlock many spells in one run, but
  the player only has 3 active slots, so too many unlocks become noise instead
  of exciting decisions.
- Most spell behavior currently resolves through only 2 reusable effect scenes:
  `SpellProjectile.tscn` and `RingOfFireEffect.tscn`.
- That means several spells are functionally "same chassis, different numbers"
  even if their names imply unique fantasy.
- Only `spell_fireball.tres` and `spell_ring_of_fire.tres` exist as authored
  resources. The rest are generated from `SpellTreeData.gd`.
- A few Spellbook nodes are explicitly marked as lacking art polish:
  `chain_lightning`, `acid_glob`, and `void_orb`.

## Main Design Problems To Solve

1. A 20-wave run should not unlock all 26 spells by default.
2. The player needs branch commitment, not just branch visibility.
3. Side spells should feel earned through playstyle or milestones.
4. Tier-3 and capstone spells need stronger identity than "same spell but
   stronger."
5. The permanent unlock layer and the in-run unlock layer need to be different.

## Recommended Structure: Two Layers

The cleanest answer is to split progression into:

1. Permanent progression across many runs: "which branches can this save file
   access at all?"
2. Run progression inside one 20-wave attempt: "how far into those branches can
   this build evolve right now?"

This solves the biggest current problem: making spells feel hard to get without
making every single run take forever before anything fun happens.

## Layer 1: Permanent Branch Unlocks Across Runs

### Why this layer should exist

If every branch is available from minute 1 forever, the Spellbook becomes a
loadout screen, not a long-term reward structure. Permanent branch discovery
gives the game something exciting to unlock even before the full meta shop is
built.

### Recommended permanent branch order

#### Fire

- Status: unlocked by default
- Reason: easiest starter fantasy, already the current first spell, easiest to
  teach

#### Water

- Unlock after first time reaching Wave 6
- Reason: good second branch because it can be framed as survival/control, which
  helps newer players

#### Lightning

- Unlock after first time clearing Wave 8
- Reason: directional play asks more of the player than Fire or Water

#### Poison

- Unlock after first time clearing Wave 10
- Reason: damage-over-time / zone-control branches should appear after the
  player understands enemy flow and spacing

#### Dark

- Unlock after first time clearing Wave 15
- Reason: dark fantasy should feel like a mid-to-late-game reward, not starter
  kit

#### Blood

- Unlock after first time clearing Wave 20 with the Dark branch equipped, or
  after first reaching `smoke_curse` and then winning a Dark mastery trial
- Reason: Blood should feel forbidden, risky, and special

### What the permanent unlock should actually do

When a branch is permanently unlocked, it should:

- add that branch's root spell to the run-start draft pool
- reveal its page in the Spellbook with full color instead of "sealed" status
- unlock its icon art, descriptions, and codex entry
- optionally add cosmetic page effects or audio stingers to make the unlock feel
  important

### Save-data recommendation

Add a future `MetaProgress` or similar autoload that stores:

- `unlocked_branches`
- `branch_mastery_levels`
- `discovered_spell_ids`
- `cleared_branch_trials`

`GameManager.victory_rewards_applied` is the cleanest current place to hook this
later.

## Layer 2: In-Run Spell Progression Inside 20 Waves

### High-level rule

One run should usually produce:

- 1 fully developed primary branch
- 1 lightly developed secondary branch
- maybe 1 utility or side spell flex slot

It should not usually produce:

- all branches
- every side spell
- more than 1 capstone

That scarcity is what makes the late unlocks feel worth it.

### Recommended run structure

#### Start of run

- Offer 3 root spells chosen from permanently unlocked branches
- Player picks 1
- That chosen root becomes the "primary attunement"
- Slot 1 is filled immediately

Short-term fallback if we do not build the root draft yet:

- keep `fireball` as the default starter for one implementation pass
- only use the new rules for later branch unlocks

#### Waves 1-4: Establish identity

- Player learns the starter root
- Level-ups mostly offer stats plus one early spell-related choice
- Secondary roots should not flood in yet

Target feeling:

- "I have a build seed."
- Not: "I already have half the tree."

#### Waves 5-8: First commitment

- First milestone trial appears
- Player can either deepen the primary branch or unlock a secondary root
- Slot 2 opens if it is still closed

Target feeling:

- first real branch decision
- first hard tradeoff between depth and breadth

#### Waves 9-12: Side spell and specialization window

- Side spells start appearing if branch conditions are met
- Primary branch can reach tier 2 or tier 3
- Secondary branch should usually still be behind the primary branch

Target feeling:

- "my build is becoming mine"

#### Waves 13-16: Mastery window

- Third slot opens if still closed
- Primary branch can reach its mastery gate
- Secondary branch can grow, but not freely all the way to capstone

Target feeling:

- the player is locking in a final identity

#### Waves 17-20: Capstone window

- Capstone choice becomes available
- Only one branch should realistically capstone in a normal run
- Final waves should test the exact branch fantasy the player invested in

Target feeling:

- one signature endgame spell, not six diluted pseudo-capstones

## Recommended In-Run Economy

### Use two progression currencies

#### Arcane Pages

Earn from:

- level-ups
- elite kills
- occasional shop offers

Use for:

- unlocking a new root mid-run
- buying tier-2 upgrades
- buying side spells

#### Branch Sigils

Earn from:

- wave milestones like 5, 10, 15, and 20
- miniboss or boss clears
- rare expensive shop offer

Use for:

- opening tier-3 gates
- unlocking capstones
- buying Blood-side spells

### Suggested costs

- Starter root: free
- Secondary root: 2 Arcane Pages
- Tier-2 spell: 2 Arcane Pages
- Tier-3 spell: 3 Arcane Pages + 1 Branch Sigil
- Side spell: 2 Arcane Pages + mastery condition
- Capstone spell: 4 Arcane Pages + 2 Branch Sigils + mastery condition
- Blood spell: same as capstone-tier cost, plus Dark prerequisite

### Hard cap recommendation

- one branch can reach capstone per run
- one extra branch can usually reach tier 2 or tier 3
- third slot is mostly for utility, defense, or a side spell

This rule matters a lot. It is the difference between:

- "I built a fire run"

and:

- "I pressed every branch eventually"

## Branch-Specific Unlock Rules

These are designed to feel difficult without requiring massive new systems.
Where possible, they are based on counters we can realistically add later:

- spell kills by school
- kills at close range
- multi-kills from one cast
- wave clears while a branch is equipped
- elite or boss kills while a branch is equipped
- damage taken during a wave

### Fire branch

Role:

- direct damage, high payoff, explosive finishers

Recommended unlock path:

- `fireball`: starter root
- `explosive_fireball`: first Fire investment
- `ring_of_fire`: unlock after a close-range fire mastery condition
- `fire_bomb`: unlock after a multi-kill / crowd-clear fire condition
- `pillar_fireball`: tier-3 primary Fire evolution
- `small_meteor`: Fire capstone

Good mastery conditions:

- kill 40 enemies with Fire spells
- kill 15 enemies at close range with Fire equipped
- kill an elite with a Fire spell equipped

### Lightning branch

Role:

- speed, precision, directional skill, chained pressure

Recommended unlock path:

- `spark_bolt`: starter or secondary root
- `chain_lightning`: first Lightning evolution
- `lightning_strike`: tier-2 or tier-3 core commitment
- `pulse_beam`: side spell unlocked by aggressive directional play
- `electric_burst`: melee panic-button branch
- `electric_field`: Lightning capstone

Good mastery conditions:

- clear a wave while casting mostly directional spells
- land 60 Lightning hits in one run
- kill an elite while moving continuously through the fight

### Poison branch

Role:

- area denial, attrition, zone ownership

Recommended unlock path:

- `acid_glob`: starter or secondary root
- `toxic_burst`: close-defense unlock
- `poison_cloud`: zone-control unlock
- `green_vortex`: Poison capstone

Good mastery conditions:

- kill 50 enemies with Poison spells
- hit 20 enemies within one wave using self-cast Poison effects
- clear a wave with Poison as your most-used school

### Water branch

Role:

- survival, control, rhythmic close-range timing

Recommended unlock path:

- `water_drop`: starter or secondary root
- `splash_burst`: defensive follow-up
- `wave`: larger area-control upgrade
- `water_whirl`: Water capstone

Good mastery conditions:

- clear 2 waves with Water equipped while taking low damage
- get 30 Water spell kills in one run
- survive an elite wave with Water as your primary branch

### Dark branch

Role:

- heavy impact, cursed power, risk and payoff

Recommended unlock path:

- `dark_bolt`: root
- `void_orb`: heavy projectile evolution
- `smoke_curse`: mastery gate
- `black_hole`: Dark capstone

Good mastery conditions:

- defeat an elite while Dark is equipped
- clear a wave below 60 percent health
- get 25 Dark kills during one high-pressure wave window

### Blood side path

Role:

- dangerous reward, brutal payoff, should feel forbidden

Recommended unlock path:

- `skull_shot`: first Blood expression after Dark investment
- `blood_explosion`: Blood finisher

Blood rules:

- should not appear before the player has meaningfully committed to Dark
- should cost more than normal side spells
- should probably include some health-risk mechanic when it gets its final
  behavior pass

Good mastery conditions:

- clear a Dark trial
- win a wave while low on health
- kill an elite with Dark/Blood equipped

## Recommended Slot Rules

The 3-slot hotbar is a strength, not a weakness. Use it to force identity.

### Slot 1

- primary branch anchor
- almost always the branch that can capstone

### Slot 2

- secondary branch or branch-side tool
- usually where defensive or utility side spells live

### Slot 3

- late-game flex slot
- either a second branch helper or a capstone-support spell

Important rule:

- unlocking a spell should not always auto-equip it anymore
- the player should be prompted to choose whether it replaces something

Auto-equip is fine for the very first starter spell only.

## What Needs Unique Behavior To Feel Worth It

This is the most important content note in the whole document.

If the progression system is improved but the spells still behave like the same
projectile or the same self-centered area burst, late unlocks will still feel
fake.

### Minimum behavior pass required

#### Fire

- `small_meteor` needs a real delayed slam feel
- `fire_bomb` should feel wider and more committed than `ring_of_fire`

#### Lightning

- `chain_lightning` should actually chain, fork, or bounce
- `electric_field` should feel persistent, not just like a bigger burst

#### Poison

- `poison_cloud` should linger
- `green_vortex` should feel like a dangerous area wipe, not just a renamed
  burst

#### Water

- `wave` should travel or feel like a pushing surge
- `water_whirl` should feel sustained or rotating

#### Dark

- `void_orb` should feel weighty and ominous
- `black_hole` should pull, compress, or at least visually imply collapse

#### Blood

- `skull_shot` should feel separate from Dark projectile logic
- `blood_explosion` should have a brutal payoff and probably a visible risk

## Recommended UI / UX Flow

### Spellbook

Keep the Spellbook in the between-wave screen, but change what it communicates.

It should show:

- permanently locked branches as sealed pages
- run-locked spells as dim nodes with clear unlock reasons
- the current primary branch with a stronger highlight
- side-spell mastery conditions in plain language
- capstone requirements before the player reaches them

Examples of good lock text:

- "Reach Wave 10 once to unseal Poison."
- "Spend 1 Sigil and master Fire to unlock Pillar Fireball."
- "Clear a Dark trial to reveal Blood magic."

### Level-up / reward moments

The player should see a real decision moment when a spell becomes available.

Best version:

- re-enable `UpgradeManager`
- present mixed cards: stat cards, branch cards, side-spell cards, economy cards

Acceptable fallback:

- keep spell progression between waves only
- use the Spellbook tab plus a reward popup that grants Pages and Sigils

### Shops

The shop should not directly sell every spell. That would cheapen them.

Use shop for:

- rerolling spell offers
- buying one extra Arcane Page
- buying one rare Sigil
- buying branch-specific support items

Do not use shop for:

- instantly purchasing capstones with gold alone

## Recommended Implementation Order

### Phase 1: Progression backbone

Goal:

- stop auto-unlocking the whole tree by plain level number

Work:

- replace `unlock_level`-only logic with a real branch reward model
- stop auto-equipping every new spell
- add run currencies: Arcane Pages and Branch Sigils
- define branch root choices

Likely files:

- `scripts/spells/SpellController.gd`
- `scripts/spells/data/SpellTreeData.gd`
- `scripts/systems/XPSystem.gd`
- `scripts/systems/UpgradeManager.gd`

### Phase 2: Permanent unlock layer

Goal:

- branch discovery across many runs

Work:

- add save flags for unlocked branches
- add first-clear branch rewards tied to wave milestones
- reveal sealed Spellbook pages as they are earned

Likely files:

- future `MetaProgress` autoload
- `scripts/systems/GameManager.gd`
- `scripts/ui/menus/SpellTreeUI.gd`

### Phase 3: Spell offer UX

Goal:

- make spell unlocks feel like deliberate picks

Work:

- build run-start root draft
- build spell reward cards or between-wave Spellbook reward prompts
- add lock-reason strings to the Spellbook

Likely files:

- `scripts/systems/UpgradeManager.gd`
- `scripts/ui/menus/SpellTreeUI.gd`
- `scripts/ui/shop/ShopUI.gd`

### Phase 4: Behavior identity pass

Goal:

- make late spells feel distinct

Work:

- add unique projectile modifiers, delayed impacts, lingering zones, or pull
  logic
- split important late spells away from the fully generic effect scenes when
  needed

Likely files:

- `scripts/spells/effects/SpellProjectile.gd`
- `scripts/spells/effects/RingOfFireEffect.gd`
- new spell-specific effect scenes/scripts for capstones

### Phase 5: Art and readability pass

Goal:

- make the Spellbook honest and readable

Work:

- replace missing / placeholder art
- add proper icons for every node
- improve capstone visual framing

## Strong Recommendation

Do not try to ship all 26 spells as equally reachable in one run.

That will make the system feel shallow fast.

The better structure is:

- permanent branch discovery across many runs
- one major branch commitment per run
- one late capstone per run
- side spells earned by specific play patterns

That combination fits the current 20-wave structure, respects the 3-slot hotbar,
and gives the Spellbook a real reason to exist.

## First Implementation Slice I Would Do

If this plan is approved, the best first practical slice is:

1. Keep Fire unlocked by default.
2. Add permanent branch unlock flags for Water, Lightning, Poison, Dark, and
   Blood.
3. Replace auto-level spell unlocks with:
   - run-start root choice
   - Pages from level-ups
   - Sigils from milestone waves
4. Let only one branch capstone per run.
5. Add one real unique behavior upgrade first:
   - either `chain_lightning` actually chaining
   - or `small_meteor` actually slamming down after a short delay

That single slice would immediately make the spell system feel far more real
without requiring the entire progression feature set to be finished in one go.
