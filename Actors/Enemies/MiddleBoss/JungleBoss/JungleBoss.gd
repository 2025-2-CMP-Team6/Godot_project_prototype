# JungleBoss.gd
extends BaseEnemy

#region 설정 변수
@export var move_speed: float = 80.0
@export var patrol_radius: float = 150.0 # 배회 반경
@export var chase_range: float = 400.0 # 플레이어 감지 범위
@export var attack_range: float = 150.0 # 공격 범위
@export var attack_cooldown: float = 2.5
@export var attack_duration: float = 1.2 # 공격 애니메이션 길이
@export var blue_hit_frame: int = 2 # Blue가 데미지를 주는 프레임
@export var purple_hit_frame: int = 2 # Purple이 데미지를 주는 프레임

# 광폭화 관련 설정
@export var enrage_health_threshold: float = 70.0 # 광폭화 발동 체력 (절반)
@export var enraged_move_speed_multiplier: float = 1.75 # 광폭화시 이동속도 배율
@export var enraged_attack_cooldown_multiplier: float = 0.5 # 광폭화시 공격쿨타임 배율
#endregion

#region 보스 상태 enum
enum State {
	IDLE, # 대기
	WALK, # 배회/추격
	ATTACK_BLUE, # Blue 공격
	ATTACK_PURPLE, # Purple 공격
	COOLDOWN # 공격 후 쿨타임
}
#endregion

#region 상태 변수
var current_state: State = State.IDLE
var state_timer: float = 0.0
var patrol_direction: int = 1
var patrol_timer: float = 0.0
var spawn_position: Vector2 # 스폰 위치 (배회 중심점)
var attack_phase: int = 0 # 0 = Blue, 1 = Purple

# 데미지 플래그 (각 머리별로 한 번씩만 데미지)
var blue_dealt_damage: bool = false
var purple_dealt_damage: bool = false

# 광폭화 관련 변수
var is_enraged: bool = false # 광폭화 상태 여부
var base_move_speed: float # 기본 이동 속도
var base_attack_cooldown: float # 기본 공격 쿨타임

var floor_checker: RayCast2D
#endregion

#region 노드 참조
@onready var main_sprite = $AnimatedSprite2D
@onready var sprite_ = $AnimatedSprite2D # BaseEnemy에서 참조하는 sprite 오버라이드
@onready var attack_area = get_node_or_null("AttackArea")
#endregion

func _ready():
	super._ready()

	add_to_group("enemies")

	# 스폰 위치 저장
	spawn_position = global_position

	# 기본 속도값 저장 (광폭화 이전 값)
	base_move_speed = move_speed
	base_attack_cooldown = attack_cooldown

	if attack_area:
		attack_area.monitoring = true

		# CollisionShape2D 확인
		var shape_count = 0
		for child in attack_area.get_children():
			if child is CollisionShape2D:
				shape_count += 1
		if shape_count == 0:
			print("경고: AttackArea에 CollisionShape2D가 없습니다!")

	# 시그널 연결
	if main_sprite and not main_sprite.frame_changed.is_connected(_on_sprite_frame_changed):
		main_sprite.frame_changed.connect(_on_sprite_frame_changed)

	if main_sprite and not main_sprite.animation_finished.is_connected(_on_animation_finished):
		main_sprite.animation_finished.connect(_on_animation_finished)

	# 바닥 감지용 RayCast 생성
	floor_checker = RayCast2D.new()
	floor_checker.target_position = Vector2(0, 50)
	floor_checker.collision_mask = collision_mask
	floor_checker.enabled = true
	add_child(floor_checker)

	# 초기 상태 설정 (change_state를 통해 타이머도 함께 초기화)
	change_state(State.IDLE)

	print("JungleBoss 초기화 완료 - 위치: ", global_position)

