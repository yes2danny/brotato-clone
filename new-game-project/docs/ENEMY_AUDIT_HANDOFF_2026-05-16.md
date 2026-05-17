# Enemy Audit Handoff — 2026-05-16

> **Status as of 2026-05-16 afternoon:** All three blocking decisions from the original audit are now **locked and applied**. The roadmap is safe to continue from.
>
> **Late update on the same date:** Waves 6-9 have since been wired much further locally than the original backlog table implied. The early-wave backlog below now reflects that newer live state.

Purpose: reconcile the current live enemy implementation with the newer v3 roadmap before wiring more waves.

## Executive summary

The project has roughly 50+ character/enemy assets in the megapack and a v3 roadmap that sketches a long progression across 20 waves, but the live game is only partially migrated to that plan.

There are two different kinds of problems:

1. **True contradictions** — the roadmap conflicts with established project intent or the current playable game.
2. **Unfinished migration** — the roadmap names enemies that simply have not been wired into the live game yet.

The three blocking contradictions have been resolved (see Section F for exact changes made):

- ✅ `Knight_LVL1`–`Knight_LVL4` reserved for the player only — Knight removed from wave enemy pools.
- ✅ `Dummy_LVL2` wired into Wave 3 — the missing middle rung of the dummy ladder is now live.
- ✅ Wave 1 opener locked as **Blue Goblin** — the Mushroom mention in the roster section was wrong.

---

## A. Design decisions — now locked

### 1. Knights belong to the player ✅ RESOLVED

**Problem**

The v3 roadmap listed `Knight_LVL1` at Wave 9, `Knight_LVL2` at Wave 12, and `Knight_LVL4` at Wave 18 as enemies. But `Knight_LVL1` is already the player character art in `Player.tscn`, and `ENEMY_DESIGN_CATALOG.md`, `ENEMY_ROSTER.md`, and `ADDING_ENEMIES.md` all reserve `Knight_LVL1`–`Knight_LVL4` for player visual progression.

**Decision: LOCKED**

`Knight_LVL1`–`Knight_LVL4` are the **player progression skins only**, never enemies.

Intended player arc:
- Run starts as `Knight_LVL1`
- Visual upgrade to `Knight_LVL2` at a mid-run milestone
- `Knight_LVL3` at a later milestone
- `Knight_LVL4` as the final / prestige form

**Live fix applied 2026-05-16**

`wave_09.tres`: Knight_LVL1 pool addition replaced with `Enemy_GoblinRed` (weight 16). GoblinRed was already the first new enemy in wave 10's pool, so pulling its introduction one wave earlier fits natural escalation — the wave 10+ files will simply upsert its weight as before.

`wave_12.tres` and `wave_18.tres` have no Knight entries in the live .tres files — those Knight slots only existed in the roadmap HTML doc. The HTML needs a future pass to replace those slots with real enemies (suggestions in Section D).

---

### 2. Dummy_LVL2 was missing from the live game — now fixed ✅ RESOLVED

**Problem**

`Main_ENEMY_WAVE_ROADMAP_V2.html` explicitly placed `Dummy_LVL2` in Tier F, added at Wave 3, retired at Wave 9. The sprites existed in the megapack (`Dummy_LVL2/`, 33×35 frames). But no `Enemy_DummyLVL2.tscn` scene existed, and it was never in any wave's pool additions. Wave 6 jumped straight from `Dummy_LVL1` to `Dummy_LVL3`, skipping the middle rung.

**Decision: RESOLVED**

Wire `Dummy_LVL2` into Wave 3 as the roadmap intended.

**Live fix applied 2026-05-16**

`scenes/enemies/Enemy_DummyLVL2.tscn` created. Stats interpolated between LVL1 and LVL3:

| Stat | LVL1 | LVL2 (new) | LVL3 |
|---|---|---|---|
| max_health | 21 | 22 | 24 |
| move_speed | 55 | 57 | 60 |
| damage | 5 | 5 | 6 |
| contact_cooldown | 1.2 | 1.2 | 1.15 |
| collision_radius | 14 | 14 | 16 |
| sprite scale | 3× | 3× | 2× |

