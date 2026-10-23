extends Node
## 极简音频管理：文件存在就播，不存在就静默。
## 好处：先写逻辑，音效后补，不用改代码。
## 目录：assets/audio/sfx/<名字>.wav   assets/audio/music/<名字>.ogg

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const SFX_COUNT := 8

var _sfx: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer


func _ready() -> void:
	for i in SFX_COUNT:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -6.0
	add_child(_music)


func play_sfx(sound_name: String, volume_db: float = 0.0) -> void:
	var stream := _load_stream(SFX_DIR + sound_name, [".wav", ".ogg"])
	if stream == null:
		return
	var p := _sfx[0]
	for candidate in _sfx:
		if not candidate.playing:
			p = candidate
			break
	p.stream = stream
	p.volume_db = volume_db
	p.play()


func play_music(music_name: String, volume_db: float = -6.0) -> void:
	var stream := _load_stream(MUSIC_DIR + music_name, [".ogg", ".wav"])
	if stream == null:
		return
	if _music.stream == stream and _music.playing:
		return
	_music.stream = stream
	_music.volume_db = volume_db
	_music.play()


func stop_music() -> void:
	_music.stop()


func _load_stream(base_path: String, extensions: Array) -> AudioStream:
	for ext in extensions:
		var path: String = base_path + ext
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return null
