# Asset Library

This file tracks every art / audio pack we own and where it lives in the
project, so we do not accidentally buy the same thing twice and so any AI
helper or future-Day can see what is already on disk without spelunking
through every folder.

> **Scope rule:** every top-level folder under `assets/` should show up in this
> file at least once, even if nothing is wired into a scene yet.

---

## 1. Magic and Explosions packs (`assets/vfx/`, `assets/_source/magic_and_explosions/`)

| Pack | Kind | Imported from | Project folders | Notes |
| --- | --- | --- | --- | --- |
| `magic_pack_07` | magic | `03 March\MAGIFX AND EXPLOSTION\Magic Pack 7 files` | `assets/_source/magic_and_explosions/magic_pack_07`, `assets/vfx/magic/magic_pack_07` | General magic pack; keep as a separate owned pack. |
| `magic_pack_09` | magic | `Downloads\Magic Pack 9 files` | `assets/_source/magic_and_explosions/magic_pack_09`, `assets/vfx/magic/magic_pack_09` | Free pack with `Dark-Bolt`, `Fire-bomb`, `Lightning`, and `spark`. |
| `magic_pack_14` | magic | `03 March\03 March\Magic and Explosions\magic pack 14` | `assets/_source/magic_and_explosions/magic_pack_14`, `assets/vfx/magic/magic_pack_14` | Includes `Acid`, `BlackHole`, `FireStar`, `Flower`, `Lava`, `Rings`, `Skull`, `Spark`, `Spin`. |
| `magic_pack_15` | magic | April Patreon drop | `assets/_source/magic_and_explosions/magic_pack_15`, `assets/vfx/magic/magic_pack_15` | Already owned before this intake pass. |
| `magic_pack_16` | magic | April Patreon drop | `assets/_source/magic_and_explosions/magic_pack_16`, `assets/vfx/magic/magic_pack_16` | Already owned before this intake pass. |
| `energy` | magic standalone | `03 March\MAGIFX AND EXPLOSTION\Energy` | `assets/_source/magic_and_explosions/energy`, `assets/vfx/magic/energy` | Standalone effect set. |
| `pulse` | magic standalone | `03 March\MAGIFX AND EXPLOSTION\Pulse` | `assets/_source/magic_and_explosions/pulse`, `assets/vfx/magic/pulse` | Standalone effect set. |
| `water_whirl` | magic standalone | `03 March\MAGIFX AND EXPLOSTION\Water Whirl` | `assets/_source/magic_and_explosions/water_whirl`, `assets/vfx/magic/water_whirl` | Standalone effect set. |
| `explosions_pack_01` | explosions | `03 March\MAGIFX AND EXPLOSTION\explosion pack 1` | `assets/_source/magic_and_explosions/explosions_pack_01`, `assets/vfx/explosions/explosions_pack_01` | Older numbered explosion pack. |
| `explosions_pack_02` | explosions | `03 March\MAGIFX AND EXPLOSTION\Explosions Pack 2 files` | `assets/_source/magic_and_explosions/explosions_pack_02`, `assets/vfx/explosions/explosions_pack_02` | Keep distinct from `explosions_p2_loose` until we visually verify overlap. |
| `explosions_pack_03` | explosions | `03 March\MAGIFX AND EXPLOSTION\Explosions Pack 3 files` | `assets/_source/magic_and_explosions/explosions_pack_03`, `assets/vfx/explosions/explosions_pack_03` | Older numbered explosion pack. |
| `explosions_pack_04` | explosions | `03 March\MAGIFX AND EXPLOSTION\Explosion Pack 4 Files` | `assets/_source/magic_and_explosions/explosions_pack_04`, `assets/vfx/explosions/explosions_pack_04` | Older numbered explosion pack. |
| `explosions_pack_11` | explosions | `03 March\03 March\Magic and Explosions\explosion pack 11` | `assets/_source/magic_and_explosions/explosions_pack_11`, `assets/vfx/explosions/explosions_pack_11` | Newer numbered explosion pack. |
| `explosions_pack_12` | explosions | `03 March\03 March\Magic and Explosions\explosion pack 12` | `assets/_source/magic_and_explosions/explosions_pack_12`, `assets/vfx/explosions/explosions_pack_12` | Newer numbered explosion pack. |
| `explosions_pack_13` | explosions | `03 March\03 March\Magic and Explosions\explosion pack 13` | `assets/_source/magic_and_explosions/explosions_pack_13`, `assets/vfx/explosions/explosions_pack_13` | Newer numbered explosion pack. |
| `explosions_pack_14` | explosions | `03 March\03 March\Magic and Explosions\explosion pack 14` | `assets/_source/magic_and_explosions/explosions_pack_14`, `assets/vfx/explosions/explosions_pack_14` | Newer numbered explosion pack. |
| `explosions_pack_15` | explosions | `03 March\03 March\Magic and Explosions\explosion pack 15` | `assets/_source/magic_and_explosions/explosions_pack_15`, `assets/vfx/explosions/explosions_pack_15` | Newer numbered explosion pack. |
| `explosions_pack_16` | explosions | April Patreon drop | `assets/_source/magic_and_explosions/explosions_pack_16`, `assets/vfx/explosions/explosions_pack_16` | Already owned before this intake pass. |
| `bonus_pack_03` | explosions bonus | `03 March\MAGIFX AND EXPLOSTION\3 Bonus Pack` | `assets/_source/magic_and_explosions/bonus_pack_03`, `assets/vfx/explosions/bonus_pack_03` | Bonus pack with `p2-explosion-b`, `p4-explosion-j`, `p7-explosion-c`. |
| `explosions_p2_loose` | explosions loose set | `03 March\MAGIFX AND EXPLOSTION\explosions-p2` | `assets/_source/magic_and_explosions/explosions_p2_loose`, `assets/vfx/explosions/explosions_p2_loose` | Four loose folders named `explosion-a` through `explosion-d`; may overlap Pack 2 but is not assumed duplicate yet. |

