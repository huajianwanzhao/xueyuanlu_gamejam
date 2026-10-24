extends Node2D
## 美术比例检查场景（F6 运行）。
## 用法：把一张候选 PNG 拖到下面 Real / Zoom 两个节点的 texture 上。
##   Real = 1:1 真实大小，看它在这个 640x360 的框里是否清楚
##   Zoom = 同一张图放大 4 倍，看像素细节

const VIEW: Vector2 = Vector2(640, 360)
const GROUND_Y: float = 320.0

const COL_BG: Color = Color(0.14, 0.16, 0.22)
const COL_GRID_MINOR: Color = Color(0.22, 0.24, 0.32)
const COL_GRID_MAJOR: Color = Color(0.32, 0.36, 0.48)
const COL_GROUND: Color = Color(0.29, 0.32, 0.42)
const COL_GHOST: Color = Color(0.95, 0.66, 0.32, 0.55)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), COL_BG)

	var x: float = 0.0
	while x <= VIEW.x:
		draw_line(Vector2(x, 0), Vector2(x, VIEW.y), COL_GRID_MAJOR if int(x) % 64 == 0 else COL_GRID_MINOR)
		x += 16.0
	var y: float = 0.0
	while y <= VIEW.y:
		draw_line(Vector2(0, y), Vector2(VIEW.x, y), COL_GRID_MAJOR if int(y) % 64 == 0 else COL_GRID_MINOR)
		y += 16.0

	draw_rect(Rect2(Vector2(0, GROUND_Y), Vector2(VIEW.x, VIEW.y - GROUND_Y)), COL_GROUND)

	# 角色标准尺寸的参考框：脚底贴地，16x28
	var ghost: Rect2 = Rect2(Vector2(56, GROUND_Y - 28.0), Vector2(16, 28))
	draw_rect(ghost, COL_GHOST, false, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(56, GROUND_Y - 34), "标准角色 16x28", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COL_GHOST)
