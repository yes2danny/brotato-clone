# Spellbook Layout Reference

Date captured: 2026-05-16  
Captured from: `scenes/ui/menus/SpellTreeUI.tscn`  
Current authored canvas: `1060 x 730`  
Current `Nodes` group offset inside that canvas: `(-3, -65)`

This is Danny's preferred Spellbook composition as of build `01m`. The scene is
still the real source of truth, but this note records the intended shape in case
the layout is ever disturbed by accident.

## Branch labels

| Label | Center px inside canvas | Center relative to canvas |
| --- | ---: | ---: |
| LIGHTNING | `(132.0, 127.5)` | `(12.45%, 17.47%)` |
| FIRE | `(237.5, 195.5)` | `(22.41%, 26.78%)` |
| POISON | `(664.5, 117.5)` | `(62.69%, 16.10%)` |
| WATER | `(965.5, 117.5)` | `(91.08%, 16.10%)` |
| DARK | `(635.0, 269.5)` | `(59.91%, 36.92%)` |

## Spell nodes

| Spell node | Center px inside canvas | Center relative to canvas |
| --- | ---: | ---: |
| Fireball | `(51.0, 275.0)` | `(4.81%, 37.67%)` |
| Explosive Fireball | `(152.0, 224.0)` | `(14.34%, 30.68%)` |
| Pillar Fireball | `(318.0, 217.0)` | `(30.00%, 29.73%)` |
| Fire Bomb | `(92.0, 395.0)` | `(8.68%, 54.11%)` |
| Ring of Fire | `(232.0, 381.0)` | `(21.89%, 52.19%)` |
| Small Meteor | `(398.0, 315.0)` | `(37.55%, 43.15%)` |
| Spark Bolt | `(46.0, 39.0)` | `(4.34%, 5.34%)` |
| Chain Lightning | `(133.0, 36.0)` | `(12.55%, 4.93%)` |
| Lightning Strike | `(223.0, 39.0)` | `(21.04%, 5.34%)` |
| Electric Burst | `(351.0, 60.0)` | `(33.11%, 8.22%)` |
| Electric Field | `(454.0, 90.0)` | `(42.83%, 12.33%)` |
| Pulse Beam | `(395.0, -6.0)` | `(37.26%, -0.82%)` |
| Acid Glob | `(568.0, 31.0)` | `(53.58%, 4.25%)` |
| Toxic Burst | `(666.0, 10.0)` | `(62.83%, 1.37%)` |
| Poison Cloud | `(743.0, 50.0)` | `(70.09%, 6.85%)` |
| Green Vortex | `(799.0, 106.0)` | `(75.38%, 14.52%)` |
| Water Drop | `(1055.0, 232.0)` | `(99.53%, 31.78%)` |
| Splash Burst | `(1044.0, 117.0)` | `(98.49%, 16.03%)` |
| Wave | `(1005.0, 25.0)` | `(94.81%, 3.42%)` |
| Water Whirl | `(921.0, -17.0)` | `(86.89%, -2.33%)` |
| Dark Bolt | `(499.0, 327.0)` | `(47.08%, 44.79%)` |
| Void Orb | `(603.0, 337.0)` | `(56.89%, 46.16%)` |
| Smoke Curse | `(693.0, 344.0)` | `(65.38%, 47.12%)` |
| Black Hole | `(800.0, 412.0)` | `(75.47%, 56.44%)` |
| Skull Shot | `(546.0, 477.0)` | `(51.51%, 65.34%)` |
| Blood Explosion | `(658.0, 486.0)` | `(62.08%, 66.58%)` |

## Resize behavior

- The first time the Spellbook appears in-game, `SpellTreeUI.gd` records this
  authored arrangement relative to the actual Spellbook window size.
- If that window later grows or shrinks, the nodes, branch labels, and hover
  panel move proportionally with it so the overall shape stays the same.
- The spell node art itself does **not** scale up; only placement changes. That
  keeps the pixel art sharp.