func _process_movement(delta):
	# 죽었으면 멈춤
	if current_health <= 0:
		velocity.x = move_toward(velocity.x, 0, 200 * delta)
		return

	# 광폭화 체크 (체력이 절반 이하가 되면 발동)
	check_enrage()

	# 상태 타이머 감소
	if state_timer > 0:
		state_timer -= delta

	# 플레이어 찾기
	var player = get_tree().get_first_node_in_group("player")

	# 상태별 행동
	match current_state:
		State.IDLE:
			handle_idle_state(delta, player)

		State.WALK:
			handle_walk_state(delta, player)

		State.ATTACK_BLUE:
			handle_attack_blue_state(delta)

		State.ATTACK_PURPLE:
			handle_attack_purple_state(delta)

		State.COOLDOWN:
			handle_cooldown_state(delta, player)

	# 스프라이트 방향 전환 (기본 스프라이트가 왼쪽을 보고 있어서 반대로)
	if main_sprite and velocity.x != 0:
		main_sprite.flip_h = (velocity.x > 0)

		# AttackArea 위치도 스프라이트 방향에 맞춰 조정 (scale 2 고려)
		if attack_area:
			if main_sprite.flip_h: # 오른쪽을 보고 있으면 (flip된 상태)
				attack_area.position.x = -12
			else: # 왼쪽을 보고 있으면 (기본 상태)
				attack_area.position.x = 12

#region 상태별 처리 함수들

func handle_idle_state(delta, player):
	velocity.x = move_toward(velocity.x, 0, 200 * delta)

	if player:
		var distance = global_position.distance_to(player.global_position)

		# 플레이어가 감지 범위 안에 들어오면 추적 시작
		if distance <= chase_range:
			change_state(State.WALK, player)
			return

	# idle 타이머가 끝나면 배회 시작
	if state_timer <= 0:
		change_state(State.WALK)

func handle_walk_state(delta, player):
	var is_chasing = false

	if player:
		var distance = global_position.distance_to(player.global_position)
		# print("WALK 상태 - 플레이어 거리: ", distance)

		# 플레이어가 공격 범위 안에 들어오면 공격
		if distance <= attack_range:
			print("공격 범위 진입! 공격 시작")
			start_attack_sequence()
			return

		# 플레이어가 추격 범위 안에 있으면 추적
		if distance <= chase_range:
			print("추격 중 - velocity.x: ", velocity.x)
			chase_player(player)
			is_chasing = true

	# 플레이어를 추적하지 않으면 배회
	if not is_chasing:
		patrol_behavior(delta)

		# 스폰 위치에서 너무 멀어지면 idle로 복귀
		var distance_from_spawn = global_position.distance_to(spawn_position)
		if distance_from_spawn > patrol_radius:
			change_state(State.IDLE)

func handle_attack_blue_state(delta):
	# 공격 중에는 멈춤
	velocity.x = move_toward(velocity.x, 0, 200 * delta)

	# 공격 애니메이션이 끝나면 다음 공격으로
	if state_timer <= 0:
		change_state(State.ATTACK_PURPLE)

func handle_attack_purple_state(delta):
	# 공격 중에는 멈춤
	velocity.x = move_toward(velocity.x, 0, 200 * delta)

	# 공격 애니메이션이 끝나면 쿨타임으로
	if state_timer <= 0:
		change_state(State.COOLDOWN)

func handle_cooldown_state(delta, player):
	velocity.x = move_toward(velocity.x, 0, 200 * delta)

	# 쿨타임이 끝나면 walk 상태로
	if state_timer <= 0:
		if player and global_position.distance_to(player.global_position) <= chase_range:
			change_state(State.WALK, player)
		else:
			change_state(State.IDLE)

#endregion

#region 행동 패턴 함수들

func chase_player(player):
	var direction = (player.global_position - global_position).normalized()
	print("chase_player 호출 - direction: ", direction, ", move_speed: ", move_speed)

	# 추격 중 바닥 체크 (일시적으로 비활성화 - 디버깅용)
	# if direction.x != 0 and floor_checker:
	# 	var check_dir = 1 if direction.x > 0 else -1
	# 	floor_checker.position.x = check_dir * 30
	# 	floor_checker.force_raycast_update()
	# 	if not floor_checker.is_colliding():
	# 		print("바닥 없음! 정지")
	# 		velocity.x = 0
	# 		if main_sprite: main_sprite.play("idle")
	# 		return

	velocity.x = direction.x * move_speed
	print("velocity 설정됨: ", velocity.x)
	if main_sprite:
		main_sprite.play("walk")