### Magic / explosion intake rules

- Add every newly purchased pack here before we start wiring it into spells.
- If two packs look similar by name, keep them separate until we visually confirm
  they are actually duplicates.
- If a pack later becomes part of a spell line, note that in its row rather than
  renaming the original pack.

### Review notes

- First visual spell review: `docs/SPELL_VFX_REVIEW_2026-05-16.md`
- `explosions_pack_02` and `explosions_p2_loose` are not exact file duplicates
  from a first hash check, so both stay in the library for now.

---

## 2. UI packs (`assets/ui/`, `assets/_source/ui/`)

| Pack | Kind | Imported from | Project folders | Notes |
| --- | --- | --- | --- | --- |
| `fantasy_ui_paid` | UI atlas | `Downloads\UI\FantasyUI\FantasyUI` | `assets/_source/ui/fantasy_ui_paid`, `assets/ui/fantasy_ui_paid` | Ornate dark frames, lanterns, scrolls, wood accents, menu pieces. Atlas file: `atlas.png`. Source also has `Dragonhpbar.png`, `DragonHpBar2.png`, `DragonHpBar3.png`, `fantasy.png`. |
| `fantasy_ui_free` | UI mini pack | `Downloads\UI\FantasyUIfree\FantasyUIfree` | `assets/_source/ui/fantasy_ui_free` | Smaller free subset; mostly overlaps the paid fantasy look. Includes `Dragonhpbar` variants and `freefantasy.png`. |
| `medieval_ui_paid` | UI props atlas | `Downloads\UI\PaidMedieval\PaidMedieval` | `assets/_source/ui/medieval_ui_paid`, `assets/ui/medieval_ui_paid` | Lanterns, shields, parchment, banners, books, potions. Atlas file: `atlas.png` (source = `medieval.png`). |
| `medieval_ui_free` | UI mini pack | `Downloads\UI\FreeMedieval\FreeMedieval` | `assets/_source/ui/medieval_ui_free` | Tiny free subset (`free.png`); useful mostly as a reference or fallback. |
| `tiny_rpg_mana_soul_gui` | UI strips | `Downloads\tinyRPG_manaSoulGUI_v_1_0` | `assets/_source/ui/tiny_rpg_mana_soul_gui`, `assets/ui/tiny_rpg_mana_soul_gui` | Small framed strips. The wider blue `button_b` panel is now wired into the shop quip box. |
| `pixel_ui` | HUD / menu pixel UI system | (existing project pack) | `assets/ui/pixel_ui/` (cleaned PNG slices), `assets/_source/pixel_ui_hud/aseprite/` (editable `.aseprite` sources) | The main UI system already wired into menus / HUD. See section 3 below for the slice breakdown. |
| `main_menu` | one-off art | (custom) | `assets/ui/main_menu/orc_hero.png` | Hero illustration used on the main menu. |

