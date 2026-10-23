extends Node
## 全局状态机：关卡、分数、暂停、场景切换。
## 用法：任何脚本里直接写 GameManager.add_score() / GameManager.start_game()

signal score_changed(value: int)
signal game_finished(final_score: int)

## 关卡顺序表：加一关就往这里加一行
const LEVELS: Array[String] = [
	"res://levels/level_01.tscn",
	"res://levels/level_02.tscn",
]

var current_level: int = 0
var score: int = 0


func start_game() -> void:
	start_game_at(0)


## 从指定关卡开始（调试用：主菜单按数字键 1/2/3…）
func start_game_at(level_index: int) -> void:
	current_level = clampi(level_index, 0, LEVELS.size() - 1)
	score = 0
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func go_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func add_score(amount: int = 1) -> void:
	score += amount
	score_changed.emit(score)


func level_complete() -> void:
	current_level += 1
	if current_level >= LEVELS.size():
		game_finished.emit(score)
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/win_screen.tscn")
		return
	get_tree().paused = false
	get_tree().reload_current_scene()


func restart_level() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
