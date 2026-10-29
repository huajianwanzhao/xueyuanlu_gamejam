extends Area2D
class_name EnemyBullet

# 敌人射出的子弹：直线飞行，只有"实体状态"的玩家会被打中（幽灵状态没有碰撞体，免疫）

@export var speed: float = 620.0
@export var lifetime: float = 2.5
@export var radius: float = 7.0

var direction: Vector2 = Vector2.RIGHT
var shooter: Node2D = null
var _age: float = 0.0

func setup(p_direction: Vector2, p_speed: float, p_shooter: Node2D) -> void:
	direction = p_direction.normalized()
	speed = p_speed
	shooter = p_shooter

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_age += delta
	if _age >= lifetime:
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius + 4.0, Color(1.0, 0.3, 0.2, 0.22))
	draw_circle(Vector2.ZERO, radius, Color(0.95, 0.2, 0.15))
	draw_circle(Vector2.ZERO, radius * 0.45, Color(1.0, 0.95, 0.8))

func _on_body_entered(body: Node) -> void:
	if body == shooter:
		return
	if body is Player:
		if body.current_state == body.State.REAL:
			body.take_hit(global_position)
			queue_free()
		return
	# 撞到墙就消失
	if body is StaticBody2D or body is TileMap:
		queue_free()
