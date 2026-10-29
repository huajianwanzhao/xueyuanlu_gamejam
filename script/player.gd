extends CharacterBody2D
class_name Player

enum State { REAL, GHOST }
var current_state: State = State.GHOST

@export_group("移动参数")
@export var ghost_speed: float = 300.0
@export var real_speed: float = 200.0

@export_group("出杆参数")
@export var switch_cooldown: float = 1.0 
@export var search_radius: float = 400.0 # 搜索半径（400很大了，基本屏幕内都能抓到）
@export var sweep_radius: float = 40.0 
@export var launch_base_speed: float = 1200.0 

@export_group("受击")
@export var hit_lockout: float = 1.5 # 被敌人子弹打中后，多久不能再出杆
var can_switch: bool = true
var cooldown_timer: float = 0.0
var current_attack_id: int = 0 

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
		_execute_teleport_impact()
	else:
		_enter_ghost_state()


func _enter_ghost_state() -> void:
	current_state = State.GHOST
	# 用 set_deferred：切状态可能发生在物理回调里（比如被子弹打中）
	collision_shape.set_deferred("disabled", true)
	velocity = Vector2.ZERO
	modulate = Color(1, 1, 1, 0.5) 

func _enter_real_state(new_pos: Vector2) -> void:
	current_state = State.REAL
	global_position = new_pos
	velocity = Vector2.ZERO 
	can_switch = false
	cooldown_timer = switch_cooldown
	modulate = Color(1, 1, 1, 1)
	
	collision_shape.set_deferred("disabled", true)
	await get_tree().create_timer(0.15).timeout
	if current_state == State.REAL:
		collision_shape.set_deferred("disabled", false)


# ================= 核心：纯数学暴力寻敌 =================
func _execute_teleport_impact() -> void:
	var from_pos := global_position
	var mouse_pos := get_global_mouse_position()
	var launch_dir := (mouse_pos - from_pos).normalized()
	
	if launch_dir == Vector2.ZERO:
		launch_dir = Vector2.RIGHT

	current_attack_id += 1 
	
	# 在场景树中直接找到所有 Enemy 类
	var all_enemies = get_tree().root.find_children("*", "Enemy", true, false)
	var primary_target: Enemy = null
	var min_dist: float = INF
	
	for e in all_enemies:
		if e is Enemy:
			# 如果已经死了，跳过
			if e.current_state == e.State.DEAD: 
				continue
				
			# 计算敌人距离玩家的距离（受 search_radius 限制）
			var dist_to_player = from_pos.distance_to(e.global_position)
			if dist_to_player <= search_radius:
				# 找离鼠标最近的那个敌人
				var dist_to_mouse = e.global_position.distance_to(mouse_pos)
				if dist_to_mouse < min_dist:
					min_dist = dist_to_mouse
					primary_target = e

	var to_pos = mouse_pos # 默认落点
	
	if primary_target:
		# 强制把落点设为目标敌人面前
		to_pos = primary_target.global_position - (launch_dir * 15.0)
		print("🎯 锁定目标: ", primary_target.name, " (距鼠标: ", int(min_dist), "px)")
	else:
		print("⚠️ 出杆落空。搜索半径内没找到活着的 Enemy。")

	# 路径扫掠：找起点到终点这条线段附近的敌人
	var path_enemies = []
	for e in all_enemies:
		if e is Enemy and e != primary_target and e.current_state != e.State.DEAD:
			# 点到线段的最短距离
			var dist_to_line = _point_to_line_distance(e.global_position, from_pos, to_pos)
			if dist_to_line <= sweep_radius:
				path_enemies.append(e)

	for enemy in path_enemies:
		var dir = (to_pos - from_pos).normalized()
		enemy.apply_path_stun(dir)
		print("✅ 路径扫到: ", enemy.name)
			
	# 执行弹射
	if primary_target:
		primary_target.apply_launch(launch_dir, launch_base_speed, current_attack_id)
		print("🔥 终点弹射命中: ", primary_target.name)
		
	_enter_real_state(to_pos)




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


# 辅助数学函数：计算点到线段的距离
func _point_to_line_distance(point: Vector2, line_start: Vector2, line_end: Vector2) -> float:
	var line_vec = line_end - line_start
	var line_len = line_vec.length()
	if line_len == 0: return point.distance_to(line_start)
	
	var t = max(0, min(1, (point - line_start).dot(line_vec) / (line_len * line_len)))
	var projection = line_start + t * line_vec
	return point.distance_to(projection)
