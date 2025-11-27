# Boss.gd
extends BaseEnemy

#region 보스 전용 설정
@export var attack_interval_min: float = 2.0
@export var attack_interval_max: float = 4.0
#endregion

#region 노드 참조
@export var pattern_timer: Timer
#endregion

func _ready():
	super._ready()
	# 보스 패턴 시작
	start_attack_pattern()

# 물리 로직 오버라이드
func _physics_process(delta: float):
	pass

# 보스 패턴
func start_attack_pattern():
	if pattern_timer:
		pattern_timer.wait_time = randf_range(attack_interval_min, attack_interval_max)
		pattern_timer.start()

func _on_fire_timer_timeout():
	spawn_random_pattern()
	pattern_timer.wait_time = randf_range(attack_interval_min, attack_interval_max)
	pattern_timer.start()

func spawn_random_pattern():
	print("Boss Pattern")