### UI intake notes

- The new fantasy/medieval art is **not** a wholesale replacement for the current
  cleaner `pixel_ui` system.
- Best current use: subtle decoration in the shop, richer framing or props in the
  main menu, future inventory / codex / merchant screens.
- Avoid dropping the wood-heavy pieces everywhere at once; the project currently
  looks strongest when the new art is used as seasoning, not as the whole meal.

---

## 3. `pixel_ui` slice breakdown (`assets/ui/pixel_ui/`)

Every subfolder here is a themed group of pre-sliced PNGs (most groups include
an `All.png` overview plus color variants).

| Folder | Contents | Typical use |
| --- | --- | --- |
| `Arcade` | `ArcadeOverlay.png`, `ArcadeOverlayFrame.png`, `ArcadeOverlayHighlights.png`, `ArcadeOverlayShadows.png`, `BackgroundGrid.png` | CRT / arcade overlay look. |
| `Banners` | `All.png` + color folders (`Black`, `Blue`, `Gold`, `Green`, `Orange`, `Purple`, `Red`) | Title / header banners. |
| `Buttons` | `All.png` + color folders (`Black`, `Blue`, `Gold`, `Orange`, `Purple`, `Red`, `White`) | Menu / dialog buttons. |
| `Cursors` | `All.png` + color folders (same palette) | Mouse cursors and pointers. |
| `Decorators` | `All.png` + color folders | Small decorative trim. |
| `FormElements` | `All.png` + color folders | Sliders, checkboxes, dropdowns. |
| `Grid` | `All.png`, `AllAnimated.png` + color folders | Inventory / loadout grid slots (with animated versions). |
| `Hearts` | `All.png` + `Blue`, `Purple`, `Red` | HP / lives display. |
| `Jewel` | `All.png` + color folders | Currency / gem displays. |
| `Lists` | `All.png` + color folders | Scrollable lists. |
| `Minimap` | `Color`, `White` | Minimap chrome. |
| `Panels` | `All.png` + many color folders (`Black`, `Blue`, `Gold`, `Paper`, etc.) | Window / dialog panels. |
| `Portraits` | `EnemyLarge.png`, `EnemyMedium.png`, `EnemySmall.png`, `EnemySmallFrame.png`, `PlayerLarge.png` + more | Character portraits and frames. |
| `Selectors` | Many individual `Angled_*`, `Chevron*`, `Square_*` selector PNGs | Highlight / select states. |
| `SkillTree` | `All.png`, `AllAnimated.png` + color folders (`Blue`, `Grey`, `Purple`, etc.) | Skill / talent tree nodes. |
| `Stars` | `All.png` + `Blue`, `Gold`, `Purple`, `Red` | Rating / tier stars. |
| `Tooltips` | `All.png` + color folders | Hover tooltip frames. |
| `ValueBars` | `All.png` + color folders | HP / XP / cooldown bars. |
| `ValueSlots` | `All.png` + color folders | Stat / value plates. |

### `pixel_ui` source files (`assets/_source/pixel_ui_hud/aseprite/`)

Editable `.aseprite` originals. Useful when we need to recolor or extend a
slice instead of fighting the exported PNG.

- `Banners.aseprite`, `Buttons.aseprite`, `ClickEffects.aseprite`, `Cursors.aseprite`
- `Decorators.aseprite`, `FormElements.aseprite`
- `GridSlots.aseprite`, `GridSlotsAnimated.aseprite`
- `Hearts.aseprite`, `Jewel.aseprite`, `Lists.aseprite`, `Minimap.aseprite`
- `Palette.aseprite`, `Panels.aseprite`, `PanelsThemed.aseprite`
- `Portraits.aseprite`, `Scripts/` (helper scripts), `Selectors.aseprite`
- `SkillTree.aseprite`, `SkillTreeAnimated.aseprite`
- `Stars.aseprite`, `Tooltips.aseprite`, `ValueBars.aseprite`, `ValueSlots.aseprite`
- Pack readme at `_source/pixel_ui_hud/Readme.txt`

---

## 4. Characters / enemies (`assets/sprites/characters/`)

