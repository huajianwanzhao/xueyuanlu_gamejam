extends Node2D
class_name AimArrow

# 幽灵态的「弹飞方向预览」箭头：指向最近的敌人，贴到人身上的瞬间变亮变粗（= 现在点左键就会弹飞它）。
# 由 player.gd 每物理帧更新位置/角度/长度；实体态时整根隐藏。
# 注意：这一根是挂在 current_scene 下的长驻节点，不是 player 的子节点——否则会跟着 player 的 modulate 一起变半透明。

@export var color_free: Color = Color(0.4, 1.0, 0.9, 0.45) # 没贴到人：淡青色
@export var color_locked: Color = Color(0.8, 1.0, 1.0, 1.0) # 贴到了：亮白
@export var thickness: float = 7.0

var aim_length: float = 170.0
var locked: bool = false
var _t: float = 0.0

func _ready() -> void:
	z_index = 90
	visible = false

func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta # 呼吸用
	queue_redraw()

func _draw() -> void:
	var pulse: float = 0.5 + 0.5 * sin(_t * 6.0)
	var base: Color = color_locked if locked else color_free
	var alpha: float = base.a * (0.75 + 0.25 * pulse)
	var c := Color(base.r, base.g, base.b, alpha)
	var th: float = thickness * (1.3 if locked else 1.0)
	var l: float = maxf(aim_length, th * 5.0)
	var head: float = minf(th * 3.8, l * 0.4)
	var tail := Vector2(l - head, 0.0)

	draw_line(Vector2.ZERO, tail, Color(c.r, c.g, c.b, c.a * 0.35), th * 2.2, true)
	draw_line(Vector2.ZERO, tail, c, th, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(l, 0.0),
		Vector2(l - head, head * 0.62),
		Vector2(l - head, -head * 0.62),
	]), c)
