# Build 01y — v0.1.0

Date: 2026-05-16

## Summary

UI theme switched to blue, quip box stretching fixed, SpellTreeUI now scales down
gracefully on small windows, proper viewport scaling added to project settings, and
camera zoom tuned so the map no longer feels like you're watching from orbit.

## Files changed

- `scripts/ui/shop/ShopUI.gd` — switched pixel UI theme from Black → Blue; fixed quip banner
- `scripts/ui/menus/SpellTreeUI.gd` — added uniform canvas scale for small windows
- `project.godot` — added display stretch settings (1920×1080 base, canvas_items, keep_width)
- `scripts/player/CameraFollow.gd` — added camera_zoom export, default 2.0
- `scripts/systems/BuildInfo.gd` — bumped BUILD_ID from `01x` to `01y`

---

## Change 1 — Shop UI theme: Black → Blue

### Problem
The shop was using the Black variant of the pixel UI pack for all panels and
buttons. Danny picked the darker blue from the asset pack and wanted that used
instead. The quip banner at the bottom of the shop was also visibly stretched —
a 96×22px atlas sprite was being scaled across 560+ pixels of width.

### Solution
- Swapped `Panels/Black/` and `Buttons/Black/` paths to `Panels/Blue/` and
  `Buttons/Blue/` throughout ShopUI.gd.
- Grid slot sprites (`Grid/Black/GridSlot.png`, `GridSlotInactive.png`) stay
  Black because `Grid/Blue/` only contains selector highlights, not slot sprites.
  The contrast between blue outer frame and black card slots actually looks good.
- Replaced the stretched `StyleBoxTexture` (atlas-based) on the quip panel with
  a `StyleBoxFlat` — deep navy (`Color(0.10, 0.14, 0.28, 0.88)`) with a soft
  blue border. Flat styleboxes scale to any width perfectly, no sprite distortion.
- Bumped quip text brightness slightly (`0.68` → `0.78`) so it reads clearly on
  the darker navy background.

### Tuning knobs
- `ShopUI.gd` — `_PIXEL_FRAME`, `_PIXEL_PANEL_GRID`, `_PIXEL_BTN_A`, `_PIXEL_BTN_B`
  paths — change the folder name to swap the whole color theme in one place
- `ShopUI.gd` — `quip_style.bg_color` / `quip_style.border_color` in `_build_ui()`
  for quip banner color

---

## Change 2 — SpellTreeUI: graceful scaling on small windows

### Problem
The SpellTree canvas is authored at a fixed `1060×730` and sits `88px` from the
top of the Spellbook tab, requiring at least `818px` of height to display fully.
At the small debug window size (`1152×619`) the tab only had ~540px, so the bottom
rows of spells (Fire Bomb, Black Hole, etc.) clipped off the edge.

### Solution
Added a uniform scale factor at the top of `_layout_spellbook()`:

```
available_h = size.y - CANVAS_TOP - 8px
available_w = size.x - CANVAS_MIN_LEFT * 2
canvas_scale = min(1.0, min(available_h / 730, available_w / 1060))
_canvas.scale = Vector2(canvas_scale, canvas_scale)
```

Scale is capped at `1.0` — it only ever shrinks, never zooms in. At fullscreen
(`2548×1320`) the ratio is well above 1.0 so scale stays exactly 1.0, zero visual
change. At `1152×619` it calculates to roughly `0.63`, fitting the whole tree.
Canvas `size` stays at the authored `1060×730`; Godot's `scale` property handles
the visual shrink so individual spell node positions never need touching.
DetailPanel position and top offset are also adjusted to track the scaled canvas.

### Tuning knobs
- `SpellTreeUI.gd` — `CANVAS_TOP` bottom padding (the `8.0` in `available_h`)
- No new exports — scale is purely derived from available space

---

## Change 3 — Project viewport scaling (was missing entirely)

### Problem
`project.godot` had no `[display]` section at all — no base resolution, no stretch
mode. Godot was rendering at whatever pixel size the window happened to be. This
is why the game looked fine at `2548×1320` fullscreen and broken at `1152×619`:
there was no consistent "what does 1x look like?" for the engine to scale from.
This also meant nothing would scale correctly in a shipped build.

### Solution
Added to `project.godot`:

```ini
[display]
window/size/viewport_width=1920
window/size/viewport_height=1080
window/stretch/mode="canvas_items"
window/stretch/aspect="keep_width"
```

`canvas_items` scales every sprite and UI element from the base resolution.
`keep_width` ensures the full `1920` game-units of width always fills the screen
edge to edge — on wider screens slightly less vertical space is visible, but no
side bars appear. This is the correct foundation for a shipped 2D game.

Side effect: with proper scaling active, the manual canvas scale added in Change 2
becomes a secondary safety net rather than the primary fix — but it still helps
for extreme window sizes, so it stays.

---

## Change 4 — Camera zoom

### Problem
`Camera2D` had no zoom set (Godot default = `1.0`). The map is `1920×1920px` and
the base viewport is `1920px` wide, so at zoom 1.0 the player could see the entire
map width at once. Enemies spawning at the edge were visible from across the arena.
No tension, no claustrophobia — the opposite of how Brotato feels.

### Solution
Added `camera_zoom` as an `@export float` to `CameraFollow.gd` (default `2.0`).
In `_ready()`, `zoom = Vector2(camera_zoom, camera_zoom)` is set before the player
is found. At zoom 2.0 the visible width is `960px` — half the map — which puts
enemies at a threatening distance and matches the Brotato feel.

```gdscript
@export var camera_zoom: float = 2.0

func _ready() -> void:
    zoom = Vector2(camera_zoom, camera_zoom)
    ...
```

Because it's an `@export`, the value is tweakable live in the Godot Inspector
without touching code.

### Tuning knobs
- `CameraFollow.gd` — `camera_zoom` export (Inspector slider). Range ~`1.8`–`2.5`
  to taste. Higher = more zoomed in / more intense. Lower = more of map visible.

---

## Known follow-ups

- With viewport scaling now active, the manual `_canvas.scale` in SpellTreeUI could
  eventually be removed if the SpellBook is redesigned to use proper anchor-based
  layout instead of hand-placed pixel positions.
- Camera zoom is applied once in `_ready()`. If a future feature needs dynamic zoom
  (e.g. zoom out on boss spawn), `camera_zoom` will need to become a runtime
  property with a tween.
- Side bars are gone but on very tall/narrow windows `keep_width` may crop the top
  and bottom of the game slightly — revisit if mobile/portrait support is ever added.
