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


# Web browsers suspend all audio until the first user gesture. On web the
# unlock plays the queued mood through the browser's own <audio> element,
# issued synchronously inside the gesture. Desktop audio starts at boot
# and works without any unlock.
func unlock() -> void:
	if _current == "":
		return
	var mood := _current
	_current = ""
	if not OS.has_feature("web"):
		return
	_audio_unlocked = true
	var path: String = MUSIC.get(mood, "")
	if path != "" and FileAccess.file_exists(path):
		_js_music(path)


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
	if OS.has_feature("web"):
		# Web: route through the browser's own <audio> element - immune
		# to Godot's web audio driver quirks. Playback waits for unlock().
		if _audio_unlocked:
			_js_music(path)
		return
	_player.stream = stream
	_player.play()


# Web-only: play a music file via JavaScript's native Audio element.
# Files are served next to the build by the web host.
func _js_music(path: String) -> void:
	var file: String = path.get_file().uri_encode()
	JavaScriptBridge.eval("var a = window.__saMusic || (window.__saMusic = new Audio()); a.loop = true; a.src = '/%s'; a.volume = 0.8; a.play();" % file)


func stop_music() -> void:
	_current = ""
	if OS.has_feature("web"):
		JavaScriptBridge.eval("if (window.__saMusic) { window.__saMusic.pause(); }")
	_player.stop()


# One-shot click sound; the player frees itself when finished.
func sfx(id: String) -> void:
	var path: String = SFX.get(id, "")
	if path == "" or not FileAccess.file_exists(path):
		return
	if OS.has_feature("web"):
		# Web: browser-native one-shot Audio element, played inside the
		# button-press gesture so autoplay policy permits it.
		JavaScriptBridge.eval("new Audio('/%s').play();" % path.get_file().uri_encode())
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
