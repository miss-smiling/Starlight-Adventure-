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


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	add_child(_player)


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
