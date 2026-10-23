extends Area2D
## 终点：玩家碰到就通知 game.gd 过关。

signal reached


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		AudioManager.play_sfx("win")
		reached.emit()
