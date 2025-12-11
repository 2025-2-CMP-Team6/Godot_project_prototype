extends BaseSkill

#region 1. 노드 참조 & 설정
# 총알 복제
@onready var bullet_template = $BulletTemplate

func _init():
	# 타겟팅 필요 여부 (false: 논타겟 스킬, 바라보는 방향 발사)
	requires_target = false
	# 중력 적용 비율 (1.0: 땅에 붙어있음, 시전 중 붕 뜨지 않음)
	gravity_multiplier = 1.0
	# 조건부 종료 여부 (false: 시전 시간 지나면 스킬 상태 끝)
	ends_on_condition = false

func _ready():
	super._ready() # 쿨타임 타이머 초기화

	if bullet_template:
		bullet_template.visible = false
		bullet_template.monitoring = false
#endregion

# region 2. 스킬 실행 (Execute)
func execute(owner: CharacterBody2D, target: Node2D = null):
	super.execute(owner, target) # 상태값 변경
	
	print(skill_name + " 발동! (멀티샷)")
	
	# --- [설정 값] ---
	var bullet_count = 3       # 발사할 총알 개수
	var spread_angle = 15.0    # 총알 사이의 각도 (벌어지는 정도)
	var distance = 600.0       # 사거리
	var travel_time = 0.8      # 날아가는 시간
	
	# 불렛의 기본 회전각
	var angle_right = -138.2
	var angle_left = 138.2
	# ----------------
	
	# 여러 발 발사 (3발 기준)
	for i in range(bullet_count):
		# 1. 총알 복제
		var bullet = bullet_template.duplicate()
		bullet.visible = true
		bullet.monitoring = true
		bullet.top_level = true
		bullet.global_position = owner.global_position
		
		# 씬 트리에 먼저 추가 (그래야 rotation 제어가 잘 먹힘)
		get_tree().current_scene.add_child(bullet)

		# 2. 방향 및 기본 회전 설정
		var base_direction = Vector2.RIGHT
		var base_rotation = 0.0
		
		# owner.visuals.scale.x가 음수인지 확인 (왼쪽을 보고 있는지)
		if owner.visuals.scale.x < 0: 
			base_direction = Vector2.LEFT 
			
			# 왼쪽일 때: 스케일 뒤집고, 각도는 양수(+) 사용
			bullet.scale.x = -abs(bullet.scale.x)
			base_rotation = angle_left
		else:
			# 오른쪽일 때: 스케일 정상, 각도는 음수(-) 사용
			bullet.scale.x = abs(bullet.scale.x)
			base_rotation = angle_right

		# 3. 멀티샷 각도 계산 (부채꼴 만들기)
		# i=0(-15도), i=1(0도), i=2(+15도) 식으로 벌어짐
		var center_index = float(bullet_count - 1) / 2.0
		var spread_offset = spread_angle * (i - center_index)
		
		# 왼쪽 볼 때는 각도 방향을 반대로 해줘야 예쁘게 벌어짐
		if base_direction == Vector2.LEFT:
			spread_offset = -spread_offset

		# 최종 각도 적용 (기본 각도 + 벌어지는 각도)
		bullet.rotation_degrees = base_rotation + spread_offset
		
		# 4. 날아갈 방향 벡터 계산
		# 중요: 총알이 회전한 만큼 날아가는 방향도 회전해야 함
		# base_direction을 (spread_offset)만큼만 회전시킴
		# (이미지가 누워있어서 angle_right를 쓰는 것 같으니, 이동 방향은 따로 계산)
		var travel_direction = base_direction.rotated(deg_to_rad(spread_offset))
		
		# 5. 날리기 (Tween)
		var tween = create_tween()
		tween.tween_property(bullet, "global_position", bullet.global_position + (travel_direction * distance), travel_time)
		tween.tween_callback(bullet.queue_free)

		# 6. 충돌 연결
		bullet.body_entered.connect(func(body):
			if body.is_in_group("enemies"):
				if body.has_method("take_damage"):
					body.take_damage(damage)
				bullet.queue_free() # 맞으면 삭제
			elif body != owner:
				bullet.queue_free() # 벽에 맞으면 삭제
		)

	# 7. 종료 타이머 설정 (플레이어 경직 시간)
	if not ends_on_condition:
		# cast_duration 만큼 지나면 _on_skill_finished 호출
		get_tree().create_timer(cast_duration).timeout.connect(_on_skill_finished)

# 스킬이 끝났을 때 호출할 함수
func _on_skill_finished():
	pass
#endregion

#region 3. 물리 처리 (Physics)
func process_skill_physics(owner: CharacterBody2D, delta: float):
	owner.velocity.x = 0
#endregion

#region 4. 충돌 처리 (Collision)
func _on_hitbox_area_entered(area):
	pass
#endregion
