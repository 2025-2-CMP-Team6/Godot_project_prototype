extends BaseSkill

#region 1. 노드 참조 & 설정
# 템플릿의 hitbox 대신, 복제해서 쓸 총알 원본을 가져옵니다.
@onready var bullet_template = $BulletTemplate

func _init():
	# [설계 사항 입력]
	# 타겟팅 필요 여부 (false: 논타겟 스킬, 바라보는 방향 발사)
	requires_target = false
	
	# 중력 적용 비율 (1.0: 땅에 붙어있음, 시전 중 붕 뜨지 않음)
	gravity_multiplier = 1.0
	
	# 조건부 종료 여부 (false: 시전 시간 지나면 스킬 상태 끝)
	ends_on_condition = false

func _ready():
	super._ready() # ★ 필수: 쿨타임 타이머 초기화
	
	# 총알 원본은 게임 시작 시 안 보이게 꺼둡니다.
	if bullet_template:
		bullet_template.visible = false
		bullet_template.monitoring = false
#endregion

#region 2. 스킬 실행 (Execute)
# 플레이어가 스킬 키를 눌렀을 때 딱 1번 실행됩니다.
func execute(owner: CharacterBody2D, target: Node2D = null):
	super.execute(owner, target) # ★ 필수: 상태값 변경
	
	print(skill_name + " 발동! (파이어볼)")
	
	# [실행 로직]
	# 1. 총알 복제 (Instantiate 대신 Duplicate 사용)
	var bullet = bullet_template.duplicate()
	
	# 2. 복제된 총알 설정
	bullet.visible = true
	bullet.monitoring = true
	bullet.top_level = true # ★ 중요: 플레이어를 따라다니지 않고 월드 좌표계 사용
	bullet.global_position = owner.global_position # 위치: 플레이어 위치
	
	# 3. 방향 설정
	var direction = Vector2.RIGHT
	var angle_right = -138.2
	var angle_left = 138.2

	# owner.visuals.scale.x가 음수인지 확인 (왼쪽을 보고 있는지)
	if owner.visuals.scale.x < 0: 
		direction = Vector2.LEFT 
		
		# 왼쪽일 때: 스케일 뒤집고, 각도는 양수(+) 사용
		bullet.scale.x = -abs(bullet.scale.x)
		bullet.rotation_degrees = angle_left 
	else:
		# 오른쪽일 때: 스케일 정상, 각도는 음수(-) 사용
		bullet.scale.x = abs(bullet.scale.x)
		bullet.rotation_degrees = angle_right

	
	# 4. 씬 트리에 추가 (발사!)
	get_tree().current_scene.add_child(bullet)
	
	# 5. 날아가게 만들기 (Tween 사용)
	var tween = create_tween()
	var distance = 800.0 # 사거리
	var travel_time = 1.0 # 탄속 (작을수록 빠름)
	
	# 현재 위치에서 방향*거리 만큼 이동시켜라
	tween.tween_property(bullet, "global_position", bullet.global_position + (direction * distance), travel_time)
	tween.tween_callback(bullet.queue_free) # 다 날아가면 삭제
	
	# 6. 충돌 연결 (관통 버전)
	bullet.body_entered.connect(func(body):
		if body.is_in_group("enemies"):
			# 1. 데미지 주기
			if body.has_method("take_damage"):
				body.take_damage(damage)

			
			#  관통했다는 느낌을 주기 위해 약간 투명해지게 함
			bullet.modulate.a = 0.8 
			print("적 관통!")
			
		elif body != owner: 
			bullet.queue_free()
	)

	# 7. 종료 타이머 설정 (플레이어 경직 시간)
	if not ends_on_condition:
		# cast_duration 만큼 지나면 _on_skill_finished 호출
		get_tree().create_timer(cast_duration).timeout.connect(_on_skill_finished)

# 스킬이 끝났을 때 호출할 함수
func _on_skill_finished():
	# 투사체 방식은 발사 후 할 게 별로 없지만, 
	# 만약 캐스팅 바 같은 UI가 있다면 여기서 끕니다.
	pass
#endregion

#region 3. 물리 처리 (Physics)
# 스킬 시전 중 매 프레임 실행됩니다.
func process_skill_physics(owner: CharacterBody2D, delta: float):
	# 시전 시간(Cast Duration) 동안 플레이어 멈추기 (선딜레이)
	# 이동키를 눌러도 못 움직이게 속도를 0으로 고정
	owner.velocity.x = 0
#endregion

#region 4. 충돌 처리 (Collision)
# ★ 투사체 방식에서는 사용하지 않습니다. 
# (위의 execute 함수 안에서 bullet.body_entered로 처리했습니다)
func _on_hitbox_area_entered(area):
	pass
#endregion
