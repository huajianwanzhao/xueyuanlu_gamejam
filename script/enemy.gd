extends CharacterBody2D
class_name Enemy

enum State { NORMAL, STUNNED, BULLET, DEAD }
var current_state: State = State.NORMAL

@export_group("属性参数")
@export var max_health: float = 100.0
var current_health: float = 100.0

@export_group("移动与弹射")
@export var speed: float = 50.0
@export var attack_id: int = -1
@export var launch_count: int = 0
@export var friction: float = 0.9 # 提高传递效率，连环撞更远
@export var min_chain_speed: float = 500.0 # 连环撞击的保底起飞速度，低于这个值被撞的敌人就只是被推一下

@export_group("伤害参数")
@export var chain_damage_factor: float = 0.06 # 连环撞击伤害 = 撞击速度 × 这个系数（0.2 时 1200 速=240 伤害，必秒杀）
@export var launch_damage: float = 20.0 # 被弹飞时立刻扣的血（原来硬编码 50，配合 0.2 系数会秒杀）
@export var chain_slowdown: float = 0.7 # 撞到敌人后自身保留的速度比例

@export_group("死亡延迟")
@export var death_delay: float = 0.15 

var debug_label: Label
var original_color: Color
var is_vanishing: bool = false 
var is_dying: bool = false 

func _ready() -> void:
	current_health = max_health
	original_color = modulate
	
	debug_label = Label.new()
	debug_label.position = Vector2(-20, -40)
	debug_label.add_theme_color_override("font_color", Color.RED)
	add_child(debug_label)
	_update_debug_label()

func _update_debug_label() -> void:
	if debug_label:
		debug_label.text = "HP: " + str(int(max(0, current_health)))

func _physics_process(delta: float) -> void:
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


func _process_normal(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.current_state == player.State.REAL:
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO


# ================= 子弹移动与连环穿透碰撞 =================
func _process_bullet(delta: float) -> void:
	var motion = velocity * delta
	var next_pos = global_position + motion
	var travel_dir := velocity.normalized()
	var space_state = get_world_2d().direct_space_state
	var exclude_rids: Array[RID] = [get_rid()]
	# 玩家不挡飞行中的敌人：出杆瞬间子弹就贴着玩家，不排除会卡在玩家身体里原地不动
	var player_node = get_tree().get_first_node_in_group("Player")
	if player_node is CollisionObject2D:
		exclude_rids.append(player_node.get_rid())
	
	#【核心修复】不再用射线找敌人，改用和自身等大的圆做重叠查询：
	# 敌人之间本来就贴得很近，射线从贴脸的敌人身体内部出发会漏掉它，
	# 结果就是被撞的敌人只是被物理碰撞挤开一点点——看起来就是「被推开、没有初速度」。
	var target := _find_overlapping_enemy(next_pos, exclude_rids)
	if target:
		# 同一次攻击的子弹互相穿透，绝不互撞卡死
		if target.attack_id == attack_id:
			global_position = next_pos
			return
		if target.current_state == State.DEAD:
			_handle_corpse_hit(target, -travel_dir)
		else:
			_handle_enemy_hit(target, -travel_dir)
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
	if velocity.length() < 20.0:
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


func _handle_enemy_hit(target_enemy: Node2D, normal: Vector2) -> void:
	if target_enemy.attack_id == self.attack_id and target_enemy.launch_count > 0:
		return
		
	var impact_damage = velocity.length() * chain_damage_factor
	print("💥 连环碰撞！", self.name, " 撞了 ", target_enemy.name, "，伤害: ", int(impact_damage))
	
	# 用当前子弹的方向把速度传给它；保底速度保证"被撞开"而不是"被推开"
	var chain_dir = velocity.normalized()
	var chain_speed = maxf(velocity.length() * friction, min_chain_speed) 
	
	# 把巨大的速度传给敌人，让它飞起来
	target_enemy.apply_launch(chain_dir, chain_speed, self.attack_id)
	
	# 然后再扣血
	target_enemy.take_damage(impact_damage)
	
	# 撞击者自身减速，但仍然保持原本的方向高速穿梭，去撞下一个
	velocity *= chain_slowdown 


func _handle_corpse_hit(corpse: Node2D, normal: Vector2) -> void:
	print("🪨 子弹撞到了 ", corpse.name, " 的尸体！")
	corpse.velocity = velocity * 0.8
	velocity = velocity.bounce(normal) * 0.5


func _handle_wall_hit(normal: Vector2) -> void:
	var wall_damage = velocity.length() * 0.2
	print("🧱 撞墙！", self.name, " 受到伤害: ", int(wall_damage))
	take_damage(wall_damage)
	# 撞墙才反弹
	velocity = velocity.bounce(normal) * friction


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
			var impact_damage = velocity.length() * 0.15
			if impact_damage > 10.0:
				print("💀 尸体砸中！", self.name, " 砸了 ", enemy_node.name, " 伤害: ", int(impact_damage))
				enemy_node.take_damage(impact_damage)
				velocity *= 0.5


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


func apply_launch(direction: Vector2, p_speed: float, p_attack_id: int) -> void:
	if current_state == State.DEAD: return
	if attack_id == p_attack_id and launch_count > 0: return
		
	current_state = State.BULLET
	attack_id = p_attack_id
	launch_count += 1
	velocity = direction * p_speed
	modulate = Color(1, 0.4, 0) 
	
	if launch_count == 1:
		take_damage(launch_damage) 
	
	print("🚀 ", name, " 被弹飞！初速度: ", int(p_speed), " 攻击ID: ", attack_id)
	
	await get_tree().create_timer(2.0).timeout
	if current_state == State.BULLET and not is_dying:
		_end_bullet_state()
