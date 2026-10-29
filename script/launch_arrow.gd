extends Node2D
class_name LaunchArrow

# 实体化冲击的方向指示箭头：从玩家身上出发、指向敌人被弹飞的方向，0.5 秒内淡出。
# 纯 _draw 绘制，没有贴图依赖；由 script/player.gd 的 _spawn_arrow() 动态 new 出来。

@export var color: Color = Color(0.4, 1.0, 0.9, 1.0)
@export var length: float = 170.0
@export var lifetime: float = 0.5
@export var thickness: float = 9.0

var _t: float = 0.0

func _ready() -> void:
	z_index = 100 # 盖在角色和敌人上面

func _process(delta: float) -> void:
	_t += delta
	if _t >= lifetime:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var k: float = clampf(_t / lifetime, 0.0, 1.0)
	var alpha: float = 1.0 - k * k # 先亮着，后半段快速淡出
	var l: float = length * (1.0 - 0.22 * k) # 稍微缩短一点，像甩出去的
	var head: float = minf(thickness * 3.6, l * 0.45)
	var tail := Vector2(maxf(l - head, 0.0), 0.0)
	var c := Color(color.r, color.g, color.b, color.a * alpha)

	# 外层光晕
	draw_line(Vector2.ZERO, tail, Color(c.r, c.g, c.b, c.a * 0.3), thickness * 2.4, true)
	# 主干
	draw_line(Vector2.ZERO, tail, c, thickness, true)
	# 箭头（三角）
	draw_colored_polygon(PackedVector2Array([
		Vector2(l, 0.0),
		Vector2(l - head, head * 0.62),
		Vector2(l - head, -head * 0.62),
	]), c)
