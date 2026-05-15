extends RefCounted
class_name WaveCurve

## Canonical numbers from `docs/Main_ENEMY_WAVE_ROADMAP_V2.html` (v3 rebalance inside that file).
## §3.2–3.6 formulas + §4 table overrides (wave duration 60s, wave 20 trash throttle).
##
## **Option B:** keep the §4 **60s** wave clock. Do not hard-stop spawns at `N_total` yet (§11.1);
## that needs a separate pass so waves do not end with long empty tails. Live pressure = `T(w)`
## + `N_max(w)` + HP/DMG multipliers (`EnemySpawner` may apply small extra multipliers for tuning).

const SPAWN_INTERVAL_FLOOR := 0.35


static func wave_duration_seconds(_wave: int) -> float:
	# §4 table: 60s for waves 1–20 (boss wave still 60s wall-clock; trash is throttled by T/N_max).
	return 60.0


## T(w) = max(0.35, 1.60 − 0.08·w)  — w is 1-based wave index.
static func spawn_interval_seconds(wave: int) -> float:
	if wave == 20:
		return 1.0
	return maxf(SPAWN_INTERVAL_FLOOR, 1.60 - 0.08 * float(wave))


## N_total(w) = round(10 + 4·w + 0.5·w²). Wave 20: §4 override ~75 trash spawns.
## Roadmap §11.1: hard "stop spawning after N_total" is not wired yet (needs sync with wave timer).
## Use for UI / tuning; spawn pressure is currently T(w) + N_max(w) only.
static func n_total_spawns(wave: int) -> int:
	if wave == 20:
		return 75
	return int(round(10.0 + 4.0 * float(wave) + 0.5 * float(wave) * float(wave)))


## N_max(w) = round(16 + 2.5·w + 0.18·w²). Wave 20: N_max = 30.
static func n_max_concurrent(wave: int) -> int:
	if wave == 20:
		return 30
	return int(round(16.0 + 2.5 * float(wave) + 0.18 * float(wave) * float(wave)))


## HP_mult(w) = min(5.0, 1.80 + 0.16·(w − 1))
static func hp_mult(wave: int) -> float:
	return minf(5.0, 1.80 + 0.16 * float(wave - 1))


## DMG_mult(w) = min(2.8, 1.15 + 0.09·(w − 1))
static func dmg_mult(wave: int) -> float:
	return minf(2.8, 1.15 + 0.09 * float(wave - 1))