func patrol_behavior(delta):
	patrol_timer -= delta

	# 1~2초마다 방향 변경
	if patrol_timer <= 0:
		patrol_timer = randf_range(1.0, 2.5)
		var random_choice = randi() % 3

		if random_choice == 0:
			patrol_direction = 0 # 멈춤
		elif random_choice == 1:
			patrol_direction = 1
		else:
			patrol_direction = -1

	# 이동 중 바닥이 없으면 방향 전환 (일시적으로 비활성화 - 디버깅용)
	# if patrol_direction != 0 and floor_checker:
	# 	floor_checker.position.x = patrol_direction * 30
	# 	floor_checker.force_raycast_update()
	# 	if not floor_checker.is_colliding():
	# 		patrol_direction *= -1

	# 배회 반경을 벗어나면 스폰 위치 방향으로
	var to_spawn = spawn_position - global_position
	if to_spawn.length() > patrol_radius:
		patrol_direction = 1 if to_spawn.x > 0 else -1

	velocity.x = patrol_direction * (move_speed * 0.4)

	if main_sprite:
		if velocity.x == 0:
			main_sprite.play("idle")
		else:
			main_sprite.play("walk")

#endregion

#region 공격 관련

func start_attack_sequence():
	# 공격 시퀀스 시작 (항상 Blue부터)
	attack_phase = 0
	change_state(State.ATTACK_BLUE)

func change_state(new_state: State, player = null):
	if current_state == new_state:
		return

	print("JungleBoss: 상태 변경 ", State.keys()[current_state], " -> ", State.keys()[new_state])

	# 새 상태 시작 처리
	current_state = new_state
	match new_state:
		State.IDLE:
			state_timer = randf_range(1.0, 2.0)
			if main_sprite:
				main_sprite.play("idle")

		State.WALK:
			state_timer = 0
			if main_sprite:
				main_sprite.play("walk")

		State.ATTACK_BLUE:
			state_timer = attack_duration
			velocity = Vector2.ZERO
			blue_dealt_damage = false # Blue 데미지 플래그 리셋
			if main_sprite:
				main_sprite.play("attackBlue")

			# 플레이어 방향 보기
			var target_player = player if player != null else get_tree().get_first_node_in_group("player")
			if target_player and main_sprite:
				var dir_to_player = target_player.global_position.x - global_position.x
				main_sprite.flip_h = (dir_to_player > 0)

			# AttackArea 위치를 현재 보는 방향에 맞춰 설정 (scale 2 고려)
			if attack_area and main_sprite:
				if main_sprite.flip_h: # 오른쪽 (flip된 상태)
					attack_area.position.x = -12
				else: # 왼쪽 (기본 상태)
					attack_area.position.x = 12

		State.ATTACK_PURPLE:
			state_timer = attack_duration
			velocity = Vector2.ZERO
			purple_dealt_damage = false # Purple 데미지 플래그 리셋
			if main_sprite:
				main_sprite.play("attackPurple")

			# AttackArea 위치를 현재 보는 방향에 맞춰 설정 (scale 2 고려)
			if attack_area and main_sprite:
				if main_sprite.flip_h: # 오른쪽 (flip된 상태)
					attack_area.position.x = -12
				else: # 왼쪽 (기본 상태)
					attack_area.position.x = 12

		State.COOLDOWN:
			state_timer = attack_cooldown
			velocity = Vector2.ZERO
			if main_sprite:
				main_sprite.play("idle")

#endregion

#region 신호 콜백

