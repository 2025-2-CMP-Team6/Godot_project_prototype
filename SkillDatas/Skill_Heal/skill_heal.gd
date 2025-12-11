extends BaseSkill

#region 스킬 고유 설정
@onready var particles = $HealParticles 
#endregion

# 쿨타임 차단용 내부 변수
var _cancel_activation: bool = false

func _init():
	skill_name = "Heal"
	type = 3 
	requires_target = false 
	cast_duration = 0.5
	gravity_multiplier = 1.0 

func _ready():
	super._ready()
	if particles:
		particles.emitting = false
		particles.one_shot = true

func execute(owner: CharacterBody2D, target: Node2D = null):
	# [1단계] 체력이 꽉 찼는지 검사
	if _is_hp_full(owner):
		print("체력이 가득 차서 스킬을 쓸 수 없습니다.")
		play_error_sound()
		_cancel_activation = true
		
		# 스태미나 환불 
		if "current_stamina" in owner:
			owner.current_stamina += stamina_cost
			# 최대치 넘지 않게 보정
			if "max_stamina" in owner:
				owner.current_stamina = min(owner.current_stamina, owner.max_stamina)
		
		# 캐스팅 모션 즉시 취소 (강제 IDLE 전환)
		if owner.has_method("change_state"):
			owner.change_state(GameManager.State.IDLE)
			
		return

	# 정상 발동 
	super.execute(owner, target)
	_cancel_activation = false 
	
	print("힐 스킬 발동!")

	# 플레이어 상태 동기화
	if owner.has_method("change_state"):
		owner.change_state(GameManager.State.SKILL_CASTING)

	# 체력 회복 로직
	if "current_lives" in owner:
		owner.current_lives += 1
		owner.update_lives_ui()
		print(" - 생명 회복! 현재: ", owner.current_lives)
		
	# 이펙트 재생
	if particles:
		particles.restart()
		particles.emitting = true
	
	# 종료 예약
	get_tree().create_timer(cast_duration).timeout.connect(_on_skill_finished)

func start_cooldown():
	# 만약 발동 취소된 상태라면? 쿨타임 타이머를 켜지 않습니다.
	if _cancel_activation:
		_cancel_activation = false # 초기화
		return 

	super.start_cooldown()

func _is_hp_full(owner) -> bool:
	# 하트(Lives) 시스템인 경우
	if "current_lives" in owner and "max_lives" in owner:
		return owner.current_lives >= owner.max_lives
		
	# 체력바(HP) 시스템인 경우
	if "health" in owner and "max_health" in owner:
		return owner.health >= owner.max_health
		
	return false # 변수가 없으면 일단 발동시킴

func _on_skill_finished():
	is_active = false
	if particles:
		particles.emitting = false
