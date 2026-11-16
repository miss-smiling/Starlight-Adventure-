extends SceneTree

# Verification: every converted WAV must load and be 44100 Hz.

func _init() -> void:
	var ok := true
	for file in ["Background_music", "calm and fun", "chat and loading music",
			"final level", "fun music", "game over music", "rock kindoff music",
			"bubble tap", "tap click", "sci fi click sound",
			"simple mouse click", "soft mouse click"]:
		var path: String = "res://audio/" + file + ".wav"
		if not FileAccess.file_exists(path):
			print("WAVCHECK %s MISSING" % file)
			ok = false
			continue
		var s: AudioStreamWAV = load(path)
		if s == null:
			print("WAVCHECK %s LOAD FAIL" % file)
			ok = false
		else:
			print("WAVCHECK %s rate=%d stereo=%s len=%.1f" % [file, s.mix_rate, s.stereo, s.get_length()])
			if s.mix_rate != 44100:
				ok = false
	print("WAVCHECK %s" % ("ALL OK" if ok else "PROBLEMS FOUND"))
	quit()
