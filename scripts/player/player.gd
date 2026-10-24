extends CharacterBody2D
## 玩家：左右移动 + 跳跃（含可变跳跃高度）+ 掉落死亡。
## 手感参数全在 Inspector 里改，不用碰代码。
##
## 外观三级自动降级，美术换图时一行代码都不用改：
##   1) 有 player_frames.tres  -> 逐帧动画
##   2) 有 player_idle.png     -> 单张静态图，自动缩放到 32x56
##   3) 都没有                  -> 纯色块占位（默认）
##
## 不管用哪一级，跳跃/落地都有程序做的挤压拉伸（Inspector 里可关）。

signal died

const FRAMES_PATH: String = "res://assets/sprites/player/player_frames.tres"
const SPRITE_PATH: String = "res://assets/sprites/player/player_idle.png"
const ANIM_IDLE: StringName = &"idle"
const ANIM_RUN: StringName = &"run"
const ANIM_JUMP: StringName = &"jump"
const ANIM_DIE: StringName = &"die"
## 碰撞盒尺寸，静态图按这个高度自动缩放
const BODY_SIZE: Vector2 = Vector2(32, 56)

@export_group("手感")
@export var speed: float = 380.0
@export var jump_force: float = 1120.0
@export var gravity: float = 3000.0
@export var max_fall_speed: float = 1800.0
## 掉到这个 y 以下就算死（世界坐标）
@export var death_y: float = 920.0

@export_group("动效")
## 跳跃/落地挤压拉伸的强度，0 = 完全关掉
@export_range(0.0, 1.0) var squash_strength: float = 0.22

var _dead: bool = false
var _squash_tween: Tween

@onready var _visual_root: Node2D = $VisualRoot
@onready var _visual: ColorRect = $VisualRoot/Visual
@onready var _sprite: Sprite2D = $VisualRoot/Sprite
@onready var _anim: AnimatedSprite2D = $VisualRoot/Anim


func _ready() -> void:
	_setup_visual()


func _physics_process(delta: float) -> void:
	if _dead:
		return

	var was_on_floor: bool = is_on_floor()

	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)

	var direction: float = Input.get_axis("move_left", "move_right")
	velocity.x = direction * speed

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -jump_force
		AudioManager.play_sfx("jump")
		_squash(Vector2(0.82, 1.18))
	# 松开跳跃键立刻减速 -> 短按小跳、长按大跳
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.45

	move_and_slide()

	if not was_on_floor and is_on_floor():
		_squash(Vector2(1.2, 0.8))

	if global_position.y > death_y:
		_die()
		return

	_update_anim(direction)


# ---------- 外观 ----------

func _setup_visual() -> void:
	if ResourceLoader.exists(FRAMES_PATH):
		var frames: SpriteFrames = load(FRAMES_PATH) as SpriteFrames
		if frames != null and not frames.get_animation_names().is_empty():
			_anim.sprite_frames = frames
			_show_only(_anim)
			_play(ANIM_IDLE)
			return

	if ResourceLoader.exists(SPRITE_PATH):
		var tex: Texture2D = load(SPRITE_PATH) as Texture2D
		if tex != null and tex.get_height() > 0:
			_sprite.texture = tex
			var s: float = BODY_SIZE.y / float(tex.get_height())
			_sprite.scale = Vector2(s, s)
			_sprite.flip_h = false
			_show_only(_sprite)
			return


func _show_only(node: Node) -> void:
	_visual.visible = node == _visual
	_sprite.visible = node == _sprite
	_anim.visible = node == _anim


func _update_anim(direction: float) -> void:
	if _sprite.visible:
		_sprite.flip_h = direction < 0.0
		# 没有跑步动画时，用轻微倾斜装作在动
		_sprite.rotation = deg_to_rad(-4.0) * signf(direction) if is_on_floor() and absf(direction) > 0.1 else 0.0
		return

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


## 挤压拉伸：只动外观，不动碰撞盒
func _squash(target: Vector2) -> void:
	if squash_strength <= 0.0:
		return
	if _squash_tween != null:
		_squash_tween.kill()
	var t: Vector2 = Vector2(lerpf(1.0, target.x, squash_strength), lerpf(1.0, target.y, squash_strength))
	_squash_tween = create_tween()
	_squash_tween.tween_property(_visual_root, "scale", t, 0.06)
	_squash_tween.tween_property(_visual_root, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _die() -> void:
	if _dead:
		return
	_dead = true
	_play(ANIM_DIE)
	died.emit()
