extends Node

# =============================================================================
# AudioManager — Global Autoload
# =============================================================================
# One central place to play all sound effects in the game.
# Any script can call:
#   AudioManager.play_sfx("shop/reroll/dice_grab")
#   AudioManager.play_sequence(["shop/reroll/dice_grab", "shop/reroll/dice_shake_3", "shop/reroll/dice_roll_3"], [0.0, 0.25, 0.55])
#
# Sounds live in: res://assets/audio/sfx/
# Just pass the path relative to that folder, no extension needed.
# =============================================================================

# How many AudioStreamPlayers to keep ready for overlapping sounds.
# (e.g. rapid shooting needs multiple players so sounds don't cut each other off)
const POOL_SIZE := 8
const SFX_BASE_PATH := "res://assets/audio/sfx/"

# Pool of AudioStreamPlayers for one-shot SFX playback
var _players: Array[AudioStreamPlayer] = []

# Cache loaded sounds so we don't reload from disk every time
var _cache: Dictionary = {}


func _ready() -> void:
	# Create the pool of players and add them as children of this node
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"  # Route through the SFX audio bus
		add_child(player)
		_players.append(player)


# -----------------------------------------------------------------------------
# play_sfx(sound_name: String, volume_db: float)
# -----------------------------------------------------------------------------
# Plays a single sound effect. Finds a free player from the pool.
#
# sound_name — path relative to res://assets/audio/sfx/, no extension
#              e.g. "shop/reroll/dice_grab"
# volume_db  — volume in decibels. 0 = full, -10 = quieter, -80 = silent
# -----------------------------------------------------------------------------
func play_sfx(sound_name: String, volume_db: float = 0.0) -> void:
	var stream := _load_sound(sound_name)
	if stream == null:
		push_warning("AudioManager: Could not load sound: " + sound_name)
		return

	# Find a player that isn't currently playing
	var player := _get_free_player()
	player.stream = stream
	player.volume_db = volume_db
	player.play()


# -----------------------------------------------------------------------------
# play_sequence(sound_names: Array[String], delays: Array[float], volume_db)
# -----------------------------------------------------------------------------
# Plays a list of sounds one after another with custom delays between them.
# Great for multi-part sounds like the dice reroll: grab → shake → roll
#
# sound_names — list of sound paths (same format as play_sfx)
# delays      — list of times in seconds to wait before each sound plays.
#               delays[0] = delay before first sound (usually 0.0)
#               delays[1] = delay before second sound, etc.
# volume_db   — applied to all sounds in the sequence
# -----------------------------------------------------------------------------
func play_sequence(sound_names: Array[String], delays: Array[float], volume_db: float = 0.0) -> void:
	# Make sure we have a delay value for each sound (pad with 0 if missing)
	for i in sound_names.size():
		var delay: float = delays[i] if i < delays.size() else 0.0
		if delay <= 0.0:
			play_sfx(sound_names[i], volume_db)
		else:
			# Use a timer to delay this specific sound in the sequence
			_play_delayed(sound_names[i], delay, volume_db)


# -----------------------------------------------------------------------------
# Private helpers
# -----------------------------------------------------------------------------

func _play_delayed(sound_name: String, delay: float, volume_db: float) -> void:
	# Wait for 'delay' seconds then play the sound
	# get_tree().create_timer() is Godot's lightweight one-shot timer
	await get_tree().create_timer(delay).timeout
	play_sfx(sound_name, volume_db)


func _load_sound(sound_name: String) -> AudioStream:
	# Return cached version if we've loaded this before
	if _cache.has(sound_name):
		return _cache[sound_name]

	# Try loading as .wav first, then .ogg (music files will be .ogg)
	var path_wav := SFX_BASE_PATH + sound_name + ".wav"
	var path_ogg := SFX_BASE_PATH + sound_name + ".ogg"

	var stream: AudioStream = null
	if ResourceLoader.exists(path_wav):
		stream = load(path_wav)
	elif ResourceLoader.exists(path_ogg):
		stream = load(path_ogg)

	if stream != null:
		_cache[sound_name] = stream  # Cache it for next time

	return stream


func _get_free_player() -> AudioStreamPlayer:
	# Find the first player that isn't currently playing
	for player in _players:
		if not player.playing:
			return player

	# If all players are busy, steal the oldest one (first in the pool)
	# This prevents sounds from piling up endlessly during heavy combat
	return _players[0]
