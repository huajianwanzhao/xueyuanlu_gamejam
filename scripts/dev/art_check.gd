extends Node2D
## 手绘风素材检查场景（F6 运行）。
##
## 用法：把候选 PNG 拖到 Real / Edge 两个节点的 Texture 上。
##   Real = 按 2 倍画的图缩回 1:1，看它在真实画面里够不够清楚
##   Edge = 放大 2 倍，看边缘有没有暗边/黑边、有没有被拉糊
##
## 判定只有一句：Real 里看得清、Edge 里没有黑边，就过。

const VIEW: Vector2 = Vector2(1280, 720)
## 和 levels/level_01.tscn 的地面顶部完全对齐，方便和真实关卡对比
const GROUND_Y: float = 656.0
## 角色碰撞盒 32x56；素材建议按 2 倍画，即 64x112
const BODY: Vector2 = Vector2(32, 56)
const ART_SCALE: float = 2.0
const SAFE_MARGIN: float = 64.0

const COL_BG: Color = Color(0.10, 0.11, 0.14)
const COL_GROUND: Color = Color(0.29, 0.32, 0.42)
const COL_SAFE: Color = Color(0.75, 0.30, 0.32)
const COL_ART: Color = Color(0.95, 0.72, 0.32, 0.9)
const COL_BODY: Color = Color(0.62, 0.66, 0.78, 0.8)
const COL_LIGHT: Color = Color(0.86, 0.87, 0.90)


func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, VIEW), COL_BG)

	# 亮色块：把图放在亮背景上，暗边/黑边最容易被看出来
	draw_rect(Rect2(Vector2(300, 340), Vector2(380, 320)), COL_LIGHT)

	# 地面
	draw_rect(Rect2(Vector2(0, GROUND_Y), Vector2(VIEW.x, VIEW.y - GROUND_Y)), COL_GROUND)

	# 安全边距：重要内容别越过这两条线（不同宽高比的屏幕会裁掉）
	draw_line(Vector2(SAFE_MARGIN, 0), Vector2(SAFE_MARGIN, VIEW.y), COL_SAFE, 2.0)
	draw_line(Vector2(VIEW.x - SAFE_MARGIN, 0), Vector2(VIEW.x - SAFE_MARGIN, VIEW.y), COL_SAFE, 2.0)
	draw_string(font, Vector2(SAFE_MARGIN + 10, 140), "红线内 = 安全区", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, COL_SAFE)

	# 参考框：外框 = 素材画布（64x112），内框 = 碰撞盒（32x56），脚底对齐地面
	var art: Vector2 = BODY * ART_SCALE
	var foot_x: float = 120.0
	draw_rect(Rect2(Vector2(foot_x - art.x * 0.5, GROUND_Y - art.y), art), COL_ART, false, 2.0)
	draw_rect(Rect2(Vector2(foot_x - BODY.x * 0.5, GROUND_Y - BODY.y), BODY), COL_BODY, false, 2.0)

	# 锚点十字：图片的脚底中心要落在这里
	draw_line(Vector2(foot_x - 14, GROUND_Y), Vector2(foot_x + 14, GROUND_Y), COL_ART, 2.0)
	draw_line(Vector2(foot_x, GROUND_Y - 14), Vector2(foot_x, GROUND_Y + 14), COL_ART, 2.0)

	draw_string(font, Vector2(foot_x - 96, GROUND_Y - art.y - 14), "素材画布 64 x 112（按 2 倍画）", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, COL_ART)
	draw_string(font, Vector2(foot_x - 66, GROUND_Y - BODY.y - 10), "碰撞盒 32 x 56", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, COL_BODY)
	draw_string(font, Vector2(foot_x + 18, GROUND_Y + 6), "脚底锚点", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, COL_ART)

	draw_string(font, Vector2(316, 372), "亮背景：暗边/黑边在这里最明显", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.18, 0.19, 0.23))
