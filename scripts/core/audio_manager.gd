## audio_manager.gd
## 音频管理器 — Autoload 单例，管理 BGM 和 SFX 播放
## 在 project.godot 中设为 Autoload: AudioManager

extends Node

# ============ BGM 轨道映射 ============
const BGM_TRACKS := {
	"menu": "res://resources/audio/bgm/menu.wav",
	"day": "res://resources/audio/bgm/day.wav",
	"dusk": "res://resources/audio/bgm/dusk.wav",
	"night": "res://resources/audio/bgm/night.wav",
	"boss": "res://resources/audio/bgm/boss.mp3",
}

# ============ SFX 轨道映射 ============
const SFX_TRACKS := {
	"pioneer_attack": "res://resources/audio/sfx/pioneer_attack.wav",
	"defender_attack": "res://resources/audio/sfx/defender_attack.mp3",
	"sniper_attack": "res://resources/audio/sfx/sniper_attack.ogg",
	"button_click": "res://resources/audio/sfx/button_click.mp3",
	"button_hover": "res://resources/audio/sfx/button_hover.mp3",
	"upgrade": "res://resources/audio/sfx/upgrade.mp3",
	"mine": "res://resources/audio/sfx/mine.mp3",
	"victory": "res://resources/audio/sfx/victory.mp3",
	"defeat": "res://resources/audio/sfx/defeat.mp3",
}

# ============ 音量 ============
var music_volume: float = 0.22
var sfx_volume: float = 1.0

# ============ BGM 播放器（双播放器交叉淡入淡出）============
var _bgm_a: AudioStreamPlayer
var _bgm_b: AudioStreamPlayer
var _current_bgm: AudioStreamPlayer
var _current_bgm_name: String = ""
var _crossfade_tween: Tween

# ============ SFX 播放器池 ============
var _sfx_pool: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE := 8

# ============ 流缓存 ============
var _cache: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bgm_a = AudioStreamPlayer.new()
	_bgm_a.name = "BGM_A"
	add_child(_bgm_a)
	_bgm_b = AudioStreamPlayer.new()
	_bgm_b.name = "BGM_B"
	add_child(_bgm_b)
	_current_bgm = _bgm_a
	for i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.name = "SFX_%d" % i
		add_child(p)
		_sfx_pool.append(p)
	print("[AudioManager] 初始化完成")


# ============ BGM 控制 ============

func play_bgm(track_name: String, fade: float = 0.8) -> void:
	if track_name == _current_bgm_name:
		return
	if not BGM_TRACKS.has(track_name):
		push_warning("[AudioManager] 未知 BGM: %s" % track_name)
		return
	var stream := _load(BGM_TRACKS[track_name], true)
	if not stream:
		return
	_current_bgm_name = track_name
	var new_p := _bgm_b if _current_bgm == _bgm_a else _bgm_a
	var old_p := _current_bgm
	new_p.stream = stream
	new_p.volume_db = _vol(music_volume)
	new_p.play()
	if _crossfade_tween and _crossfade_tween.is_valid():
		_crossfade_tween.kill()
	_crossfade_tween = create_tween().set_parallel(true)
	_crossfade_tween.tween_property(old_p, "volume_db", -80.0, fade)
	_crossfade_tween.chain().tween_callback(old_p.stop)
	_crossfade_tween.tween_property(new_p, "volume_db", _vol(music_volume), fade)
	_current_bgm = new_p


func stop_bgm(fade: float = 0.5) -> void:
	_current_bgm_name = ""
	if _crossfade_tween and _crossfade_tween.is_valid():
		_crossfade_tween.kill()
	# fade=0 时立即停止（不用 tween，避免 time_scale=0 时冻结导致 BGM 不停）
	if fade <= 0.0:
		_bgm_a.stop()
		_bgm_b.stop()
		return
	if _bgm_a.playing:
		var tw := create_tween()
		tw.tween_property(_bgm_a, "volume_db", -80.0, fade)
		tw.tween_callback(_bgm_a.stop)
	if _bgm_b.playing:
		var tw := create_tween()
		tw.tween_property(_bgm_b, "volume_db", -80.0, fade)
		tw.tween_callback(_bgm_b.stop)


## 暂停/恢复 BGM 播放（游戏暂停时调用，不影响 SFX）
func set_bgm_paused(paused: bool) -> void:
	_bgm_a.stream_paused = paused
	_bgm_b.stream_paused = paused


# ============ SFX 控制 ============

func play_sfx(track_name: String, vol_mult: float = 1.0) -> void:
	if not SFX_TRACKS.has(track_name):
		return
	var stream := _load(SFX_TRACKS[track_name], false)
	if not stream:
		return
	for p in _sfx_pool:
		if not p.playing:
			p.stream = stream
			p.volume_db = _vol(sfx_volume * vol_mult)
			p.play()
			return
	# 池满 → 覆盖第一个
	_sfx_pool[0].stream = stream
	_sfx_pool[0].volume_db = _vol(sfx_volume * vol_mult)
	_sfx_pool[0].play()


# ============ 音量 ============

func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	var db := _vol(music_volume)
	if _bgm_a.playing:
		_bgm_a.volume_db = db
	if _bgm_b.playing:
		_bgm_b.volume_db = db


func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)


# ============ 辅助 ============

func _load(path: String, loop: bool = false) -> AudioStream:
	var cache_key := path + ("|loop" if loop else "|noloop")
	if _cache.has(cache_key):
		return _cache[cache_key]
	if not FileAccess.file_exists(path):
		push_warning("[AudioManager] 文件不存在: %s" % path)
		return null
	var s := load(path) as AudioStream
	if s:
		# 仅 BGM 设置循环播放（SFX 不循环，避免按键音效无限循环）
		if loop:
			_set_loop(s)
		_cache[cache_key] = s
	return s


## 按音频格式设置循环播放
func _set_loop(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
		(stream as AudioStreamWAV).loop_begin = 0
		(stream as AudioStreamWAV).loop_end = (stream as AudioStreamWAV).data.size()
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true


static func _vol(v: float) -> float:
	if v <= 0.0:
		return -80.0
	return linear_to_db(v)
