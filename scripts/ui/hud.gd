extends CanvasLayer
## HUD：订阅 GameManager 的分数信号，不用每帧查询。

@onready var score_label: Label = $Root/Bar/ScoreLabel
@onready var level_label: Label = $Root/Bar/LevelLabel


func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	_on_score_changed(GameManager.score)


func _on_score_changed(value: int) -> void:
	score_label.text = "分数 %d" % value


func set_level(current: int, total: int) -> void:
	level_label.text = "%d / %d" % [current, total]
