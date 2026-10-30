@tool
class_name FloorGrid
extends Node2D
# 地板：纯代码画一块带网格的底，z_index 拉到最后面。

@export var rect_size: Vector2 = Vector2(2400.0, 1600.0)
@export var base_color: Color = Color(0.16, 0.17, 0.2)
@export var line_color: Color = Color(0.24, 0.26, 0.31)
@export var tile: float = 120.0


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var r := Rect2(-rect_size * 0.5, rect_size)
	draw_rect(r, base_color)
	var x: float = -rect_size.x * 0.5
	while x <= rect_size.x * 0.5:
		draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), line_color, 2.0)
		x += tile
	var y: float = -rect_size.y * 0.5
	while y <= rect_size.y * 0.5:
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), line_color, 2.0)
		y += tile
	draw_rect(r, line_color, false, 4.0)
