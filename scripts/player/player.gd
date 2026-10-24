extends CharacterBody2D
## 玩家：左右移动 + 跳跃（含可变跳跃高度）+ 掉落死亡。
## 手感参数全在 Inspector 里改，不用碰代码。
##
## 外观两种状态，自动切换：
##   1) 没做美术 -> 用 ColorRect 纯色块占位（默认）
##   2) 美术做完 -> 把 SpriteFrames 存到 FRAMES_PATH，自动改用动画，代码一行不用改

signal died

## 有帧动画就自动用；没有就继续用纯色块
const FRAMES_PATH: String = "res://assets/sprites/player/player_frames.tres"
## 这些动画名要和 SpriteFrames 里的一致；缺哪个就跳过哪个
const ANIM_IDLE: StringName = &"idle"
const ANIM_RUN: StringName = &"run"
const ANIM_JUMP: StringName = &"jump"
const ANIM_DIE: StringName = &"die"

@export_group("手感")
@export var speed: float = 190.0
@export var jump_force: float = 560.0
@export var gravity: float = 1500.0
@export var max_fall_speed: float = 900.0
## 掉到这个 y 以下就算死（世界坐标）
@export var death_y: float = 460.0

var _dead: bool = false

@onready var _visual: ColorRect = $Visual
@onready var _anim: AnimatedSprite2D = $Anim


func _ready() -> void:
	_setup_visual()


func _physics_process(delta: float) -> void:
	if _dead:
		return

	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)

	var direction: float = Input.get_axis("move_left", "move_right")
	velocity.x = direction * speed

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -jump_force
		AudioManager.play_sfx("jump")
	# 松开跳跃键立刻减速 -> 短按小跳、长按大跳
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.45

	move_and_slide()

	if global_position.y > death_y:
		_die()
		return

	_update_anim(direction)


# ---------- 外观 ----------

func _setup_visual() -> void:
	if not ResourceLoader.exists(FRAMES_PATH):
		return
	var frames: SpriteFrames = load(FRAMES_PATH) as SpriteFrames
	if frames == null or frames.get_animation_names().is_empty():
		return
	_anim.sprite_frames = frames
	_anim.visible = true
	_visual.visible = false
	_play(ANIM_IDLE)


func _update_anim(direction: float) -> void:
	if not _anim.visible:
		return
	_anim.flip_h = direction < 0.0
	if not is_on_floor():
		_play(ANIM_JUMP)
	elif absf(direction) > 0.1:
		_play(ANIM_RUN)
	else:
		_play(ANIM_IDLE)


func _play(anim: StringName) -> void:
	var frames: SpriteFrames = _anim.sprite_frames
	if frames == null or not frames.has_animation(anim):
		return
	if _anim.animation == anim and _anim.is_playing():
		return
	_anim.play(anim)


func _die() -> void:
	if _dead:
		return
	_dead = true
	_play(ANIM_DIE)
	died.emit()
