extends Node

# Music + UI sound effects. Music tracks are named by mood and switch per
# context without restarting the same track; click sounds are one-shot
# players so overlapping clicks never cut each other off.

const MUSIC := {
	"menu": "res://audio/Background_music.wav",
	"shift": "res://audio/calm and fun.wav",
	"puzzle": "res://audio/fun music.wav",
	"chat": "res://audio/chat and loading music.wav",
	"final": "res://audio/final level.wav",
	"rock": "res://audio/rock kindoff music.wav",
	"over": "res://audio/game over music.wav",
}

const SFX := {
	"primary": "res://audio/sci fi click sound.wav",
	"simple": "res://audio/simple mouse click.wav",
	"soft": "res://audio/soft mouse click.wav",
	"bubble": "res://audio/bubble tap.wav",
	"tap": "res://audio/tap click.wav",
}

var _player: AudioStreamPlayer = null
var _current := ""
var _streams := {}
var _audio_unlocked := false
var _last_pos := 0.0


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	add_child(_player)
	# Web-only watchdog: right after the tap the browser's audio context
	# resumes asynchronously, and a play() issued too early is swallowed.
	# Every second, if music should be playing but its position hasn't
	# advanced, kick it again - so the bed always starts within ~1s.
	if OS.has_feature("web"):
		var watchdog := Timer.new()
		watchdog.wait_time = 1.0
		watchdog.autostart = true
		add_child(watchdog)
		watchdog.timeout.connect(_watchdog_tick)


func _watchdog_tick() -> void:
	if _current == "" or _player.stream == null:
		return
	var pos := _player.get_playback_position()
	if pos > _last_pos + 0.01:
		_last_pos = pos
		return
	# Stopped or frozen: restart the stream from the top of the track.
	_last_pos = 0.0
	_player.play()


# Web browsers suspend all audio until the first user gesture. On web the
# unlock recreates the music player INSIDE the tap gesture (a player that
# attempted play into the suspended boot context can stay dead), so the
# queued mood starts immediately. Desktop audio starts at boot and works.
func unlock() -> void:
	_audio_unlocked = true
	if _current == "":
		return
	var mood := _current
	var path: String = MUSIC.get(mood, "")
	var stream := _stream(path)
	if stream == null:
		return
	_player.queue_free()
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	add_child(_player)
	_player.stream = stream
	_player.play()


func _input(event: InputEvent) -> void:
	if _audio_unlocked:
		return
	if event is InputEventMouseButton or event is InputEventKey or event is InputEventScreenTouch:
		_audio_unlocked = true
		unlock()


func _stream(path: String) -> AudioStream:
	if not _streams.has(path):
		if not FileAccess.file_exists(path):
			return null
		_streams[path] = load(path)
	return _streams[path]


# Switch the music bed. Same id = keep playing seamlessly.
func music(id: String) -> void:
	var path: String = MUSIC.get(id, "")
	if id == _current or path == "":
		return
	var stream := _stream(path)
	if stream == null:
		return
	if stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamWAV:
		# WAV music loops seamlessly across its whole length.
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = stream.data.size() / (4 if stream.stereo else 2)
	_current = id
	if OS.has_feature("web") and not _audio_unlocked:
		return	# web: queued; unlock() starts it from the tap gesture
	_player.stream = stream
	_player.play()


func stop_music() -> void:
	_current = ""
	_player.stop()


# One-shot click sound; the player frees itself when finished.
func sfx(id: String) -> void:
	var path: String = SFX.get(id, "")
	if path == "" or not FileAccess.file_exists(path):
		return
	var stream := _stream(path)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.bus = "Master"
	player.stream = stream
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
