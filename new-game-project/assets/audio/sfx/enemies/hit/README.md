# enemies/hit/

Sounds that play when an enemy takes damage.

Examples of what belongs here:
- Generic flesh hit / impact
- Different sounds per enemy family if desired later:
  - small_hit.wav, medium_hit.wav, heavy_hit.wav

Start with 1–2 generic hits. Variation by enemy type can come after the roster is stable.
These play very frequently — keep them short and not too loud.

## sword_clash.wav + sword_clash_2.wav — sword enemy attacks
Used when a sword-wielding enemy hits the player (or clashes during combat).
Alternate between the two on each swing so it never sounds like the same hit twice.
Only assign these to sword-type enemies — generic enemies should use a separate hit sound.
