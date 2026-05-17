extends RefCounted
class_name SpellTreeData

const PROJECTILE_SCENE_PATH := "res://scenes/spells/effects/SpellProjectile.tscn"
const AREA_SCENE_PATH := "res://scenes/spells/effects/RingOfFireEffect.tscn"

const ICON_FIREBALL := "res://assets/vfx/magic/magic_pack_14/FireStar/Sprites/f-6.png"
const ICON_RING_OF_FIRE := "res://assets/vfx/magic/magic_pack_16/ring_of_fire/sprites/frame-08.png"

const SPELL_UNLOCK_ORDER: Array[String] = [
	"fireball",
	"spark_bolt",
	"ring_of_fire",
	"water_drop",
	"dark_bolt",
	"acid_glob",
	"explosive_fireball",
	"splash_burst",
	"chain_lightning",
	"toxic_burst",
	"fire_bomb",
	"wave",
	"void_orb",
	"pillar_fireball",
	"lightning_strike",
	"poison_cloud",
	"smoke_curse",
	"small_meteor",
	"pulse_beam",
	"water_whirl",
	"green_vortex",
	"electric_burst",
	"skull_shot",
	"electric_field",
	"black_hole",
	"blood_explosion",
]

static var _spell_definitions_cache: Dictionary = {}
static var _spell_cache: Dictionary = {}


static func get_spell_ids_in_unlock_order() -> Array[String]:
	return SPELL_UNLOCK_ORDER.duplicate()


static func get_spell_definition(spell_id: String) -> Dictionary:
	return get_spell_definitions().get(spell_id, {}).duplicate(true)


