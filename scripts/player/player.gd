extends CharacterBody2D
## 玩家：左右移动 + 跳跃（含可变跳跃高度）+ 掉落死亡。
## 手感参数全在 Inspector 里改，不用碰代码。

signal died

@export_group("手感")
@export var speed: float = 190.0
@export var jump_force: float = 560.0
@export var gravity: float = 1500.0
@export var max_fall_speed: float = 900.0
## 掉到这个 y 以下就算死（世界坐标）
@export var death_y: float = 460.0

var _dead: bool = false


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


func _die() -> void:
	if _dead:
		return
	_dead = true
	died.emit()
