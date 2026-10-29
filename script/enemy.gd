extends CharacterBody2D
class_name Enemy

enum State { NORMAL, STUNNED, BULLET, DEAD, AIMING }
var current_state: State = State.NORMAL

@export_group("属性参数")
@export var max_health: float = 100.0
var current_health: float = 100.0

@export_group("移动与弹射")
@export var speed: float = 50.0
@export var attack_id: int = -1
@export var launch_count: int = 0
@export var min_chain_speed: float = 500.0 # 连环撞击的保底起飞速度（按正碰程度打折），低于这个值被撞的敌人就只是被推一下

@export_group("碰撞物理")
@export var restitution: float = 0.85 # 恢复系数 e：1=完全弹性（正碰两球交换速度），0=完全非弹性（撞完一起走）
@export var chain_damage_factor: float = 0.06 # 撞击伤害 = 法向相对速度 × 这个系数（擦边几乎没伤害）
@export var launch_damage: float = 20.0 # 被弹飞时立刻扣的血
@export var corpse_damage_factor: float = 0.12 # 尸体砸人的伤害系数（也按法向相对速度算）
@export var stop_speed: float = 150.0 # 速度低于这个就当球停住了，结束飞行状态（真实台球也会被滚动摩擦停下）

@export_group("射击")
@export var can_shoot: bool = true # 这个敌人会不会开枪
@export var shoot_range: float = 520.0 # 看到实体玩家 + 进入这个距离，就开始瞄准
@export var aim_time: float = 1.0 # 瞄准（预警）时间：玩家有 1 秒时间跑开或切回幽灵
@export var shoot_cooldown: float = 2.5 # 打一发之后要等多久才能再瞄
@export var bullet_speed: float = 620.0

@export_group("死亡延迟")
@export var death_delay: float = 0.15 

var debug_label: Label
var original_color: Color
var is_vanishing: bool = false 
var is_dying: bool = false 

const BULLET_SCENE := preload("res://scenes/enemy_bullet.tscn")
var aim_timer: float = 0.0
var shoot_cooldown_timer: float = 0.0
var aim_target: Node2D = null
var aim_line: Line2D = null

var player:Node

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	current_health = max_health
	original_color = modulate
	
	debug_label = Label.new()
	debug_label.position = Vector2(-20, -40)
	debug_label.add_theme_color_override("font_color", Color.RED)
	add_child(debug_label)
	_update_debug_label()
	_create_aim_line()

func _update_debug_label() -> void:
	if debug_label:
		debug_label.text = "HP: " + str(int(max(0, current_health)))

func _physics_process(delta: float) -> void:
	if shoot_cooldown_timer > 0.0:
		shoot_cooldown_timer = maxf(0.0, shoot_cooldown_timer - delta)
	# 只要不是瞄准状态，预警线一律收起来（被撞飞、被扫晕时自动生效）
	if current_state != State.AIMING and aim_line and aim_line.visible:
		aim_line.visible = false
	
	match current_state:
		State.NORMAL:
			_process_normal(delta)
		State.STUNNED:
			velocity = velocity.move_toward(Vector2.ZERO, 500 * delta)
			move_and_slide()
		State.BULLET:
			_process_bullet(delta)
		State.DEAD:
			_process_dead(delta)
		State.AIMING:
			_process_aiming(delta)


func _process_normal(delta: float) -> void:
	if player and player.current_state == player.State.REAL:
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * speed
		move_and_slide()
		# 看到实体玩家 → 停下来瞄准
		if _can_start_aim(player):
			_start_aiming(player)
	else:
		velocity = Vector2.ZERO


# ================= 射击：瞄准 → 开火 ===================
func _can_start_aim(player: Node) -> bool:
	if not can_shoot: return false
	if shoot_cooldown_timer > 0.0: return false
	return global_position.distance_to(player.global_position) <= shoot_range

func _create_aim_line() -> void:
	aim_line = Line2D.new()
	aim_line.width = 2.0
	aim_line.default_color = Color(1.0, 0.15, 0.15, 0.2)
	aim_line.z_index = 6
	aim_line.visible = false
	add_child(aim_line)

func _start_aiming(player: Node2D) -> void:
	current_state = State.AIMING
	aim_target = player
	aim_timer = aim_time
	velocity = Vector2.ZERO
	if aim_line:
		aim_line.visible = true
	print("🎯 ", name, " 开始瞄准")

