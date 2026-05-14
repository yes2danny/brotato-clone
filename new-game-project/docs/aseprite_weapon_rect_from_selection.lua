-- Aseprite: print Godot Rect2 from current rectangular selection.
--
-- HOW TO RUN (once per Aseprite install):
--   File → Scripts → Open Script… → pick this file → Run (or assign a shortcut).
-- Or: File → Scripts → Rescan Scripts, then Scripts menu if you put this in your scripts folder.
--
-- BEFORE RUNNING: use the Rectangular Marquee (M), draw around ONE gun on weapons.png.

local spr = app.activeSprite
if not spr then
  app.alert("No active sprite.")
  return
end

local sel = spr.selection
if sel.isEmpty then
  app.alert("No selection. Press M, drag a box around one gun, then run this script again.")
  return
end

local b = sel.bounds
if b.width == 0 or b.height == 0 then
  app.alert("Selection has zero size. Draw a rectangular selection (M tool) around one gun.")
  return
end
local line = string.format(
  "Godot Inspector → Weapon Region Manual:\n\n  x = %d\n  y = %d\n  w = %d\n  h = %d\n\nOr in code:\n  Rect2(%d, %d, %d, %d)",
  b.x, b.y, b.width, b.height,
  b.x, b.y, b.width, b.height
)
app.alert(line)
