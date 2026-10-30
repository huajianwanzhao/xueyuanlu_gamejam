@tool
class_name Furniture
extends StaticBody2D
# 伪3D 家具：一体化画「顶面 + 正面」，并按 Y 轴排序遮挡。
# 原点 = 家具正面底边（贴地那条线），所以站在它下方(y 更大)的机器人自然画在前面。
# 碰撞只占地面 footprint（顶面那块矩形），高度只影响画面。

@export_group("尺寸")
@export var width: float = 300.0 # 左右宽
@export var depth: float = 150.0 # 进深（画面上往上）
@export var height: float = 80.0 # 正面高度（画面上往下叠）

@export_group("外观")
@export var top_color: Color = Color(0.46, 0.34, 0.26)
@export var side_color: Color = Color(0.3, 0.2, 0.15)
@export var outline_color: Color = Color(0.12, 0.08, 0.06)

@export_group("遮挡")
@export var fade_when_behind: bool = true
@export var fade_alpha: float = 0.42

var _area: Area2D
var _alpha: float = 1.0


func _ready() -> void:
	queue_redraw()
	if Engine.is_editor_hint():
		return
	# 碰撞只占地面 footprint：宽度 x 进深，原点在正面底边，所以往上挪半个进深
	var body_cs := CollisionShape2D.new()
	body_cs.name = "Footprint"
	var body_rect := RectangleShape2D.new()
	body_rect.size = Vector2(width, depth)
	body_cs.shape = body_rect
	body_cs.position = Vector2(0.0, -depth * 0.5)
	add_child(body_cs)
	if not fade_when_behind:
		return
	# 遮挡探测区：盖住整个家具的可见范围
	_area = Area2D.new()
	_area.name = "Occluder"
	_area.monitoring = true
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, depth + height)
	cs.shape = rect
	cs.position = Vector2(0.0, -(depth + height) * 0.5)
	_area.add_child(cs)
	add_child(_area)


func _process(_delta: float) -> void:
	if _area == null:
		return
	var want: float = 1.0
	for body in _area.get_overlapping_bodies():
		# 机器人中心在原点上方 = 站在家具后面 = 挡视线，淡出
		if body.global_position.y < global_position.y - 1.0:
			want = fade_alpha
			break
	if not is_equal_approx(want, _alpha):
		_alpha = want
		modulate.a = _alpha
		queue_redraw()


func _draw() -> void:
	var hw: float = width * 0.5

	# 1. 地面阴影（贴地，往下方偏，暗示灯光在上方）
	var dark: Color = outline_color
	dark.a = 0.22
	draw_rect(Rect2(-hw + 8.0, -depth * 0.12, width, depth * 1.06), dark)
	dark.a = 0.3
	draw_rect(Rect2(-hw + 12.0, 0.0, width + 8.0, maxf(14.0, height * 0.16)), dark)

	# 2. 正面：下宽上窄的梯形，给一点透视
	var flare: float = height * 0.12
	var front := PackedVector2Array([
		Vector2(-hw, -height),
		Vector2(hw, -height),
		Vector2(hw + flare, 0.0),
		Vector2(-hw - flare, 0.0),
	])
	draw_colored_polygon(front, side_color)
	# 正面下沿压暗（渐变两段）
	var low := PackedVector2Array([
		Vector2(-hw - flare * 0.5, -height * 0.45),
		Vector2(hw + flare * 0.5, -height * 0.45),
		Vector2(hw + flare, 0.0),
		Vector2(-hw - flare, 0.0),
	])
	draw_colored_polygon(low, side_color.darkened(0.3))

	# 3. 顶面
	draw_rect(Rect2(-hw, -height - depth, width, depth), top_color)
	# 顶面受光渐变：越靠后（离灯越近）越亮
	var bands: int = 6
	for i in bands:
		var t: float = float(i) / float(bands)
		var c: Color = top_color.lightened(0.2 * (1.0 - t))
		draw_rect(Rect2(-hw, -height - depth + depth * t, width, depth / float(bands) + 1.0), c)
	# 左右两条暗边，暗示顶面是块厚板
	draw_rect(Rect2(-hw, -height - depth, maxf(6.0, width * 0.03), depth), top_color.darkened(0.22))
	draw_rect(Rect2(hw - maxf(6.0, width * 0.03), -height - depth, maxf(6.0, width * 0.03), depth), top_color.darkened(0.3))

	# 4. 描边 + 分界线
	draw_rect(Rect2(-hw, -height - depth, width, depth + height), outline_color, false, 3.0)
	draw_line(Vector2(-hw, -height), Vector2(hw, -height), outline_color, 2.0)