static func get_spell_definitions() -> Dictionary:
	if not _spell_definitions_cache.is_empty():
		return _spell_definitions_cache

	_spell_definitions_cache = {
		"fireball": _spell_def(
			"Fireball",
			"Hurl a fast fire orb into the nearest threat.",
			SpellData.School.FIRE,
			SpellData.CastType.AUTO_TARGET,
			1,
			2.2,
			34,
			470.0,
			PROJECTILE_SCENE_PATH,
			[],
			{"icon_path": ICON_FIREBALL, "projectile_speed": 360.0}
		),
		"spark_bolt": _spell_def(
			"Spark Bolt",
			"Snap a quick lightning shot straight along your move direction.",
			SpellData.School.SHOCK,
			SpellData.CastType.DIRECTIONAL,
			2,
			1.8,
			24,
			490.0,
			PROJECTILE_SCENE_PATH,
			["fireball"],
			{"projectile_speed": 420.0, "projectile_scale": 0.9}
		),
		"ring_of_fire": _spell_def(
			"Ring of Fire",
			"Explode a close-range fire circle around yourself.",
			SpellData.School.FIRE,
			SpellData.CastType.SELF_CAST,
			3,
			4.0,
			45,
			0.0,
			AREA_SCENE_PATH,
			["fireball"],
			{
				"icon_path": ICON_RING_OF_FIRE,
				"effect_radius": 72.0,
				"visual_scale": 1.25,
				"effect_duration": 0.55,
				"animation_frames_path": "res://assets/vfx/magic/magic_pack_16/ring_of_fire/sprites"
			}
		),
		"water_drop": _spell_def(
			"Water Drop",
			"Send a clean water shot at the nearest target.",
			SpellData.School.WATER,
			SpellData.CastType.AUTO_TARGET,
			4,
			2.0,
			28,
			500.0,
			PROJECTILE_SCENE_PATH,
			[],
			{"projectile_speed": 340.0}
		),
		"dark_bolt": _spell_def(
			"Dark Bolt",
			"Launch a heavy dark projectile that hits harder than it looks.",
			SpellData.School.DARK,
			SpellData.CastType.AUTO_TARGET,
			5,
			2.8,
			42,
			460.0,
			PROJECTILE_SCENE_PATH,
			[],
			{"projectile_speed": 300.0, "projectile_scale": 1.1}
		),
		"acid_glob": _spell_def(
			"Acid Glob",
			"Lob a poison glob that trades speed for damage.",
			SpellData.School.POISON,
			SpellData.CastType.AUTO_TARGET,
			6,
			2.6,
			38,
			430.0,
			PROJECTILE_SCENE_PATH,
			[],
			{"projectile_speed": 280.0, "projectile_scale": 1.05}
		),
		"explosive_fireball": _spell_def(
			"Explosive Fireball",
			"A bigger fireball with a longer recharge and harder hit.",
			SpellData.School.FIRE,
			SpellData.CastType.AUTO_TARGET,
			7,
			3.0,
			52,
			480.0,
			PROJECTILE_SCENE_PATH,
			["fireball"],
			{"icon_path": ICON_FIREBALL, "rank": 2, "projectile_scale": 1.15}
		),
		"splash_burst": _spell_def(
			"Splash Burst",
			"Release a short water pulse that clips anything crowding you.",
			SpellData.School.WATER,
			SpellData.CastType.SELF_CAST,
			8,
			3.2,
			32,
			0.0,
			AREA_SCENE_PATH,
			["water_drop"],
			{"effect_radius": 80.0, "visual_scale": 1.05, "effect_duration": 0.42}
		),
		"chain_lightning": _spell_def(
			"Chain Lightning",
			"Fire a stronger lightning shot in the direction you are steering.",
			SpellData.School.SHOCK,
			SpellData.CastType.DIRECTIONAL,
			9,
			2.5,
			39,
			500.0,
			PROJECTILE_SCENE_PATH,
			["spark_bolt"],
			{"projectile_speed": 430.0, "rank": 2}
		),
		"toxic_burst": _spell_def(
			"Toxic Burst",
			"Pop a poison blast around yourself to clear melee pressure.",
			SpellData.School.POISON,
			SpellData.CastType.SELF_CAST,
			10,
			3.4,
			36,
			0.0,
			AREA_SCENE_PATH,
			["acid_glob"],
			{"effect_radius": 86.0, "visual_scale": 1.1, "effect_duration": 0.45}
		),
		"fire_bomb": _spell_def(
			"Fire Bomb",
			"Drop a hotter, wider fire detonation on top of yourself.",
			SpellData.School.FIRE,
			SpellData.CastType.SELF_CAST,
			11,
			3.8,
			58,
			0.0,
			AREA_SCENE_PATH,
			["explosive_fireball"],
			{"effect_radius": 92.0, "visual_scale": 1.2, "effect_duration": 0.48}
		),
		"wave": _spell_def(
			"Wave",
			"Push out a broader water surge that rewards close timing.",
			SpellData.School.WATER,
			SpellData.CastType.SELF_CAST,
			12,
			3.7,
			44,
			0.0,
			AREA_SCENE_PATH,
			["splash_burst"],
			{"effect_radius": 98.0, "visual_scale": 1.28, "effect_duration": 0.5}
		),
		"void_orb": _spell_def(
			"Void Orb",
			"Fire a dense dark orb that hits hard and moves slow.",
			SpellData.School.DARK,
			SpellData.CastType.AUTO_TARGET,
			13,
			3.3,
			55,
			470.0,
			PROJECTILE_SCENE_PATH,
			["dark_bolt"],
			{"projectile_speed": 250.0, "projectile_scale": 1.2, "rank": 2}
		),
		"pillar_fireball": _spell_def(
			"Pillar Fireball",
			"Upgrade the fire branch into a slower hit with boss-ready damage.",
			SpellData.School.FIRE,
			SpellData.CastType.AUTO_TARGET,
			14,
			3.8,
			68,
			500.0,
			PROJECTILE_SCENE_PATH,
			["explosive_fireball"],
			{"icon_path": ICON_FIREBALL, "rank": 3, "projectile_speed": 320.0, "projectile_scale": 1.25}
		),
		"lightning_strike": _spell_def(
			"Lightning Strike",
			"Launch a fast high-voltage bolt wherever you are facing.",
			SpellData.School.SHOCK,
			SpellData.CastType.DIRECTIONAL,
			15,
			2.1,
			47,
			520.0,
			PROJECTILE_SCENE_PATH,
			["chain_lightning"],
			{"projectile_speed": 500.0, "projectile_scale": 1.0, "rank": 3}
		),
		"poison_cloud": _spell_def(
			"Poison Cloud",
			"Spread a larger poison bloom over the space around you.",
			SpellData.School.POISON,
			SpellData.CastType.SELF_CAST,
			16,
			4.0,
			48,
			0.0,
			AREA_SCENE_PATH,
			["toxic_burst"],
			{"effect_radius": 108.0, "visual_scale": 1.35, "effect_duration": 0.56}
		),
		"smoke_curse": _spell_def(
			"Smoke Curse",
			"Blanket nearby enemies in a dark burst with a sharp damage spike.",
			SpellData.School.DARK,
			SpellData.CastType.SELF_CAST,
			17,
			4.1,
			52,
			0.0,
			AREA_SCENE_PATH,
			["void_orb"],
			{"effect_radius": 96.0, "visual_scale": 1.22, "effect_duration": 0.52}
		),
		"small_meteor": _spell_def(
			"Small Meteor",
			"Call down a compact fire slam right on your position.",
			SpellData.School.FIRE,
			SpellData.CastType.SELF_CAST,
			18,
			4.6,
			74,
			0.0,
			AREA_SCENE_PATH,
			["pillar_fireball"],
			{"effect_radius": 112.0, "visual_scale": 1.4, "effect_duration": 0.62}
		),
		"pulse_beam": _spell_def(
			"Pulse Beam",
			"Emit a tight shock pulse that clears a ring around you.",
			SpellData.School.SHOCK,
			SpellData.CastType.SELF_CAST,
			19,
			3.5,
			46,
			0.0,
			AREA_SCENE_PATH,
			["lightning_strike"],
			{"effect_radius": 90.0, "visual_scale": 1.12, "effect_duration": 0.44}
		),
		"water_whirl": _spell_def(
			"Water Whirl",
			"Spin a wide water ring that punishes enemies already on top of you.",
			SpellData.School.WATER,
			SpellData.CastType.SELF_CAST,
			20,
			4.4,
			58,
			0.0,
			AREA_SCENE_PATH,
			["wave"],
			{"effect_radius": 118.0, "visual_scale": 1.48, "effect_duration": 0.62}
		),
		"green_vortex": _spell_def(
			"Green Vortex",
			"Turn the poison branch into a heavier close-range wipe.",
			SpellData.School.POISON,
			SpellData.CastType.SELF_CAST,
			21,
			4.8,
			64,
			0.0,
			AREA_SCENE_PATH,
			["poison_cloud"],
			{"effect_radius": 124.0, "visual_scale": 1.55, "effect_duration": 0.66}
		),
		"electric_burst": _spell_def(
			"Electric Burst",
			"Detonate a short lightning burst around the player.",
			SpellData.School.SHOCK,
			SpellData.CastType.SELF_CAST,
			22,
			3.2,
			40,
			0.0,
			AREA_SCENE_PATH,
			["lightning_strike"],
			{"effect_radius": 84.0, "visual_scale": 1.04, "effect_duration": 0.4}
		),
		"skull_shot": _spell_def(
			"Skull Shot",
			"Fire a grim projectile that keeps dark damage on demand.",
			SpellData.School.BLOOD,
			SpellData.CastType.AUTO_TARGET,
			23,
			2.7,
			50,
			510.0,
			PROJECTILE_SCENE_PATH,
			["void_orb"],
			{"projectile_speed": 360.0, "projectile_scale": 1.08}
		),
		"electric_field": _spell_def(
			"Electric Field",
			"Spread your lightning branch into a larger personal shock zone.",
			SpellData.School.SHOCK,
			SpellData.CastType.SELF_CAST,
			24,
			4.5,
			60,
			0.0,
			AREA_SCENE_PATH,
			["electric_burst"],
			{"effect_radius": 116.0, "visual_scale": 1.42, "effect_duration": 0.6}
		),
		"black_hole": _spell_def(
			"Black Hole",
			"Collapse the dark branch into a huge close-range blast.",
			SpellData.School.DARK,
			SpellData.CastType.SELF_CAST,
			25,
			5.2,
			72,
			0.0,
			AREA_SCENE_PATH,
			["smoke_curse"],
			{"effect_radius": 132.0, "visual_scale": 1.62, "effect_duration": 0.72}
		),
		"blood_explosion": _spell_def(
			"Blood Explosion",
			"Cash out the blood branch with a brutal point-blank detonation.",
			SpellData.School.BLOOD,
			SpellData.CastType.SELF_CAST,
			26,
			5.6,
			82,
			0.0,
			AREA_SCENE_PATH,
			["smoke_curse"],
			{"effect_radius": 128.0, "visual_scale": 1.58, "effect_duration": 0.68}
		),
	}

	return _spell_definitions_cache