func _process_aiming(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	if aim_target == null or not is_instance_valid(aim_target):
		_stop_aiming(0.0)
		return
	# 玩家切回幽灵、或者跑出射程 → 放弃瞄准（这就是 1 秒预警的意义）
	if aim_target.current_state != aim_target.State.REAL or global_position.distance_to(aim_target.global_position) > shoot_range * 1.15:
		_stop_aiming(0.4)
		return
	aim_timer -= delta
	var progress: float = clampf(1.0 - aim_timer / maxf(aim_time, 0.01), 0.0, 1.0)
	_update_aim_line(progress)
	if aim_timer <= 0.0:
		_fire()

func _update_aim_line(progress: float) -> void:
	if aim_line == null: return
	aim_line.points = PackedVector2Array([Vector2.ZERO, to_local(aim_target.global_position)])
	aim_line.width = 2.0 + 3.0 * progress
	aim_line.default_color = Color(1.0, 0.2, 0.15, 0.15 + 0.75 * progress)

func _fire() -> void:
	var dir: Vector2 = (aim_target.global_position - global_position).normalized()
	var bullet = BULLET_SCENE.instantiate()
	var host: Node = get_tree().current_scene
	if host == null: host = get_parent()
	host.add_child(bullet)
	bullet.global_position = global_position + dir * 95.0
	bullet.setup(dir, bullet_speed, self)
	shoot_cooldown_timer = shoot_cooldown
	print("🔫 ", name, " 开火！")
	_stop_aiming(0.0)

func _stop_aiming(extra_cooldown: float) -> void:
	if aim_line:
		aim_line.visible = false
	aim_target = null
	if current_state == State.AIMING:
		current_state = State.NORMAL
	if extra_cooldown > 0.0:
		shoot_cooldown_timer = maxf(shoot_cooldown_timer, extra_cooldown)


# ================= 子弹移动与连环穿透碰撞 =================
func _process_bullet(delta: float) -> void:
	var motion = velocity * delta
	var next_pos = global_position + motion
	var travel_dir := velocity.normalized()
	var space_state = get_world_2d().direct_space_state
	var exclude_rids: Array[RID] = [get_rid()]
	# 玩家不挡飞行中的敌人：出杆瞬间子弹就贴着玩家，不排除会卡在玩家身体里原地不动
	if player is CollisionObject2D:
		exclude_rids.append(player.get_rid())
	
	#【核心修复】不再用射线找敌人，改用和自身等大的圆做重叠查询：
	# 敌人之间本来就贴得很近，射线从贴脸的敌人身体内部出发会漏掉它，
	# 结果就是被撞的敌人只是被物理碰撞挤开一点点——看起来就是「被推开、没有初速度」。
	var target := _find_overlapping_enemy(next_pos, exclude_rids)
	if target:
		# 同一次攻击的子弹互相穿透，绝不互撞卡死
		if target.attack_id == attack_id:
			global_position = next_pos
			return
		# 法线一律取「两球球心连线」，这是真实碰撞法线；飞行方向只在正碰时才和它重合
		var contact_normal: Vector2 = (target.global_position - global_position).normalized()
		if target.current_state == State.DEAD:
			_handle_corpse_hit(target, contact_normal)
		else:
			_handle_enemy_hit(target, contact_normal)
		# 撞完人直接穿透过去，绝不卡在原地
		global_position = next_pos
	else:
		var query := PhysicsRayQueryParameters2D.create(global_position, next_pos)
		query.exclude = exclude_rids
		query.collision_mask = 0xFFFFFFFF
		var result := space_state.intersect_ray(query)
		if result and (result.collider is StaticBody2D or result.collider is TileMap):
			_handle_wall_hit(result.normal)
			global_position = result.position - travel_dir * 2.0
		else:
			# 什么都没撞到、或撞到打不动的物体（比如玩家），继续飞
			global_position = next_pos
	
	# 速度太低了才停下
	if velocity.length() < stop_speed:
		_end_bullet_state()


# 用自身大小的圆在目标位置做重叠查询，找出最近的一个敌人
func _find_overlapping_enemy(at_pos: Vector2, exclude_rids: Array[RID]) -> Node2D:
	var radius := 60.0
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs and cs.shape is CircleShape2D:
		radius = (cs.shape as CircleShape2D).radius
	var circle := CircleShape2D.new()
	circle.radius = radius
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = circle
	params.transform = Transform2D(0.0, at_pos)
	params.collision_mask = collision_mask
	params.exclude = exclude_rids
	var hits := get_world_2d().direct_space_state.intersect_shape(params, 8)
	var best: Node2D = null
	var best_dist := INF
	for h in hits:
		var c = h.collider
		if c == self or not (c is Enemy):
			continue
		var d: float = at_pos.distance_to(c.global_position)
		if d < best_dist:
			best_dist = d
			best = c
	return best


# 等质量两球的对心碰撞（沿法线交换冲量，切向速度完全不变）
# v1/v2：两球速度；n：从 1 指向 2 的单位法线；e：恢复系数
# 返回 [v1', v2', 法向相对速度]。法向相对速度 <= 0 说明两球正在分开，不产生冲量。
static func sphere_collision(v1: Vector2, v2: Vector2, n: Vector2, e: float) -> Array:
	var approach: float = (v1 - v2).dot(n)
	if approach <= 0.0:
		return [v1, v2, 0.0]
	var j: float = (1.0 + e) * 0.5 * approach
	return [v1 - n * j, v2 + n * j, approach]


func _handle_enemy_hit(target_enemy: Node2D, normal: Vector2) -> void:
	if target_enemy.attack_id == self.attack_id and target_enemy.launch_count > 0:
		return

	# 【真实物理】正碰和斜碰的差别全在法线上：
	#   法线 = 两球球心连线。正碰时法线和飞行方向重合 → 速度几乎全传过去、自己停下；
	#   斜碰时法线是斜的 → 只有法向分量传过去，切向分量留在自己身上，自己顺着切线滑走。
	var v1: Vector2 = velocity
	var v2: Vector2 = target_enemy.velocity
	var res: Array = sphere_collision(v1, v2, normal, restitution)
	var approach: float = res[2]
	if approach <= 0.0:
		return # 本来就在互相远离，没有冲量
	var v1_new: Vector2 = res[0]
	var v2_new: Vector2 = res[1]

	# 正碰程度 = 法向相对速度 / 自身速度，0=完全擦边，1=正面撞
	var head_on: float = clampf(approach / maxf(v1.length(), 1.0), 0.0, 1.0)
	# 伤害只看「怼上去」的那部分速度：擦边几乎不掉血
	var impact_damage: float = approach * chain_damage_factor

	# 保底起飞速度也按正碰程度打折，否则擦一下也会被弹飞，斜碰就没区别了
	var floor_speed: float = min_chain_speed * head_on
	if v2_new.length() < floor_speed:
		var dir2: Vector2 = normal if v2_new.length() < 1.0 else v2_new.normalized()
		v2_new = dir2 * floor_speed

	print("💥 ", self.name, " 撞 ", target_enemy.name, "｜正碰度 ", int(head_on * 100.0), "%｜伤害 ", int(impact_damage), "｜传给对方 ", int(v2_new.length()))

	target_enemy.apply_launch_velocity(v2_new, self.attack_id, impact_damage)

	# 卡肉：撞得越正、顿得越狠（擦边几乎不卡），连撞时才有一路「砰砰砰」的节奏
	GameManager.hit_stop(lerpf(0.025, 0.06, head_on), 0.05)

	# 自己保留剩余速度：正碰会几乎停住（变成接力），斜碰会顺着切线滑过去
	velocity = v1_new
	if velocity.length() < stop_speed:
		_end_bullet_state()


func _handle_corpse_hit(corpse: Node2D, normal: Vector2) -> void:
	# 尸体也是等质量的球，只是不会「起飞」：照样按冲量交换速度
	var res: Array = sphere_collision(velocity, corpse.velocity, normal, restitution)
	if res[2] <= 0.0:
		return
	corpse.velocity = res[1]
	velocity = res[0]
	print("🪨 ", self.name, " 撞上 ", corpse.name, " 的尸体，尸体被推着滑走")
	GameManager.hit_stop(0.03, 0.06) # 撞尸体只轻轻卡一下


func _handle_wall_hit(normal: Vector2) -> void:
	var wall_damage = velocity.length() * 0.2
	print("🧱 撞墙！", self.name, " 受到伤害: ", int(wall_damage))
	take_damage(wall_damage)
	# 撞墙反弹：法向速度反向、按恢复系数损失能量
	velocity = velocity.bounce(normal) * restitution


func _end_bullet_state() -> void:
	if is_dying: return 
	if current_state == State.DEAD: return
	
	current_state = State.NORMAL
	velocity = Vector2.ZERO
	modulate = original_color


# ================= 尸体的物理滑行与消失 =================
func _process_dead(delta: float) -> void:
	if is_vanishing: return

	velocity = velocity.move_toward(Vector2.ZERO, 800 * delta)
	move_and_slide()
	
	if velocity.length() < 5.0:
		_vanishing_corpse()
		return 
		
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var other = collision.get_collider()
		
		var enemy_node = other
		if not enemy_node.has_method("take_damage") and enemy_node.get_parent() and enemy_node.get_parent().has_method("take_damage"):
			enemy_node = enemy_node.get_parent()
			
		if enemy_node.has_method("take_damage") and enemy_node != self and enemy_node.current_state != State.DEAD:
			# 尸体砸人同样是球撞球：只算怼上去的那部分速度，擦过去不算
			var n: Vector2 = enemy_node.global_position - global_position
			if n.length() < 0.001:
				n = velocity.normalized()
			n = n.normalized()
			var approach: float = (velocity - enemy_node.velocity).dot(n)
			if approach <= 0.0:
				continue
			var corpse_damage: float = approach * corpse_damage_factor
			if corpse_damage > 10.0:
				print("💀 尸体砸中！", self.name, " 砸了 ", enemy_node.name, " 伤害 ", int(corpse_damage))
				enemy_node.take_damage(corpse_damage)
				var res: Array = sphere_collision(velocity, enemy_node.velocity, n, restitution)
				velocity = res[0]
				enemy_node.apply_path_stun(n)


func _vanishing_corpse() -> void:
	is_vanishing = true
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.4)
	
	await tween.finished
	queue_free()


