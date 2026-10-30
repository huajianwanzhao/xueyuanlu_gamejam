extends Camera2D

# ================= 震动参数 =================
@export_group("运动偏移设置")
@export var target := CharacterBody2D
@export var look_ahead_scale : float = 0.1
@export var follow_speed :float = 5.0
@export_group("震动设置")
@export var max_offset: Vector2 = Vector2(15.0, 15.0) # 最大水平/垂直偏移
@export var max_roll: float = 0.05 # 最大旋转角度（弧度）
@export var decay_speed: float = 2.0 # 创伤值衰减速度（越大恢复越快）

var trauma: float = 0.0 # 当前创伤值（0.0 到 1.0）
var trauma_power: float = 2.0 # 创伤指数（2.0 意味着衰减非常顺滑）
var noise = FastNoiseLite.new() # 使用噪声让震动更自然

func _ready() -> void:
	# 连接 GameManager 的震动信号
	GameManager.request_screen_shake.connect(_on_shake_requested)
	
	# 初始化噪声，用来生成平滑的随机震动
	noise.frequency = 0.1
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

func _process(delta: float) -> void:
	if target :
		var look_ahead_offset = -target.velocity*look_ahead_scale
		var desire_position = target.global_position+look_ahead_offset
		global_position = global_position.lerp(desire_position,exp(-follow_speed))
		
	if trauma > 0.0:
		# 创伤值随时间衰减
		trauma = max(trauma - decay_speed * delta, 0.0)
		
		# 核心公式：trauma的平方，让震动在快结束时迅速衰减，非常自然
		var shake_amount = pow(trauma, trauma_power)
		
		# 用时间作为噪声输入，生成连续的随机数
		var time = Time.get_ticks_msec() * 0.05
		
		# 应用水平、垂直偏移
		offset.x = max_offset.x * shake_amount * noise.get_noise_2d(time, 0)
		offset.y = max_offset.y * shake_amount * noise.get_noise_2d(0, time)
		
		# 应用旋转
		rotation = max_roll * shake_amount * noise.get_noise_2d(time, time)
	else:
		# 恢复平静
		offset = Vector2.ZERO
		rotation = 0.0

# 接收到 GameManager 的信号
func _on_shake_requested(intensity: float, duration: float) -> void:
	# 将传入的强度转化为 0~1 的创伤值
	# 比如传进来 15.0，我们将其转换为高创伤值
	var new_trauma = clampf(intensity / 20.0, 0.0, 1.0)
	
	# 如果新的震动比当前强，就覆盖，否则叠加一点
	trauma = min(trauma + new_trauma, 1.0)
