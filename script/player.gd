extends CharacterBody2D
class_name Player

enum State { REAL, GHOST }
var current_state: State = State.GHOST

@export_group("移动参数")
@export var ghost_speed: float = 300.0
@export var real_speed: float = 200.0

@export_group("出杆（实体化冲击）")
@export var switch_cooldown: float = 1.0 
@export var overlap_launch_speed: float = 2600.0 # 实体化瞬间把重叠敌人弹飞的速度，要「非常大」
@export var overlap_impact_damage: float = 30.0 # 每次实体化冲击额外扣的血
@export var arrow_length: float = 170.0 # 弹飞方向箭头的长度
@export var arrow_color: Color = Color(0.4, 1.0, 0.9, 1.0) # 箭头颜色

@export_group("受击")
@export var hit_lockout: float = 1.5 # 被敌人子弹打中后，多久不能再出杆
var can_switch: bool = true
var cooldown_timer: float = 0.0
var current_attack_id: int = 0 

# 弹飞方向指示箭头（纯绘制节点，见 script/launch_arrow.gd）
const ARROW_SCRIPT := preload("res://script/launch_arrow.gd")

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	_enter_ghost_state()

func _physics_process(delta: float) -> void:
	if not can_switch:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			can_switch = true

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if current_state == State.GHOST:
		velocity = input_dir * ghost_speed
	else:
		velocity = input_dir * real_speed
	
	move_and_slide()

	if Input.is_action_just_pressed("switch_state"):
		_try_switch_state()


func _try_switch_state() -> void:
	if not can_switch: return

	if current_state == State.GHOST:
		# 幽灵态能穿过敌人，所以「实体化」就是唯一的攻击手段：
		# 贴着敌人点一下，把自己变成实体，重叠的敌人被撞飞。
		_materialize_impact()
		_enter_real_state()
	else:
		_enter_ghost_state()


func _enter_ghost_state() -> void:
	current_state = State.GHOST
	# 用 set_deferred：切状态可能发生在物理回调里（比如被子弹打中）
	collision_shape.set_deferred("disabled", true)
	velocity = Vector2.ZERO
	modulate = Color(1, 1, 1, 0.5) 

func _enter_real_state() -> void:
	current_state = State.REAL
	velocity = Vector2.ZERO 
	can_switch = false
	cooldown_timer = switch_cooldown
	modulate = Color(1, 1, 1, 1)
	
	# 实体化后 0.15 秒无敌帧：碰撞体晚一点打开，避免刚实体化就被贴脸的敌人顶飞
	collision_shape.set_deferred("disabled", true)
	await get_tree().create_timer(0.15).timeout
	if current_state == State.REAL:
		collision_shape.set_deferred("disabled", false)


# ================= 核心：实体化冲击 =================
# 幽灵态没有碰撞体、可以自由穿过敌人；变回实体的那一瞬间，
# 凡是和自己碰撞体积有重合的敌人，都沿「两个圆心的连线」被弹飞出去。
func _materialize_impact() -> void:
	var targets := _find_overlapping_enemies()
	if targets.is_empty():
		return # 没贴到人，就是安静地变回实体

	current_attack_id += 1
	for enemy in targets:
		# 方向 = 两球球心连线（从自己指向对方），和敌人自己怎么动无关
		var dir: Vector2 = enemy.global_position - global_position
		if dir.length() < 0.001:
			dir = Vector2.RIGHT
		dir = dir.normalized()

		_spawn_arrow(dir)
		enemy.apply_launch_velocity(dir * overlap_launch_speed, current_attack_id, overlap_impact_damage)
		print("💥 实体化冲击: ", enemy.name, " 弹飞速度 ", int(overlap_launch_speed), " 方向 ", dir)


# 用自己碰撞体那个圆做一次重叠查询，找出真正和玩家重合的敌人
func _find_overlapping_enemies() -> Array:
	var result: Array = []
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = _overlap_shape()
	params.transform = global_transform
	params.collide_with_areas = false
	params.collide_with_bodies = true
	var exclude: Array[RID] = [get_rid()]
	params.exclude = exclude

	var hits := get_world_2d().direct_space_state.intersect_shape(params, 16)
	for h in hits:
		var c = h.collider
		if c is Enemy and c.current_state != c.State.DEAD:
			result.append(c)
	return result


func _overlap_shape() -> Shape2D:
	if collision_shape and collision_shape.shape:
		return collision_shape.shape.duplicate()
	var fallback := CircleShape2D.new()
	fallback.radius = 85.0
	return fallback


# 箭头：从自己身上出发、指向弹飞方向，0.5 秒内淡出
func _spawn_arrow(dir: Vector2) -> void:
	var host: Node = get_tree().current_scene
	if host == null: host = get_parent()
	if host == null: return
	var arrow = ARROW_SCRIPT.new()
	arrow.length = arrow_length
	arrow.color = arrow_color
	host.add_child(arrow)
	arrow.global_position = global_position
	arrow.rotation = dir.angle()



# ================= 挨打 ===================
# 敌人子弹命中：实体状态才会被打中（幽灵状态没有碰撞体，免疫）
func take_hit(from_pos: Vector2) -> void:
	if current_state != State.REAL:
		return
	print("💢 玩家被击中，强制打回幽灵状态")
	_enter_ghost_state()
	can_switch = false
	cooldown_timer = hit_lockout
	modulate = Color(1.0, 0.35, 0.35, 0.85)
	await get_tree().create_timer(0.25).timeout
	if current_state == State.GHOST:
		modulate = Color(1, 1, 1, 0.5)
