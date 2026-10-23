extends Control
## 主菜单：只负责几个按钮，流程交给 GameManager。
## 调试：按数字键 1/2/3… 直接从第 N 关开始。

func _ready() -> void:
	$Center/VBox/StartButton.pressed.connect(_start)
	$Center/VBox/QuitButton.pressed.connect(_quit)
	$Center/VBox/StartButton.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key: InputEventKey = event
		var index: int = key.physical_keycode - KEY_1
		if index >= 0 and index < GameManager.LEVELS.size():
			GameManager.start_game_at(index)
			return

	if event.is_action_pressed("jump"):
		_start()


func _start() -> void:
	GameManager.start_game()


func _quit() -> void:
	get_tree().quit()
