@tool
class_name RobotVisual
extends Node2D
# 扫地机器人占位美术：纯代码绘制，不用贴图。
# 原点 = 底盘中心（正好是碰撞圆心），椭圆压缩暗示斜俯视。
# 以后换成真美术：把这个节点换成 Sprite2D 就行，碰撞体和逻辑都不用动。

@export_group("尺寸")
@export var radius: float = 85.0 # 底盘半径（= 碰撞半径）
@export var squash: float = 0.62 # 椭圆压缩比，越小越"趴"、透视越强
@export var side_depth: float = 14.0 # 侧壁厚度（像素），圆盘的"高度"

@export_group("外观")
@export var body_color: Color = Color(0.36, 0.72, 0.9)
@export var accent_color: Color = Color(0.85, 1.0, 1.0)
@export var shadow_color: Color = Color(0.0, 0.0, 0.0, 0.34)

# 腾空高度：被打飞时把圆盘抬起来、影子留在地上
var lift: float = 0.0


func _ready() -> void:
	queue_redraw()


func set_lift(v: float) -> void:
	if is_equal_approx(v, lift):
		return
	lift = maxf(v, 0.0)
	queue_redraw()


func _draw() -> void:
	var ry: float = radius * squash
	var c := Vector2(0.0, -lift)

	# 1. 接触阴影：永远贴地；腾空越高越小越淡
	var k: float = 1.0 - clampf(lift / 140.0, 0.0, 0.6)
	var sc: Color = shadow_color
	sc.a = shadow_color.a * k
	_fill_ellipse(Vector2(0.0, ry * 0.62), radius * 1.04 * k, ry * 1.04 * k, sc)

	# 2. 侧壁：整个底圆往下挪 side_depth，最后只露出下沿一条月牙 = 圆盘厚度
	_fill_ellipse(c + Vector2(0.0, side_depth), radius, ry, body_color.darkened(0.52))
	# 侧壁高光（左下受光）
	_fill_ellipse(c + Vector2(-radius * 0.22, side_depth * 0.95), radius * 0.55, ry * 0.34, body_color.darkened(0.32))

	# 3. 顶面
	_fill_ellipse(c, radius, ry, body_color)
	# 顶面外圈高光
	_ring_ellipse(c, radius * 0.93, ry * 0.93, body_color.lightened(0.34), 3.0)

	# 4. 顶盖上的结构：中心盖 + 内圈 + 挡板
	_fill_ellipse(c, radius * 0.5, ry * 0.5, body_color.darkened(0.12))
	_fill_ellipse(c, radius * 0.34, ry * 0.34, body_color.darkened(0.28))
	_ring_ellipse(c, radius * 0.5, ry * 0.5, body_color.darkened(0.42), 2.0)

	# 5. 前挡板（下方一段圆弧，暗示"正面"朝屏幕下方）
	var bumper := PackedVector2Array()
	for i in 25:
		var a: float = PI * (0.12 + 0.76 * float(i) / 24.0)
		bumper.append(c + Vector2(cos(a) * radius * 0.99, sin(a) * ry * 0.99))
	draw_polyline(bumper, body_color.darkened(0.4), 5.0, true)

	# 6. 激光塔 + LED
	_fill_ellipse(c + Vector2(0.0, -ry * 0.06), radius * 0.13, ry * 0.13, accent_color)
	_fill_ellipse(c + Vector2(radius * 0.46, -ry * 0.42), radius * 0.085, radius * 0.085 * squash, accent_color)
	_fill_ellipse(c + Vector2(-radius * 0.46, -ry * 0.42), radius * 0.06, radius * 0.06 * squash, accent_color.darkened(0.25))


func _ellipse_pts(c: Vector2, rx: float, ry: float, seg: int = 48) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in seg:
		var a: float = TAU * float(i) / float(seg)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _fill_ellipse(c: Vector2, rx: float, ry: float, color: Color) -> void:
	if rx <= 0.0 or ry <= 0.0:
		return
	draw_colored_polygon(_ellipse_pts(c, rx, ry), color)


func _ring_ellipse(c: Vector2, rx: float, ry: float, color: Color, w: float) -> void:
	var pts := _ellipse_pts(c, rx, ry)
	pts.append(pts[0])
	draw_polyline(pts, color, w, true)
