extends Area2D
## 金币：玩家碰到就加分、播声音、消失。

@export var value: int = 1
@export var bob_height: float = 4.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_start_bob()


func _start_bob() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(self, "position:y", position.y - bob_height, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y", position.y + bob_height, 0.6).set_trans(Tween.TRANS_SINE)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	GameManager.add_score(value)
	AudioManager.play_sfx("coin")
	queue_free()
