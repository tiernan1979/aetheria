# AudioManager.gd
# Autoload as "AudioManager"
# Handles pooled SFX players and music streaming.
# Uses generated procedural sounds (no audio files needed to start).

extends Node

# ── BUS LAYOUT ────────────────────────────────────────────────
# Master > Music
#        > SFX

const SFX_POOL_SIZE = 16
const MUSIC_FADE_TIME = 1.5

var _sfx_pool:   Array[AudioStreamPlayer] = []
var _pool_idx:   int = 0
var _music_player: AudioStreamPlayer = null
var _ambient_player: AudioStreamPlayer = null

# Volume settings (0.0 – 1.0)
var music_volume:   float = 0.65
var sfx_volume:     float = 0.85
var ambient_volume: float = 0.45

func _ready() -> void:
	# SFX pool
	for i in SFX_POOL_SIZE:
		var p = AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_pool.append(p)

	# Music player
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.volume_db = _linear_to_db(music_volume)
	add_child(_music_player)

	# Ambient player (cave sounds, wind)
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = "SFX"
	_ambient_player.volume_db = _linear_to_db(ambient_volume)
	add_child(_ambient_player)

	_ensure_audio_buses()

# ── PLAY SFX ──────────────────────────────────────────────────
# Generates a simple synthesised sound so the game has audio
# without needing .wav files. Replace stream assignments with
# real AudioStreamOggVorbis/WAV when assets are added.

func play(sfx_name: String, pitch_var: float = 0.1) -> void:
	var player = _sfx_pool[_pool_idx]
	_pool_idx = (_pool_idx + 1) % SFX_POOL_SIZE
	if player.playing: player.stop()
	player.stream = _get_synth_stream(sfx_name)
	player.volume_db = _linear_to_db(sfx_volume) + randf_range(-1.5, 1.5)
	player.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	player.play()

func play_at(sfx_name: String, world_pos: Vector2, listener_pos: Vector2) -> void:
	var dist = world_pos.distance_to(listener_pos)
	if dist > 900.0: return
	var vol_fade = 1.0 - clamp(dist / 900.0, 0.0, 1.0)
	var player = _sfx_pool[_pool_idx]
	_pool_idx = (_pool_idx + 1) % SFX_POOL_SIZE
	if player.playing: player.stop()
	player.stream = _get_synth_stream(sfx_name)
	player.volume_db = _linear_to_db(sfx_volume * vol_fade)
	player.pitch_scale = 1.0 + randf_range(-0.08, 0.08)
	player.play()

# ── MUSIC ─────────────────────────────────────────────────────

func play_music(track_name: String) -> void:
	# Crossfade to new track
	if _music_player.playing:
		var fade_out = create_tween()
		fade_out.tween_property(_music_player, "volume_db",
			_linear_to_db(0.0), MUSIC_FADE_TIME)
		fade_out.tween_callback(func():
			_music_player.stop()
			_start_music_track(track_name))
	else:
		_start_music_track(track_name)

func _start_music_track(track_name: String) -> void:
	_music_player.stream = _get_music_stream(track_name)
	_music_player.volume_db = _linear_to_db(0.0)
	_music_player.play()
	var fade_in = create_tween()
	fade_in.tween_property(_music_player, "volume_db",
		_linear_to_db(music_volume), MUSIC_FADE_TIME)

func stop_music() -> void:
	var tw = create_tween()
	tw.tween_property(_music_player, "volume_db", _linear_to_db(0.0), 1.0)
	tw.tween_callback(_music_player.stop)

# ── SYNTH STREAM GENERATOR ────────────────────────────────────
# Returns a short procedurally-generated AudioStreamWAV for each
# sound effect type. Replace these with real audio assets later.

func _get_synth_stream(name: String) -> AudioStreamWAV:
	const RATE = 22050
	var freq: float; var dur: float; var wave: String = "square"
	match name:
		"swing":      freq=320.0; dur=0.08; wave="noise"
		"mine_hit":   freq=180.0; dur=0.06; wave="noise"
		"mine_break": freq=220.0; dur=0.14; wave="noise"
		"pickup":     freq=880.0; dur=0.08; wave="sine"
		"jump":       freq=440.0; dur=0.06; wave="sine"
		"land":       freq=150.0; dur=0.05; wave="noise"
		"hurt":       freq=200.0; dur=0.12; wave="noise"
		"die":        freq=120.0; dur=0.45; wave="noise"
		"enemy_hit":  freq=260.0; dur=0.07; wave="noise"
		"enemy_die":  freq=180.0; dur=0.22; wave="noise"
		"coin":       freq=1320.0;dur=0.07; wave="sine"
		"open_inv":   freq=660.0; dur=0.05; wave="sine"
		"craft":      freq=550.0; dur=0.12; wave="sine"
		"potion":     freq=770.0; dur=0.10; wave="sine"
		"place_tile": freq=200.0; dur=0.05; wave="square"
		_:            freq=330.0; dur=0.08; wave="sine"

	var frames = int(RATE * dur)
	var data   = PackedByteArray()
	data.resize(frames * 2)  # 16-bit mono
	for i in frames:
		var t = float(i) / RATE
		var env = (1.0 - t / dur) ** 0.5  # decay envelope
		var s: float
		match wave:
			"sine":
				s = sin(TAU * freq * t) * env
			"square":
				s = (1.0 if sin(TAU * freq * t) > 0 else -1.0) * env * 0.5
			"noise":
				s = (randf() * 2.0 - 1.0) * env * 0.8
			_:
				s = sin(TAU * freq * t) * env
		var sample = int(clamp(s, -1.0, 1.0) * 32000)
		data[i * 2]     = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF

	var stream = AudioStreamWAV.new()
	stream.format    = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo    = false
	stream.mix_rate  = RATE
	stream.data      = data
	return stream

func _get_music_stream(_track_name: String) -> AudioStream:
	# Placeholder: returns silence. Replace with real OGG tracks.
	# e.g. return load("res://assets/audio/music/overworld.ogg")
	const RATE = 22050
	var dur = 4.0
	var frames = int(RATE * dur)
	var data   = PackedByteArray()
	data.resize(frames * 2)
	# Gentle ambient drone
	for i in frames:
		var t = float(i) / RATE
		var s = sin(TAU * 110.0 * t) * 0.12 + sin(TAU * 165.0 * t) * 0.08
		var sample = int(clamp(s, -1.0, 1.0) * 28000)
		data[i * 2]     = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	var stream = AudioStreamWAV.new()
	stream.format    = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo    = false
	stream.mix_rate  = RATE
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end  = frames - 1
	stream.data      = data
	return stream

# ── UTILS ─────────────────────────────────────────────────────

func _linear_to_db(linear: float) -> float:
	if linear <= 0.0: return -80.0
	return 20.0 * log(linear) / log(10.0)

func _ensure_audio_buses() -> void:
	if AudioServer.get_bus_count() < 3:
		AudioServer.add_bus()
		AudioServer.set_bus_name(1, "Music")
		AudioServer.add_bus()
		AudioServer.set_bus_name(2, "SFX")

func set_music_volume(v: float) -> void:
	music_volume = v
	_music_player.volume_db = _linear_to_db(v)

func set_sfx_volume(v: float) -> void:
	sfx_volume = v
