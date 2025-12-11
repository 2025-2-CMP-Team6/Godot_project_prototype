extends BaseSkill

#region 스킬 설정
@export var heal_amount: int = 3     
@export var max_overheal: int = 2      # 최대 추가체력
@onready var particles = $HealParticles 
#endregion

# 쿨타임/스태미나 차단용 플래그
var _cancel_activation: bool = false

func _init():
	skill_name = "GreatHeal"
	type = 3 
	requires_target = false 
	cast_duration = 1.0 
	stamina_cost = 50.0 
	gravity_multiplier = 1.0 

func _ready():
	super._ready()
	if particles:
		particles.emitting = false
		particles.one_shot = true

func execute(owner: CharacterBody2D, target: Node2D = null):
	var absolute_max_lives = 7 # 기본값
	if "max_lives" in owner:
		absolute_max_lives = owner.max_lives + max_overheal
	
	# 이미 한계치까지 꽉 찼는지 검사
	if "current_lives" in owner and owner.current_lives >= absolute_max_lives:
		print("오버힐 한계치 도달! 더 이상 회복 불가.")
		
		play_error_sound() 
		_cancel_activation = true # 쿨타임 방지
		
		# 스태미나 환불
		if "current_stamina" in owner:
			owner.current_stamina += stamina_cost
			if "max_stamina" in owner:
				owner.current_stamina = min(owner.current_stamina, owner.max_stamina)
		
		# 모션 취소
		if owner.has_method("change_state"):
			owner.change_state(GameManager.State.IDLE)
		return

	# 정상 발동
	super.execute(owner, target)
	_cancel_activation = false
	
	print("GreatHeal 발동!")

	if owner.has_method("change_state"):
		owner.change_state(GameManager.State.SKILL_CASTING)

	if "current_lives" in owner:
		# 예상 회복량: 현재 + 3
		var potential_lives = owner.current_lives + heal_amount
		
		# 둘 중 작은 값을 선택 (예상치 vs 한계치)
		owner.current_lives = min(potential_lives, absolute_max_lives)
		
		owner.update_lives_ui() # 노란 하트 그리기 (Player.gd 로직)
		print(" - 생명 회복! 현재: ", owner.current_lives, " / 절대한계: ", absolute_max_lives)

	if particles:
		particles.restart()
		particles.emitting = true
	
	get_tree().create_timer(cast_duration).timeout.connect(_on_skill_finished)

# 쿨타임 제어
func start_cooldown():
	if _cancel_activation:
		_cancel_activation = false
		return 
	super.start_cooldown()

func _on_skill_finished():
	is_active = false
	if particles:
		particles.emitting = false
