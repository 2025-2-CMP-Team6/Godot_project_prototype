class_name FlyingEnemy extends BaseEnemy

#region 상태
enum State {
	WANDER,
	CHASE,
	AIMING,
	LOCK,
	DASH,
	COOLDOWN
}
var current_state: State = State.WANDER
#endregion

#region 설정값 (Inspector)
@export_group("Movement")
@export var fly_speed: float = 600.0
@export var wander_radius: float = 300.0
@export var surround_radius: float = 80.0

@export_group("Detection")
@export var detect_range: float = 400.0 # 플레이어 감지 거리
@export var lose_interest_range: float = 600.0 # CHASE -> WANDER 복귀 거리
@export var attack_trigger_range: float = 200.0 # CHASE -> AIMING 전환 거리

@export_group("Attack")
@export var dash_speed: float = 1800.0
@export var aim_duration: float = 1.0 # 조준 시간
@export var lock_duration: float = 0.5 # 발사 직전 대기
@export var dash_duration: float = 0.5 # 돌진 지속 시간
@export var attack_cooldown: float = 0.25 # 실패 시 대기 시간
@export var attack_width: float = 20.0 # 공격 예고 범위 폭
#endregion

#region 내부 변수
var player: Node2D = null
var initial_pos: Vector2
var target_velocity: Vector2 = Vector2.ZERO
var move_change_timer: float = 0.0

# 공격용 타이머 및 벡터
var state_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var locked_target_pos: Vector2 = Vector2.ZERO

@onready var animation: AnimatedSprite2D = $Visuals/AnimatedSprite2D
#endregion

func _ready():
	super._ready()
	gravity = 0.0 # 중력 제거
	initial_pos = global_position
	
	if animation:
		animation.play("idle")
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	
	# 시작 상태
	_change_state(State.WANDER)

func _physics_process(delta: float):
	match current_state:
		State.WANDER:
			_process_wander(delta)
		State.CHASE:
			_process_chase(delta)
		State.AIMING:
			_process_aiming(delta)
		State.LOCK:
			_process_lock(delta)
		State.DASH:
			_process_dash(delta)
		State.COOLDOWN:
			_process_cooldown(delta)

	move_and_slide()
	queue_redraw() # 공격 범위 그리기 업데이트

#region 상태별 로직 (1~4)

# WANDER
func _process_wander(delta: float):
	# 이동 
	_apply_erratic_movement(delta)
	
	# 플레이어 감지
	if player:
		var dist = global_position.distance_to(player.global_position)
		if dist < detect_range:
			_change_state(State.CHASE)

# CHASE
func _process_chase(delta: float):
	# 이동
	_apply_erratic_movement(delta)
	
	if player == null:
		_change_state(State.WANDER)
		return

	var dist = global_position.distance_to(player.global_position)
	
	if dist < 50.0:
		var dir_away = (global_position - player.global_position).normalized()
		target_velocity = dir_away * fly_speed
		velocity = velocity.lerp(target_velocity, 5.0 * delta)
		return

	_apply_erratic_movement(delta)
	
	if dist < attack_trigger_range:
		_change_state(State.AIMING)
	elif dist > lose_interest_range:
		_change_state(State.WANDER)

# AIMING
func _process_aiming(delta: float):
	# 멈춰서 플레이어 바라보기
	velocity = velocity.lerp(Vector2.ZERO, 10.0 * delta)
	if player:
		_update_sprite_facing(player.global_position.x - global_position.x)
	
	state_timer -= delta
	if state_timer <= 0:
		_change_state(State.LOCK)

# LOCK
func _process_lock(delta: float):
	velocity = Vector2.ZERO
	state_timer -= delta
	if state_timer <= 0:
		_change_state(State.DASH)

# DASH
func _process_dash(delta: float):
	velocity = dash_direction * dash_speed
	
	# 충돌 체크
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider.is_in_group("player"):
			_explode(collider) # 성공 시 자폭
			return
		else:
			# 실패 쿨타임
			print("벽 충돌! 추적 복귀 준비")
			_change_state(State.COOLDOWN)
			return
	
	# 실패 쿨타임
	state_timer -= delta
	if state_timer <= 0:
		print("돌진 빗나감! 추적 복귀 준비")
		_change_state(State.COOLDOWN)

# COOLDOWN
func _process_cooldown(delta: float):
	velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
	
	state_timer -= delta
	if state_timer <= 0:
		# 쿨타임 끝나면 추적 모드
		_change_state(State.CHASE)

#endregion

#region 이동 및 헬퍼 함수


func _apply_erratic_movement(delta: float):
	move_change_timer -= delta
	if move_change_timer <= 0:
		_pick_new_direction()
	
	velocity = velocity.lerp(target_velocity, 4.0 * delta)
	_update_sprite_facing(velocity.x)

func _pick_new_direction():
	move_change_timer = randf_range(0.05, 1.5)
	
	if current_state == State.CHASE and player:
		var random_angle = randf() * TAU
		var min_surround = 40.0
		var random_dist = randf_range(min_surround, surround_radius)
		
		var offset = Vector2(cos(random_angle), sin(random_angle)) * random_dist
		var target_pos = player.global_position + offset
		target_velocity = (target_pos - global_position).normalized() * fly_speed
		
	elif current_state == State.WANDER:
		move_change_timer = randf_range(0.2, 0.5)
		
		var dist_from_home = global_position.distance_to(initial_pos)
		if dist_from_home > wander_radius:
			var dir_home = (initial_pos - global_position).normalized()
			var jitter = Vector2(randf() - 0.5, randf() - 0.5) * 0.8
			target_velocity = (dir_home + jitter).normalized() * fly_speed
		else:
			var random_dir = Vector2(randf() - 0.5, randf() - 0.5).normalized()
			target_velocity = random_dir * fly_speed

func _change_state(new_state: State):
	current_state = new_state
	
	match new_state:
		State.WANDER:
			_pick_new_direction()
		State.CHASE:
			_pick_new_direction()
		State.AIMING:
			state_timer = aim_duration
			velocity = Vector2.ZERO
		State.LOCK:
			state_timer = lock_duration
			if player:
				locked_target_pos = player.global_position
				dash_direction = (locked_target_pos - global_position).normalized()
			else:
				dash_direction = Vector2.RIGHT
		State.DASH:
			state_timer = dash_duration
		State.COOLDOWN:
			state_timer = attack_cooldown

func _update_sprite_facing(dir_x: float):
	if animation:
		if dir_x > 0: animation.flip_h = true
		elif dir_x < 0: animation.flip_h = false

func _explode(target):
	if target.has_method("lose_life"):
		target.lose_life()
	EffectManager.play_hit_effect(global_position, 2.0)
	die()

func _draw():
	if current_state == State.AIMING and player:
		draw_line(Vector2.ZERO, (player.global_position - global_position).normalized() * attack_trigger_range, Color(1, 0, 0, 0.4), attack_width)
	elif current_state == State.LOCK:
		draw_line(Vector2.ZERO, (locked_target_pos - global_position).normalized() * attack_trigger_range, Color(1, 0, 0, 0.8), attack_width)
#endregion
