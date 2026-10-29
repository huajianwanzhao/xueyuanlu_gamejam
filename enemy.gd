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
@export var friction: float = 0.85 # 稍微调高了传递效率

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


# ================= 子弹移动与碰撞 =================
func _process_bullet(delta: float) -> void:
	var motion = velocity * delta
	var next_pos = global_position + motion
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, next_pos)
	query.exclude = [get_rid()]
	query.collision_mask = 0xFFFFFFFF 
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var collider = result.collider
		var normal = result.normal
		
		var enemy_node = collider
		if not enemy_node.has_method("take_damage") and enemy_node.get_parent() and enemy_node.get_parent().has_method("take_damage"):
			enemy_node = enemy_node.get_parent()
			
		if enemy_node.has_method("take_damage"):
			# 【核心修复1】如果是同一次攻击产生的子弹，直接穿透，不反弹！
			if enemy_node.attack_id == self.attack_id:
				global_position = next_pos
				return
				
			if enemy_node != self and enemy_node.current_state != State.DEAD:
				_handle_enemy_hit(enemy_node, normal)
				# 【核心修复2】撞击者直接穿过去，不要停留在原地，也不要反弹
				global_position = next_pos 
			elif enemy_node.current_state == State.DEAD:
				_handle_corpse_hit(enemy_node, normal)
				global_position = result.position - velocity.normalized() * 2.0
				
		elif collider is StaticBody2D or collider is TileMap:
			_handle_wall_hit(normal)
			global_position = result.position - velocity.normalized() * 2.0
	else:
		global_position = next_pos
		
	# 速度太低了才停下
	if velocity.length() < 20.0:
		_end_bullet_state()


func _handle_enemy_hit(target_enemy: Node2D, normal: Vector2) -> void:
	if target_enemy.attack_id == self.attack_id and target_enemy.launch_count > 0:
		return
		
	var impact_damage = velocity.length() * 0.2
	print("💥 连环碰撞！", self.name, " 撞了 ", target_enemy.name, "，伤害: ", int(impact_damage))
	
	# 传递速度
	var chain_dir = velocity.normalized()
	var chain_speed = velocity.length() * friction
	target_enemy.apply_launch(chain_dir, chain_speed, self.attack_id)
	
	# 扣血
	target_enemy.take_damage(impact_damage)
	
	# 【核心修复3】撞击者自身减速，但保持原方向不反弹，这样它可以继续撞下一个人
	velocity *= 0.6 


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
		take_damage(50.0) 
	
	print("🚀 ", name, " 被弹飞！初速度: ", int(p_speed), " 攻击ID: ", attack_id)
	
	await get_tree().create_timer(2.0).timeout
	if current_state == State.BULLET and not is_dying:
		_end_bullet_state()
