extends Node

# Music + UI sound effects. Music tracks are named by mood and switch per
# context without restarting the same track; click sounds are one-shot
# players so overlapping clicks never cut each other off.

const MUSIC := {
	"menu": "res://Background_music.mp3",
	"shift": "res://calm and fun.mp3",
	"puzzle": "res://fun music.mp3",
	"chat": "res://chat and loading music.mp3",
	"final": "res://final level.mp3",
	"rock": "res://rock kindoff music.mp3",
	"over": "res://game over music.mp3",
}

const SFX := {
	"primary": "res://sci fi click sound.mp3",
	"simple": "res://simple mouse click.mp3",
	"soft": "res://soft mouse click.mp3",
	"bubble": "res://bubble tap.mp3",
	"tap": "res://tap click.mp3",
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


# Web browsers suspend all audio until the first user gesture. Probing
# showed a play() issued synchronously INSIDE the tap gesture works, while
# delayed restarts can be swallowed - so unlock restarts the queued mood
# immediately, in the gesture itself.
func unlock() -> void:
	if _current == "":
		return
	var mood := _current
	_current = ""
	var path: String = MUSIC.get(mood, "")
	var stream := _stream(path)
	if stream == null:
		return
	if stream is AudioStreamMP3:
		stream.loop = true
	# Brand-new player created INSIDE the gesture: the diagnostic probe
	# proved a fresh player + play() at the tap sounds, while reusing a
	# player that already attempted play into a suspended context can
	# stay dead on web no matter how often it is restarted.
	_player.queue_free()
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	add_child(_player)
	_current = mood
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
	_current = id
	_player.stream = stream
	_player.play()


func stop_music() -> void:
	_current = ""
	_player.stop()


# One-shot click sound; the player frees itself when finished.
func sfx(id: String) -> void:
	var stream := _stream(SFX.get(id, ""))
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.bus = "Master"
	player.stream = stream
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
