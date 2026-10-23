extends Control
## 通关界面：显示分数，提供重玩/回菜单。


func _ready() -> void:
	$Center/VBox/ScoreLabel.text = "得分 %d" % GameManager.score
	$Center/VBox/RetryButton.pressed.connect(func() -> void: GameManager.start_game())
	$Center/VBox/MenuButton.pressed.connect(func() -> void: GameManager.go_to_menu())
	$Center/VBox/RetryButton.grab_focus()
