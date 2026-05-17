extends Resource
class_name SpellData

enum School {
	FIRE,
	SHOCK,
	POISON,
	WATER,
	DARK,
	BLOOD,
	ARCANE
}

enum CastType {
	SELF_CAST,
	AUTO_TARGET,
	DIRECTIONAL
}

@export var spell_id: String = ""
@export var spell_name: String = "Unnamed Spell"
@export_multiline var description: String = ""
@export var icon: Texture2D = null
@export var school: School = School.FIRE
@export var cast_type: CastType = CastType.AUTO_TARGET

@export var cooldown: float = 3.0
@export var base_damage: int = 30
@export var detection_range: float = 350.0

@export var spell_scene: PackedScene = null
@export var animation_frames_path: String = ""
@export var effect_radius: float = 72.0
@export var visual_scale: float = 1.0
@export var projectile_speed: float = 320.0
@export var projectile_lifetime: float = 4.0
@export var projectile_scale: float = 1.0
@export var effect_duration: float = 0.4

@export var rank: int = 1
@export var unlock_level: int = 1
