# Progress Log

This folder tracks what was built / changed / fixed in each build of the game.
The build ID shown in-game (bottom of screen, e.g. `v0.1.0 • build 01a`) comes
from `scripts/systems/BuildInfo.gd` and should match the filename here.

## File naming

`build_<BUILD_ID>.md` — example: `build_01a.md`

## Conventions

Each build doc should briefly cover:

- **What changed** — files touched and the high-level summary
- **Why** — the problem we were solving
- **How** — the actual approach (so future-us remembers the reasoning)
- **Tuning knobs** — any exported vars or magic numbers worth knowing about
- **Known follow-ups** — stuff we noticed but didn't tackle yet

Keep entries short. Code is the source of truth; this is the changelog.
