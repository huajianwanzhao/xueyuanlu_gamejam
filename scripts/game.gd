extends Node2D
## 关卡容器：加载当前关卡、接住关卡事件、处理暂停。
## 关卡本身（levels/*.tscn）是纯内容，策划可以随便改，不会影响这里。

@onready var level_holder: Node2D = $LevelHolder
@onready var hud: CanvasLayer = $HUD
@onready var pause_menu: CanvasLayer = $PauseMenu

var _level: Node = null
var _player: Node = null
var _level_done: bool = false
var _paused: bool = false


func _ready() -> void:
	pause_menu.resume_pressed.connect(func() -> void: set_paused(false))
	pause_menu.restart_pressed.connect(func() -> void: GameManager.restart_level())
	pause_menu.menu_pressed.connect(func() -> void: GameManager.go_to_menu())
	_load_level()


func _load_level() -> void:
	var path: String = GameManager.LEVELS[GameManager.current_level]
	_level = load(path).instantiate()
	level_holder.add_child(_level)

	hud.set_level(GameManager.current_level + 1, GameManager.LEVELS.size())

	_player = get_tree().get_first_node_in_group("player")
	if _player:
		_player.died.connect(_on_player_died)

	for goal in get_tree().get_nodes_in_group("goal"):
		goal.reached.connect(_on_goal_reached)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		set_paused(not _paused)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("restart") and not _paused and not _level_done:
		GameManager.restart_level()


func set_paused(value: bool) -> void:
	_paused = value
	get_tree().paused = value
	if value:
		pause_menu.open()
	else:
		pause_menu.close()


func _on_player_died() -> void:
	if _level_done:
		return
	_level_done = true
	AudioManager.play_sfx("die")
	await get_tree().create_timer(0.45).timeout
	GameManager.restart_level()


func _on_goal_reached() -> void:
	if _level_done:
		return
	_level_done = true
	await get_tree().create_timer(0.25).timeout
	GameManager.level_complete()