### Custom (`assets/sprites/characters/custom/`)

| Folder / file | Frames | Notes |
| --- | --- | --- |
| `GoldThief/GoldThief_Run_9x1.png` | 9-frame run sheet | Custom enemy used by the gold-thief behavior. |
| `screenshot_2026-05-15_010836_128.png` | — | Reference screenshot, not a runtime sprite. |

### Megapack roster (`assets/sprites/characters/megapack/`)

Every character below has its own folder of animation sprite sheets (typical
animations: `Idle`, `Move`/`Walk`/`Run`, `ATK`/`ATK_Full`, `Hit`, `Death`, plus
extras like `Dash`, `Dashend`, `Block`, `Charge` where the kit supports it).
Sheets follow the `Name_<frames>x1.png` convention and ship with both a folder
of individual frames and the strip.

**Wired or experimentally wired right now:**

- `Cyclop_Archer_01`
- `Knight_LVL1`, `Knight_LVL2`, `Knight_LVL3`, `Knight_LVL4`
- `Dummy_LVL1`, `Dummy_LVL2`, `Dummy_LVL3`, `Dummy_LVL4` (training dummies / test enemies)
- `GameMaster`

**Owned but not wired (available for future waves / bosses):**

| Character | Variants in folder |
| --- | --- |
| `Dwarfette` | `LVL1`, `LVL2`, `LVL3`, `LVL4` |
| `Ent` | `LVL1`, `LVL2`, `LVL3`, `LVL4` |
| `Sorcerer` | `LVL1`, `LVL2`, `LVL3`, `LVL4` |
| `Mimic` | `LVL1`, `LVL2`, `LVL3`, `LVL4` |
| `Goblin_Barrel` | `01 (Green Skinned)`, `02 (Blue Skinned)`, `03 (Red Skinned)` |
| `Goblin_Regular` | `01 (Green Skinned)`, `02 (Blue Skinned)`, `03 (Red Skinned)` |
| `Orc_Archer` | `01 (Green Skinned)`, `02 (Blue Skinned)`, `03 (Red Skinned)` |
| `Orc_Barbare` | `01 (Green Skinned)`, `02 (Blue Skinned)`, `03 (Red Skinned)` |
| `RhinoMonster` | `01_Regular`, `02_Silver`, `03_Gold`, `04_Devil`, `05_Orc`, `06_OrcRedSkinned`, `07_Frozen`, `08_Bioluminescent`, `09_Radioactive`, `10_Oniric` |
| `FrogBoss`, `FrogMonster` | boss + minion pair |
| `Mushroom` | single creature |
| `Monsterfly_01` | single creature |
| `MonsterSlasher_01` | single creature |
| `Vampire_Archer_01` | single creature |

> Naming rule: keep the megapack folder names exactly as shipped (including the
> spaces and parens like `(Green Skinned)`) so we can re-import / diff against
> the source pack later.

---

## 5. Tilemaps and biome art (`assets/sprites/tilemaps/`, `assets/tilemaps/`)

Three biome packs, each with the same Characters / Mockups / Props / Tilesets /
TiledMap Editor layout. Meadow adds a `UI/` folder with NPC avatars.

| Biome | Folder | Highlights |
| --- | --- | --- |
| Cemetery | `assets/sprites/tilemaps/cemetery/` | `Characters/` (bat, crow, undead), `Props/` (`abandoned structures - cemetery`, `abandoned structures - day light`, `animated`, `atlas-Props.png`, `props by individual sprites`), `Tilesets/` (`Tileset-Terrain.png`, dirt/grass transition sheets, fences, `Room_Cemetery.tmx`), `Mockups/` (gifs + pngs), `TiledMap Editor/` (sample maps + rules). |
| Crypt | `assets/sprites/tilemaps/crypt/` | `Characters/` (Big Worm 1, Big Worm 2, Skeleton, Spider), `Props/` (`Atlas-Props.png`, `animated`, `atlas props - individual sprites`, `ground-runes.png`), `Tilesets/` (`Tileset-Terrain.png`, balluster sheets, ground transitions, `Room_Crypt.tmx`), `Mockups/`, `TiledMap Editor/`. |
| Meadow | `assets/sprites/tilemaps/meadow/` | `Characters/` (Enemy1, NPC, Warrior), `Props/` (`Atlas-Props.png`, individual sprites, sunlight rays, altars, columns), `Tilesets/` (`Tileset-Terrain.png`, animated water tile sheets + gif, dirt/grass transitions), `Mockups/`, `TiledMap Editor/`, `UI/` (Blacksmith + Vendor avatars in idle/blinking/speaking, plus `UI-elements-32x32` and `64x64` sheets and `npc-icon-attention.png`). |

