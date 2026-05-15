extends Resource

class_name WaveSpawnEntry

@export var enemy_scene: PackedScene
@export var weight: float = 10.0
## Per-type cap. 0 = unlimited (roadmap uses global N_max only).
@export var max_alive: int = 0