func _on_sprite_frame_changed():
	if not main_sprite or not attack_area:
		print("sprite 또는 attack_area가 없음")
		return

	var current_frame = main_sprite.frame
	var current_anim = main_sprite.animation
	print("프레임 변경: ", current_anim, " - 프레임 ", current_frame)

	# Blue 공격 중일 때
	if current_state == State.ATTACK_BLUE and current_frame == blue_hit_frame:
		print("Blue 공격 히트 프레임! (프레임 ", blue_hit_frame, ")")
		if not blue_dealt_damage:
			check_attack_hit()
			blue_dealt_damage = true
			print("Blue 데미지 처리 완료")
		else:
			print("Blue 이미 데미지 처리됨")

	# Purple 공격 중일 때
	elif current_state == State.ATTACK_PURPLE and current_frame == purple_hit_frame:
		print("Purple 공격 히트 프레임! (프레임 ", purple_hit_frame, ")")
		if not purple_dealt_damage:
			check_attack_hit()
			purple_dealt_damage = true
			print("Purple 데미지 처리 완료")
		else:
			print("Purple 이미 데미지 처리됨")

func check_attack_hit():
	if not attack_area:
		print("attack_area가 없음!")
		return

	# 플레이어 정보 확인
	var player = get_tree().get_first_node_in_group("player")
	if player:
		print("플레이어 글로벌 위치: ", player.global_position)
		print("플레이어 collision_layer: ", player.collision_layer)
		print("플레이어 collision_mask: ", player.collision_mask)
		var distance = attack_area.global_position.distance_to(player.global_position)
		print("AttackArea와 플레이어 거리: ", distance)
	else:
		print("플레이어를 찾을 수 없음!")

	print("AttackArea 글로벌 위치: ", attack_area.global_position)
	print("AttackArea 로컬 위치: ", attack_area.position)
	print("AttackArea collision_mask: ", attack_area.collision_mask)
	print("AttackArea monitoring: ", attack_area.monitoring)
	print("보스 flip_h: ", main_sprite.flip_h if main_sprite else "sprite 없음")

	# CollisionShape2D 확인
	var collision_shape = attack_area.get_node_or_null("CollisionShape2D")
	if collision_shape:
		print("CollisionShape2D disabled: ", collision_shape.disabled)
		print("CollisionShape2D shape: ", collision_shape.shape)
	else:
		print("CollisionShape2D를 찾을 수 없음!")

	var overlapping_bodies = attack_area.get_overlapping_bodies()
	print("겹치는 body 수: ", overlapping_bodies.size())

	for body in overlapping_bodies:
		print("Body 발견: ", body.name, ", 그룹: ", body.get_groups())
		if body.is_in_group("player"):
			print("=== 플레이어 감지! 데미지 처리 ===")
			if body.has_method("lose_life"):
				body.lose_life()
				print("플레이어 lose_life() 호출됨")
			else:
				print("플레이어에 lose_life() 메서드 없음")
		else:
			print("플레이어 그룹이 아님")

func _on_animation_finished():
	# 애니메이션이 끝났을 때 추가 처리가 필요하면 여기에
	pass

#endregion

#region 광폭화 시스템

func check_enrage():
	# 이미 광폭화 상태면 체크하지 않음
	if is_enraged:
		return

	# 체력이 임계값 이하가 되면 광폭화 발동
	if current_health <= enrage_health_threshold:
		activate_enrage()

func activate_enrage():
	if is_enraged:
		return

	is_enraged = true

	# 이동 속도 증가
	move_speed = base_move_speed * enraged_move_speed_multiplier

	# 공격 쿨타임 감소 (더 빠른 공격)
	attack_cooldown = base_attack_cooldown * enraged_attack_cooldown_multiplier

	print("=== JungleBoss 광폭화 발동! ===")
	print("이동 속도: ", base_move_speed, " -> ", move_speed)
	print("공격 쿨타임: ", base_attack_cooldown, " -> ", attack_cooldown)

	# 시각적 효과 추가 가능 (예: 스프라이트 색상 변경, 파티클 이펙트 등)
	if main_sprite:
		# 빨간색 틴트를 줘서 광폭화 상태를 시각적으로 표현
		main_sprite.modulate = Color(1.5, 0.8, 0.8, 1.0)

#endregion
