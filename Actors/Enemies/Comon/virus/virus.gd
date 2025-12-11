extends BaseEnemy

#region 설정 변수
@export var move_speed: float = 50.0
@export var attack_range: float = 100.0 # 사거리
@export var attack_cooldown: float = 3.0

# 상태 변수
var is_attacking: bool = false
var on_cooldown: bool = false
var patrol_direction: int = 1
var patrol_timer: float = 0.0
#endregion

#region 노드 참조 (스크린샷 경로 기준)
@onready var main_sprite = $Visuals/AnimatedSprite2D
@onready var wave_effect = $ShockwaveHolder/AttakVisual
@onready var attack_area = $ShockwaveHolder/AttakArea
#endregion

func _ready():
	super._ready()
	
	# 1. 시작 시 파동 숨기기 및 판정 끄기
	wave_effect.visible = false
	attack_area.monitoring = false
	
	# 2. 시그널 연결 
	
	# 파동 애니메이션이 끝났을 때
	if not wave_effect.animation_finished.is_connected(_on_wave_finished):
		wave_effect.animation_finished.connect(_on_wave_finished)
	
	# 플레이어가 파동에 닿았을 때
	if not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
		attack_area.body_entered.connect(_on_attack_area_body_entered)
		
	# 본체 애니메이션 프레임이 바뀔 때 
	if not main_sprite.frame_changed.is_connected(_on_main_sprite_frame_changed):
		main_sprite.frame_changed.connect(_on_main_sprite_frame_changed)

func _process_movement(delta):
	# 공격 중이거나 죽었으면 제자리에 멈춤
	if is_attacking or current_health <= 0:
		velocity.x = move_toward(velocity.x, 0, 200 * delta)
		return

	# 쿨타임 중일 때는 멈춤 또는 회
	if on_cooldown:
		velocity.x = move_toward(velocity.x, 0, 100 * delta)
		main_sprite.play("idle")
		return

	# 플레이어 찾기
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		var dist = global_position.distance_to(player.global_position)
		
		# [상황 1] 공격 사거리 안 -> 공격 시작
		if dist <= attack_range:
			start_attack_sequence()
			
		# [상황 2] 추격 (사거리의 2배 안)
		elif dist <= (attack_range * 2.0):
			chase_player(player)
			
		# [상황 3] 멀면 배회
		else:
			patrol_behavior(delta)
	else:
		patrol_behavior(delta)

	# 방향 전환 (스프라이트 좌우 반전)
	if velocity.x != 0:
		main_sprite.flip_h = (velocity.x < 0)

# --- 행동 패턴 함수들 ---

func chase_player(player):
	var direction = (player.global_position - global_position).normalized()
	velocity.x = direction.x * move_speed
	main_sprite.play("walk")

func patrol_behavior(delta):
	patrol_timer -= delta
	
	# 0.5 ~ 1.0초마다 행동을 바꿈 뽈뽈거리기
	if patrol_timer <= 0:
		patrol_timer = randf_range(0.5, 1.0)
		var random_choice = randi() % 5
		
		# 0, 1 나오면 멈춤 (40% 확률)
		if random_choice <= 1:
			patrol_direction = 0
		# 2: 오른쪽, 3: 왼쪽
		elif random_choice == 2:
			patrol_direction = 1
		elif random_choice == 3:
			patrol_direction = -1
		# 4: 반대 방향으로 턴
		else:
			patrol_direction = - patrol_direction
			
	velocity.x = patrol_direction * (move_speed * 0.5)
	
	if velocity.x == 0:
		main_sprite.play("idle")
	else:
		main_sprite.play("walk")

# --- 공격 시퀀스  ---

func start_attack_sequence():
	is_attacking = true
	on_cooldown = true
	velocity = Vector2.ZERO # 이동 정지
	
	main_sprite.play("shockwave")

# 프레임 감지 함수
func _on_main_sprite_frame_changed():
	# 현재 'shockwave' 동작 중이고 + 프레임이 4번(빨간색)이라면?
	if main_sprite.animation == "shockwave" and main_sprite.frame == 4:
		fire_wave_effect()

# 파동 발사
func fire_wave_effect():
	# 파동 보이기 & 재생
	wave_effect.visible = true
	wave_effect.frame = 0
	wave_effect.play("wave")
	
	# 공격 판정 켜기 (플레이어 데미지용)
	attack_area.monitoring = true

# 파동 애니메이션(wave)이 끝나면 호출됨
func _on_wave_finished():
	wave_effect.visible = false
	wave_effect.stop()
	attack_area.monitoring = false
	
	is_attacking = false
	
	# 본체 다시 idle 상태
	main_sprite.play("idle")
	
	# 쿨타임 대기 (3초)
	print("virus coolimte...")
	await get_tree().create_timer(attack_cooldown).timeout
	
	on_cooldown = false
	print("virus coolimte end")

# --- 충돌 처리 ---

func _on_attack_area_body_entered(body):
	if body.is_in_group("player"):
		print(">> 플레이어 파동 적중")
		if body.has_method("lose_life"):
			body.lose_life()

func apply_slow(slow_ratio: float, duration: float):
	print("으악! 이동 속도가 느려졌다!")
	move_speed *= slow_ratio # 0.5가 들어오면 속도 반토막
	
	# 일정 시간 뒤 원상복구 (타이머 사용)
	await get_tree().create_timer(duration).timeout
	move_speed /= slow_ratio # 다시 원래대로