static func get_spell(spell_id: String) -> SpellData:
	if _spell_cache.has(spell_id):
		return _spell_cache[spell_id]

	var spell_def := get_spell_definition(spell_id)
	if spell_def.is_empty():
		return null

	var spell := SpellData.new()
	spell.spell_id = spell_id
	spell.spell_name = spell_def["name"]
	spell.description = spell_def["description"]
	spell.school = spell_def["school"]
	spell.cast_type = spell_def["cast_type"]
	spell.cooldown = spell_def["cooldown"]
	spell.base_damage = spell_def["base_damage"]
	spell.detection_range = spell_def["detection_range"]
	spell.effect_radius = spell_def["effect_radius"]
	spell.visual_scale = spell_def["visual_scale"]
	spell.projectile_speed = spell_def["projectile_speed"]
	spell.projectile_lifetime = spell_def["projectile_lifetime"]
	spell.projectile_scale = spell_def["projectile_scale"]
	spell.effect_duration = spell_def["effect_duration"]
	spell.rank = spell_def["rank"]
	spell.unlock_level = spell_def["unlock_level"]
	spell.animation_frames_path = spell_def["animation_frames_path"]

	var scene_path: String = spell_def["scene_path"]
	if ResourceLoader.exists(scene_path):
		spell.spell_scene = load(scene_path) as PackedScene

	var icon_path: String = spell_def["icon_path"]
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		spell.icon = load(icon_path) as Texture2D

	_spell_cache[spell_id] = spell
	return spell


