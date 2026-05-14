#!/usr/bin/env python3
"""
Generate Godot WeaponData .tres files from a CSV.

Usage (from the new-game-project folder):
  python tools/weapon_bulk_import.py path/to/weapons.csv

Columns (see weapon_bulk_import.example.csv):
  Required: id, weapon_name
  Optional: description, cost, damage, fire_rate, bullet_speed, detection_range,
            bullet_lifetime, projectile_count, spread_angle, scale_x, scale_y,
            damage_scale, fire_rate_scale, is_unlocked (true/false),
            cell (0–43), x, y, w, h

Crop rules:
  - If x, y, w, h are all present and numeric → use_sprite_region_rect = true
  - Else → grid mode with spritesheet_cell_index = cell (default 0)

Output: res://resources/items/weapons/<id>.tres (under this project).
"""
from __future__ import annotations

import argparse
import csv
import re
import sys
from pathlib import Path

SCRIPT_PATH = Path(__file__).resolve()
PROJECT_ROOT = SCRIPT_PATH.parent.parent
DEFAULT_OUT = PROJECT_ROOT / "resources" / "items" / "weapons"

GD_RESOURCE_HEADER = """[gd_resource type="Resource" script_class="WeaponData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/weapons/data/WeaponData.gd" id="1_weapon_data"]

[resource]
script = ExtResource("1_weapon_data")
"""


def _safe_id(raw: str) -> str:
    s = raw.strip().lower().replace(" ", "_").replace("-", "_")
    if not re.fullmatch(r"[a-z0-9_]+", s):
        raise ValueError(f"Unsafe or invalid id {raw!r} — use letters, numbers, underscore only.")
    return s


def _g_str(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def _parse_bool(cell: str | None, default: bool = True) -> bool:
    if cell is None or str(cell).strip() == "":
        return default
    v = str(cell).strip().lower()
    if v in ("1", "true", "yes", "y"):
        return True
    if v in ("0", "false", "no", "n"):
        return False
    raise ValueError(f"Expected true/false, got {cell!r}")


def _f(cell: str | None, default: float) -> float:
    if cell is None or str(cell).strip() == "":
        return default
    return float(str(cell).strip())


def _i(cell: str | None, default: int) -> int:
    if cell is None or str(cell).strip() == "":
        return default
    return int(float(str(cell).strip()))


def row_to_tres(row: dict[str, str]) -> str:
    rid = _safe_id(row.get("id", ""))
    name = row.get("weapon_name", "").strip()
    if not name:
        raise ValueError(f"Row id={rid!r}: weapon_name is required.")

    desc = (row.get("description") or "").strip()
    cost = _i(row.get("cost"), 75)
    damage = _i(row.get("damage"), 20)
    fire_rate = _f(row.get("fire_rate"), 1.0)
    bullet_speed = _f(row.get("bullet_speed"), 400.0)
    detection_range = _f(row.get("detection_range"), 300.0)
    bullet_lifetime = _f(row.get("bullet_lifetime"), 2.0)
    projectile_count = _i(row.get("projectile_count"), 1)
    spread_angle = _f(row.get("spread_angle"), 0.0)
    sx = _f(row.get("scale_x"), 1.3)
    sy = _f(row.get("scale_y"), 1.3)
    damage_scale = _f(row.get("damage_scale"), 1.15)
    fire_rate_scale = _f(row.get("fire_rate_scale"), 1.1)
    unlocked = _parse_bool(row.get("is_unlocked"), True)

    xs, ys, ws, hs = row.get("x"), row.get("y"), row.get("w"), row.get("h")
    rect_parts = [xs, ys, ws, hs]
    rect_filled = all(p is not None and str(p).strip() != "" for p in rect_parts)

    if rect_filled:
        use_rect = True
        rx, ry, rw, rh = float(xs.strip()), float(ys.strip()), float(ws.strip()), float(hs.strip())
        cell = 0
    else:
        use_rect = False
        cell = _i(row.get("cell"), 0)
        if cell < 0 or cell > 43:
            raise ValueError(f"id={rid!r}: cell must be 0–43, got {cell}")
        rx = ry = rw = rh = 0.0

    lines = [
        GD_RESOURCE_HEADER,
        f"weapon_name = {_g_str(name)}",
        f"description = {_g_str(desc)}",
        f"cost = {cost}",
        f"is_unlocked = {str(unlocked).lower()}",
        f"use_sprite_region_rect = {str(use_rect).lower()}",
        f"sprite_region_rect = Rect2({rx}, {ry}, {rw}, {rh})",
        f"spritesheet_cell_index = {cell}",
        f"weapon_sprite_scale = Vector2({sx}, {sy})",
        f"damage = {damage}",
        f"fire_rate = {fire_rate}",
        f"bullet_speed = {bullet_speed}",
        f"bullet_lifetime = {bullet_lifetime}",
        f"detection_range = {detection_range}",
        f"projectile_count = {projectile_count}",
        f"spread_angle = {spread_angle}",
        f"damage_scale = {damage_scale}",
        f"fire_rate_scale = {fire_rate_scale}",
        "",
    ]
    return "".join(line + "\n" for line in lines)


def main() -> int:
    ap = argparse.ArgumentParser(description="Generate WeaponData .tres from CSV.")
    ap.add_argument("csv_path", type=Path, help="CSV file (see weapon_bulk_import.example.csv)")
    ap.add_argument(
        "-o",
        "--out-dir",
        type=Path,
        default=DEFAULT_OUT,
        help=f"Output folder (default: {DEFAULT_OUT})",
    )
    args = ap.parse_args()
    csv_path: Path = args.csv_path
    out_dir: Path = args.out_dir

    if not csv_path.is_file():
        print(f"Missing CSV: {csv_path}", file=sys.stderr)
        return 1

    out_dir.mkdir(parents=True, exist_ok=True)
    written: list[str] = []

    with csv_path.open(newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        if not reader.fieldnames or "id" not in reader.fieldnames or "weapon_name" not in reader.fieldnames:
            print("CSV must have headers including id, weapon_name", file=sys.stderr)
            return 1
        for i, row in enumerate(reader, start=2):
            if not row.get("id") or str(row["id"]).startswith("#"):
                continue
            try:
                body = row_to_tres(row)
            except ValueError as e:
                print(f"Line {i}: {e}", file=sys.stderr)
                return 1
            rid = _safe_id(row["id"])
            out_path = out_dir / f"{rid}.tres"
            out_path.write_text(body, encoding="utf-8")
            written.append(str(out_path.relative_to(PROJECT_ROOT)))

    print(f"Wrote {len(written)} file(s) under {out_dir}:")
    for w in written:
        print(" ", w)
    print("\nNext in Godot: Main.tscn → ShopManager → Available Weapons → add these resources.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
