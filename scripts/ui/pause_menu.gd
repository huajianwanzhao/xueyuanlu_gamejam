extends CanvasLayer
## 暂停菜单：只管发信号，具体做什么由 game.gd 决定。

signal resume_pressed
signal restart_pressed
signal menu_pressed


func _ready() -> void:
	visible = false
	$Root/Center/VBox/ResumeButton.pressed.connect(func() -> void: resume_pressed.emit())
	$Root/Center/VBox/RestartButton.pressed.connect(func() -> void: restart_pressed.emit())
	$Root/Center/VBox/MenuButton.pressed.connect(func() -> void: menu_pressed.emit())


func open() -> void:
	visible = true
	$Root/Center/VBox/ResumeButton.grab_focus()


func close() -> void:
	visible = false