static func get_unlocks_for_level(level: int) -> Array[String]:
	var unlocked_now: Array[String] = []
	for spell_id in SPELL_UNLOCK_ORDER:
		if get_unlock_level(spell_id) == level:
			unlocked_now.append(spell_id)
	return unlocked_now


static func get_unlock_level(spell_id: String) -> int:
	var spell_def := get_spell_definition(spell_id)
	return int(spell_def.get("unlock_level", 999))


static func get_branches() -> Array[Dictionary]:
	return [
		{
			"id": "fire",
			"name": "Fire",
			"color": "Red",
			"nodes": [
				_node("fireball", "Fireball", true),
				_node("explosive_fireball", "Explosive\nFireball", true),
				_node("pillar_fireball", "Pillar\nFireball", true),
			],
			"side_spells": ["Fire Bomb", "Ring of Fire", "Small Meteor"],
		},
		{
			"id": "shock",
			"name": "Lightning",
			"color": "Blue",
			"nodes": [
				_node("spark_bolt", "Spark\nBolt", true),
				_node("chain_lightning", "Chain\nLightning", false),
				_node("lightning_strike", "Lightning\nStrike", true),
				_node("electric_burst", "Electric\nBurst", true),
				_node("electric_field", "Electric\nField", true),
			],
			"side_spells": ["Pulse Beam"],
		},
		{
			"id": "poison",
			"name": "Poison",
			"color": "Purple",
			"nodes": [
				_node("acid_glob", "Acid\nGlob", false),
				_node("toxic_burst", "Toxic\nBurst", true),
				_node("poison_cloud", "Poison\nCloud", true),
				_node("green_vortex", "Green\nVortex", true),
			],
			"side_spells": [],
		},
		{
			"id": "water",
			"name": "Water",
			"color": "White",
			"nodes": [
				_node("water_drop", "Water\nDrop", true),
				_node("splash_burst", "Splash\nBurst", true),
				_node("wave", "Wave", true),
				_node("water_whirl", "Water\nWhirl", true),
			],
			"side_spells": [],
		},
		{
			"id": "dark",
			"name": "Dark",
			"color": "Grey",
			"nodes": [
				_node("dark_bolt", "Dark\nBolt", true),
				_node("void_orb", "Void\nOrb", false),
				_node("smoke_curse", "Smoke\nCurse", true),
				_node("black_hole", "Black\nHole", true),
			],
			"side_spells": ["Skull Shot", "Blood Explosion"],
		},
	]


static func _node(id: String, label: String, has_art: bool) -> Dictionary:
	return {
		"id": id,
		"label": label,
		"has_art": has_art,
	}


static func _spell_def(
	name: String,
	description: String,
	school: SpellData.School,
	cast_type: SpellData.CastType,
	unlock_level: int,
	cooldown: float,
	base_damage: int,
	detection_range: float,
	scene_path: String,
	prerequisites: Array[String],
	overrides: Dictionary = {}
) -> Dictionary:
	var spell_def := {
		"name": name,
		"description": description,
		"school": school,
		"cast_type": cast_type,
		"unlock_level": unlock_level,
		"cooldown": cooldown,
		"base_damage": base_damage,
		"detection_range": detection_range,
		"scene_path": scene_path,
		"prerequisites": prerequisites.duplicate(),
		"icon_path": "",
		"animation_frames_path": "",
		"effect_radius": 72.0,
		"visual_scale": 1.0,
		"projectile_speed": 320.0,
		"projectile_lifetime": 4.0,
		"projectile_scale": 1.0,
		"effect_duration": 0.4,
		"rank": 1,
	}
	for key in overrides.keys():
		spell_def[key] = overrides[key]
	return spell_def