### In-engine tileset assets (`assets/tilemaps/maps/`)

Godot-side tileset resources actually used by the project:

- `Cemetery.tsx`, `Tileset-Cemetery.png`
- `Crypt.tsx`, `Tileset-Crypt.png`

> Meadow tileset is not yet imported as a `.tsx` here, even though the source
> art exists under `sprites/tilemaps/meadow/`.

---

## 6. Projectiles (`assets/projectiles/`, `assets/sprites/projectiles/`)

### `BulletsAndBombs-PROJECTILEKIT`

Full bullets / bombs art kit. Lives at `assets/projectiles/BulletsAndBombs-PROJECTILEKIT/`.

- `Information-please-read.txt` — pack readme.
- `SPRITE SHEETS/` — combined strips:
  - `Casings-SpriteSheet-(RIGHT).png`, `Casings-SpriteSheet-(UP).png`
  - `Projectiles-Bombs-SpriteSheet-(RIGHT).png`, `Projectiles-Bombs-SpriteSheet-(UP).png`
  - `Projectiles-Bullets-SpriteSheet-(RIGHT).png`, `Projectiles-Bullets-SpriteSheet-(UP).png`, `Projectiles-Bullets-Round-SpriteSheet.png`
  - `Projectiles-Bullets-Stylized-SpriteSheet-(RIGHT).png`, `Projectiles-Bullets-Stylized-SpriteSheet-(UP).png`, `Projectiles-Bullets-Stylized-SpriteSheet-Round.png`
- `SPRITES SEPARATED/` — folders of individual frames matching the strips:
  - `Casings-(RIGHT)`, `Casings-(UP)`
  - `Projectiles-Bombs-(RIGHT)`, `Projectiles-Bombs-(UP)`
  - `Projectiles-Bullets-(RIGHT)`, `Projectiles-Bullets-(UP)`, `Projectiles-Bullets-Round`
  - `Projectiles-Stylized-(RIGHT)`, `Projectiles-Stylized-(UP)`, `Projectiles-Stylized-Round`

### Individual projectile sprites (`assets/sprites/projectiles/`)

- `arrow_cyclop.png` — arrow used by the Cyclop archer enemy.

---

## 7. Weapons (`assets/weapons/`)

Pre-rendered weapon sheets, not yet broken into individual icons.

| Folder | Files | Notes |
| --- | --- | --- |
| `melee/` | `Melee_Weapons.png` | Melee sheet (swords, axes, etc.). |
| `ranged/` | `All_Weapons.png`, `weapons.png`, `gun_01.png` | Ranged weapon sheets + a single gun cut-out. |
| `throwables/` | `Granades.png` | Throwable grenades sheet. |
| `variants/` | `Black_weapons.png`, `Blue_weapons.png`, `Gold_weapons.png`, `Pink_weapons.png` | Recolored copies of the base weapon sheet for rarity / tier variants. |

> See `docs/WEAPON_SPRITE_REGION_GUIDE.html` and
> `docs/aseprite_weapon_rect_from_selection.lua` for the workflow we use to pull
> individual weapon regions out of these sheets.

---

## 8. Item / shop icons (`assets/sprites/items/shop_icons/`)

Custom shop / inventory item icons. Most exist in two sizes: `_64.png`
(in-shop display) and `_full.png` (full resolution master).