`wave_03.tres`: `Enemy_DummyLVL2` added to `pool_additions` (weight 12 — low, it's a rare mid-wave surprise, not the dominant spawn at that tier).

`wave_09.tres`: `Enemy_DummyLVL2` added to `pool_removals` alongside `Dummy_LVL1` and `Dummy_LVL3`. The full tutorial dummy ladder now retires cleanly at Wave 9 as designed.

---

### 3. Wave 1 opener is Blue Goblin, not Mushroom ✅ RESOLVED

**Problem**

The v3 roadmap's Tier-F roster section listed `Mushroom` as a Wave 1 enemy alongside `Dummy_LVL1` and green goblin. But the roadmap's own wave table (§4) and the live `wave_01.tres` both used `Dummy_LVL1` / green goblin / **blue goblin** — no Mushroom. The HTML document was internally inconsistent.

**Decision: LOCKED — Blue Goblin is the Wave 1 opener**

Reasoning:
1. The live game has used Blue Goblin since early development.
2. No `Enemy_Mushroom.tscn` scene has ever been created.
3. The roadmap wave table (§4) — the more authoritative section — already says Blue Goblin for Wave 1.
4. The Mushroom megapack sprite has `Spell_Begin`, `Spell_Full`, and `Spell_Loop` animations, clearly marking it as a **ranged/magic enemy** that belongs in mid-to-late game, not Wave 1 tutorial fodder.

**Fix applied 2026-05-16: doc only**

No live game change needed — `wave_01.tres` is already correct. The only fix is this document locking the answer so future sessions don't re-open it.

When a Mushroom enemy scene is eventually created, treat it as a mid-game ranged caster (Tier C/D), not a Tier F fodder unit.

---

## B. Audit sheet

### 1. Safe to wire as-is

| Enemy / line | Notes |
|---|---|
| `Dummy_LVL1` | Live |
| `Dummy_LVL2` | Now live (fixed 2026-05-16) |
| `Dummy_LVL3` | Live |
| `Dummy_LVL4` | Safe as mid-game enemy; has a shield so belongs Tier D, not Tier F |
| `Goblin_Regular green / blue / red` | Safe |
| `Goblin_Barrel green / blue / red` | Safe |
| `Mimic_LVL1`–`LVL4` | Safe |
| `Dwarfette_LVL1`–`LVL4` | Safe |
| `Ent_LVL1`–`LVL4` | Safe |
| `FrogMonster` | Safe |
| `Sorcerer_LVL1`–`LVL4` | Safe; flagged for ranged AI when that system lands |
| `Orc_Archer` variants | Safe; flagged for ranged AI |
| `RhinoMonster` line | Safe |
| `MonsterSlasher_01` | Safe |
| `Orc_Barbare` variants | Safe |
| `Cyclop_Archer_01` | Safe; already live |
| `Vampire_Archer_01` | Safe; flagged for ranged AI |
| `FrogBoss` / `GameMaster` | Boss content only, not wave trash |
| `Mushroom` | Future mid-game ranged caster — NOT Wave 1 fodder |

### 2. Confirmed off-limits for enemy pools

| Enemy / line | Reason |
|---|---|
| `Knight_LVL1` | Player character art — player progression only |
| `Knight_LVL2` | Reserved for player visual upgrade |
| `Knight_LVL3` | Reserved for player visual upgrade |
| `Knight_LVL4` | Reserved for player's final / prestige form |

### 3. Backlog — roadmap entries not yet wired (not contradictions)

| Wave | Not yet live |
|---|---|
| 4 | No blocker in code. Green goblin is already live via pool carry-forward; remaining question is whether this wave still wants one more distinct body beyond Cyclop before Wave 5. |
| 5 | Trash roster is live (`Mimic_LVL1` is in); the separate mini-boss beat from the roadmap is still not implemented. |
| 10 | `Dummy_LVL4`, `RhinoMonster_01` |
| 11 | `Ent_LVL3`, `Sorcerer_LVL2`, `Orc_Archer blue` |
| 12 | `Mimic_LVL3`, `Dwarfette_LVL3` *(Knight_LVL2 slot needs a replacement — see §D)* |
| 13 | `RhinoMonster_03`, `Orc_Barbare blue` |
| 14 | `Sorcerer_LVL3`, `MonsterSlasher_01` |
| 15 | `Ent_LVL4`, `Orc_Archer red` |
| 16 | `RhinoMonster_05`, `RhinoMonster_06` |
| 17 | `Dwarfette_LVL4`, `Orc_Barbare red`, `Sorcerer_LVL4` |
| 18 | `RhinoMonster_04 Devil` *(Knight_LVL4 slot needs a replacement — see §D)* |
| 19 | `RhinoMonster_07`–`10` |
| 20 | Boss-wave implementation still mostly placeholder |

---

## C. Doc-vs-live status table

| Area | Was | Now | Status |
|---|---|---|---|
| Wave 1 opener | Doc said Mushroom; live had Blue Goblin | Blue Goblin locked; Mushroom is a future mid-game enemy | ✅ Resolved |
| Wave 3 Dummy_LVL2 | No scene, not in any pool | Scene created, added to Wave 3 pool | ✅ Resolved |
| Wave 9 Knight | Knight_LVL1 in pool additions | Replaced with GoblinRed; Dummy_LVL2 added to removals | ✅ Resolved |
| Wave 12 Knight slot | Roadmap listed Knight_LVL2 | No live Knight entry; slot needs replacement in roadmap HTML | ⚠ Future doc pass |
| Wave 18 Knight slot | Roadmap listed Knight_LVL4 | No live Knight entry; slot needs replacement in roadmap HTML | ⚠ Future doc pass |
| Waves 10–20 composition | Large planned roster vs sparse live pools | Migration incomplete but no longer blocked by contradictions | 🔲 Backlog |

---

## D. Next decisions for future sessions

1. **Replace Knight slots in `Main_ENEMY_WAVE_ROADMAP_V2.html`**
   - Wave 12 Knight_LVL2 → suggest `Orc_Barbare green` or `RhinoMonster_02 Silver` (similar tier)
   - Wave 18 Knight_LVL4 → suggest `RhinoMonster_04 Devil` (already in the §B3 backlog for that wave)

2. **Continue wave wiring from the backlog**
   - Wave 4: `Ent_LVL1` is a natural next addition (Ent_LVL2 is already live; a LVL1 scene needs creating or LVL2 can be reused with lower stats)
   - Wave 10+: `Dummy_LVL4`, `RhinoMonster_01` are both safe to wire

3. **Decide on player Knight upgrade trigger**
   - When does the player visually upgrade Knight_LVL1 → LVL2 → LVL3 → LVL4?
   - Options: XP level thresholds during a run, meta-progression unlock, wave milestone, shop purchase.

4. **Future Mushroom enemy scene**
   - Sprite has Spell_Begin / Spell_Full / Spell_Loop → clearly a ranged caster
   - Target Tier C/D, not Tier F
   - Wire only after the ranged AI system is ready

---

## E. Current live state snapshot (as of 2026-05-16 fixes)

| Scene | First wave in pool | Last wave in pool | Notes |
|---|---|---|---|
| `Enemy_Dummy` (LVL1) | 1 | 8 | Retired at Wave 9 |
| `Enemy.tscn` (Green Goblin) | 1 | 8 | Retired at Wave 9 |
| `Enemy_GoblinBlue` | 1 | ongoing | Weight fades in later waves |
| `Enemy_Cyclop` | 3 | ongoing | |
| `Enemy_DummyLVL2` | 3 | 8 | **Added 2026-05-16; retired at Wave 9** |
| `Enemy_Mimic` (LVL1) | 5 | ongoing | cap=3 |
| `Enemy_DummyLVL3` | 6 | 8 | Retired at Wave 9 |
| `Enemy_GoblinBarrelRed` | 6 | ongoing | |
| `Enemy_DwarfetteLVL1` | 6 | ongoing | |
| `Enemy_FrogMonster` | 7 | ongoing | |
| `Enemy_Ent_LVL2` | 7 | ongoing | |
| `Enemy_MimicLVL2` | 8 | ongoing | cap=3 |
| `Enemy_SorcererLVL1` | 8 | ongoing | cap=2 |
| `Enemy_OrcArcherGreen` | 8 | ongoing | cap=2 |
| `Enemy_DwarfetteLVL2` | 9 | ongoing | |
| `Enemy_GoblinRed` | 9 | 19 | **Intro moved from W10; retired at Wave 20** |

Special / non-pool:
- `Enemy_TreasureGoblin` — separate frequent special, not wave trash

---

## F. Changes applied 2026-05-16

| File | Change |
|---|---|
| `scenes/enemies/Enemy_DummyLVL2.tscn` | **Created.** Dummy_LVL2 megapack sprites, 33×35 frames (Idle 2f / Move 12f / Dash 4f). HP=22, spd=57, dmg=5. UID: `uid://enemy_dummy_lvl2` |
| `resources/enemies/waves/wave_03.tres` | Added `Enemy_DummyLVL2` to `pool_additions` (weight 12). load_steps 11→13. |
| `resources/enemies/waves/wave_09.tres` | Removed `Enemy_KnightLVL1` from `pool_additions`; replaced with `Enemy_GoblinRed` (weight 16). Added `Enemy_DummyLVL2` to `pool_removals` to close the dummy ladder cleanly. load_steps 10→11. |
| `docs/ENEMY_AUDIT_HANDOFF_2026-05-16.md` | This file — all three decisions locked, all status tables updated. |

---

## Bottom line

The roadmap is now safe to continue. All true contradictions are resolved:

- **Knights stay with the player.** Full stop. No Knight scenes should ever appear in an enemy wave .tres.
- **The dummy ladder is LVL1 → LVL2 → LVL3**, entering at waves 1 / 3 / 6 respectively, retiring together at wave 9.
- **Wave 1 opens with Dummy + Green Goblin + Blue Goblin.** Mushroom is a future mid-game ranged caster, not tutorial trash.

The remaining backlog in §B3 is unfinished migration, not contradictions — safe to wire one wave at a time without stepping on anything.
