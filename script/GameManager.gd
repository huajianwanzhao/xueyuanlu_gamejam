extends Node


#1  信号
signal game_state_changed(new_state: GameState)
signal score_changed(new_score: int)
signal request_screen_shake(intensity : float, duration : float)

#2. 游戏状态机
enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER
}

var current_state : GameState = GameState.MENU
var current_score : int = 0


#    3.场景切换
var current_level_index : int = 1
var level_screens: Array[String] = [
	"res://scenes/levels/level_01.tscn"
]



func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func change_state(new_state : GameState)-> void:
	current_state = new_state
	game_state_changed.emit(current_state)
	
	match current_state:
		GameState.PLAYING:
			get_tree().paused = false
			Engine.time_scale = 1.0
		GameState.PAUSED:
			get_tree().paused = true
			Engine.time_scale = 1.0
		GameState.GAME_OVER:
			get_tree().paused = true
			
func add_score(amount : int )->void:
	current_score+=amount
	score_changed.emit(current_score)

func _load_scene(scene_path : String) -> void:
	change_state(GameState.PLAYING)
	get_tree().change_scene_to_file(scene_path)

func load_next_level() ->void:
	if current_level_index < level_screens.size() - 1:
		current_level_index += 1
		_load_scene(level_screens[current_level_index])
		
func restart_current_level() -> void:
	_load_scene(level_screens[current_level_index])
	

	
#  4.顿帧和慢动作
func hit_stop(duration : float, time_scale: float = 0.05)->void:
	if Engine.time_scale<1.0:
		return
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration,true,false,true).timeout
	Engine.time_scale = 1.0
	
func slow_motion(duration : float,time_scale: float = 0.3)->void:
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration,true,false,true).timeout
	Engine.time_scale = 1.0