| Item icon (basename) | Has 64 | Has full |
| --- | --- | --- |
| `icon_armor_shield` | ✓ | — |
| `icon_damage_sword` | ✓ | — |
| `icon_banana_peel_insurance` | ✓ | ✓ |
| `icon_blue_ward` | ✓ | ✓ |
| `icon_emotional_support_rock` | ✓ | ✓ |
| `icon_fire_rate_spark_clock` | ✓ | ✓ |
| `icon_fridge_magnet` | ✓ | ✓ |
| `icon_gem_alert_magnifier` | ✓ | ✓ |
| `icon_health_heart_charm` | ✓ | ✓ |
| `icon_heavy_round` | ✓ | ✓ |
| `icon_jet_too_boarding_pass` | ✓ | ✓ |
| `icon_lucky_parking_ticket` | ✓ | ✓ |
| `icon_merchant_coupon` | ✓ | ✓ |
| `icon_no_la_polizia_whistle` | ✓ | ✓ |
| `icon_overclocked_toaster` | ✓ | ✓ |
| `icon_panic_button` | ✓ | ✓ |
| `icon_pocket_sand` | ✓ | ✓ |
| `icon_questionable_mystery_box` | ✓ | ✓ |
| `icon_reroll_token` | ✓ | ✓ |
| `icon_six_seven_dice` | ✓ | ✓ |
| `icon_speed_boots` | ✓ | ✓ |
| `icon_stop_sign_question` | ✓ | ✓ |
| `icon_suspicious_hotdog` | ✓ | ✓ |
| `icon_tin_can_armor` | ✓ | ✓ |
| `icon_tiny_legal_disclaimer` | ✓ | ✓ |
| `icon_xp_magnet_pulse` | ✓ | ✓ |
| `meme_item_icon_preview.png`, `shop_icon_preview.png` | — | preview / mockup images, not runtime icons |

---

## 9. Audio (`assets/audio/`)

### Music (`assets/audio/music/`)

- `README.md` placeholder only — no music files imported yet.

### SFX (`assets/audio/sfx/`)

Each subfolder owns one bucket of game events. Files are mostly `.wav`;
each bucket has a `README.md` describing what should live there.

| Bucket | Files (excluding READMEs / `.import`) |
| --- | --- |
| `enemies/death/` | _empty (README only)_ |
| `enemies/hit/` | `sword_clash.wav`, `sword_clash_2.wav` |
| `misc/` | `whistle.wav` |
| `pickups/gold/` | `chips_stack.wav` |
| `pickups/xp/` | _empty (README only)_ |
| `player/death/` | _empty (README only)_ |
| `player/hurt/` | `punch.wav`, `slap.wav` |
| `player/melee/` | `swipe.wav` |
| `player/shoot/` | _empty (README only)_ |
| `round_lose/` | `brass_defeated.wav` |
| `round_start/` | `clock_ticking.wav` |
| `round_win/` | `brass_chime_positive.wav`, `brass_defeated.wav` |
| `shop/buy/` | `item_equip.wav` |
| `shop/open/` | _empty (README only)_ |
| `shop/reroll/` | `dice_grab.wav`, `dice_roll_3.wav`, `dice_shake_3.wav` |
| `ui/` | `map_close.wav`, `map_open.wav`, `toggle_off.wav`, `toggle_on.wav` |
| `weapons/` | `weapon_equip_short.wav`, `weapon_pick_up.wav`, `weapon_unequip.wav`, `weapon_upgrade.wav` |
| `weapons/explosions/` | `explosion_quick.wav`, `shot_muffled.wav` |

> See `docs/SOUND_PLAN_HANDOFF_2026-05-16.md` for the bigger sound plan.

---

## 10. Palettes (`assets/palettes/`)

- `wave1_palette_16.png` — 16-color palette swatch for wave 1.
- `wave1_palette_32.png` — 32-color version of the same palette.

> Treat these as reference swatches when picking colors for new pixel art so
> the whole game keeps a consistent look.

---

## Intake rules (general)

- **Every new pack gets a row.** Drop it in the right section above before you
  start wiring it into scenes; do not delete the source pack folder after import.
- **Keep `_source/` and the wired folder paired.** When you import a new pack,
  copy the source to `assets/_source/<category>/<pack>` and the
  cleaned/ready-to-use copy to its destination (e.g. `assets/vfx/...`,
  `assets/ui/...`). Note both paths in the table.
- **Do not rename ON-DISK pack folders** to match a spell or enemy. Add a note
  in the row instead — that way we can still trace it back to the original
  download if we need to re-import.
- **If two packs might overlap**, keep them both until we visually confirm
  duplicates. Cheap disk space, expensive re-buys.
- **When something gets wired into a scene**, add a short note in the row
  (e.g. _"used by Knight enemy in Wave 1"_) so it's easy to see what is
  actually in-game vs. owned-but-shelved.
