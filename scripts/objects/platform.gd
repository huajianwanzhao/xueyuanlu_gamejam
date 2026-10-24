@tool
extends StaticBody2D
## 地板/平台：改 size，碰撞体和视觉一起变。
## 策划在编辑器里拖出来，改 Inspector 里的 size 就行，不用写代码。

@export var size: Vector2 = Vector2(96, 16):
	set(value):
		size = Vector2(maxf(value.x, 16.0), maxf(value.y, 16.0))
		_apply_size()


func _ready() -> void:
	_apply_size()


func _apply_size() -> void:
	var col: CollisionShape2D = get_node_or_null("CollisionShape2D")
	if col:
		# 每个平台都新建独立 shape：场景里的 sub_resource 是所有实例共享的，
		# 直接改它的 size 会导致所有平台变成同一个尺寸。
		var rect := RectangleShape2D.new()
		rect.size = size
		col.shape = rect
	var vis: ColorRect = get_node_or_null("Visual")
	if vis:
		vis.offset_left = -size.x * 0.5
		vis.offset_top = -size.y * 0.5
		vis.offset_right = size.x * 0.5
		vis.offset_bottom = size.y * 0.5