# ================= 伤害与死亡 =================
func take_damage(amount: float) -> void:
	if current_state == State.DEAD or is_dying: return
	
	current_health -= amount
	_update_debug_label()
	
	modulate = Color(1, 1, 1, 1)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 0.2, 0.2), 0.05)
	
	if current_health <= 0:
		_dying_delay()

func _dying_delay() -> void:
	is_dying = true
	print("💀 ", name, " 濒死，进入延迟...")
	
	var tween = create_tween().set_loops(3)
	tween.tween_property(self, "modulate:a", 0.2, 0.03)
	tween.tween_property(self, "modulate:a", 1.0, 0.03)
	
	await get_tree().create_timer(death_delay).timeout
	
	if current_state != State.DEAD:
		_die()


func _die() -> void:
	print("☠️ ", name, " 死亡！变为尸体")
	GameManager.hit_stop(0.05, 0.05) # 打死人也要有一点停顿感
	is_dying = false
	current_state = State.DEAD
	modulate = Color(0.3, 0.3, 0.3)
	debug_label.text = "DEAD"


# ================= 接口 =================
func apply_path_stun(direction: Vector2) -> void:
	if current_state == State.BULLET or current_state == State.DEAD or is_dying: return
	current_state = State.STUNNED
	velocity = direction * 150.0
	modulate = Color(0.5, 0.5, 0.5)
	await get_tree().create_timer(0.4).timeout
	if current_state == State.STUNNED:
		current_state = State.NORMAL
		modulate = original_color


# 直接给定撞完之后应该有的速度向量（真实碰撞算出来的结果）。
# 和 apply_launch 的区别：速度不是猜的，是法向冲量算出来的。
func apply_launch_velocity(p_velocity: Vector2, p_attack_id: int, p_impact_damage: float = 0.0) -> void:
	if current_state == State.DEAD: return
	if attack_id == p_attack_id and launch_count > 0: return

	current_state = State.BULLET
	attack_id = p_attack_id
	launch_count += 1
	velocity = p_velocity
	modulate = Color(1, 0.4, 0)

	if launch_count == 1:
		take_damage(launch_damage)
	if p_impact_damage > 0.0:
		take_damage(p_impact_damage)

	print("🚀 ", name, " 起飞：速度 ", int(velocity.length()), "  方向 ", velocity.normalized())

	await get_tree().create_timer(2.0).timeout
	if current_state == State.BULLET and not is_dying:
		_end_bullet_state()


func apply_launch(direction: Vector2, p_speed: float, p_attack_id: int) -> void:
	await apply_launch_velocity(direction.normalized() * p_speed, p_attack_id)
