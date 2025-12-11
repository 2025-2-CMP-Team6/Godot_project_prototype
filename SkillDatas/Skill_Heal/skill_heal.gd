extends BaseSkill

#region 스킬 설정
@export var heal_amount: float = 30.0 # 회복량
@onready var particles = $HealParticles # 파티클 노드 가져오기
#endregion

func _init():
	skill_name = "치유"
	skill_description = "체력을 회복합니다."
	cooldown = 5.0
	stamina_cost = 20.0
	type = 1 # 번: 특수/방어기
	requires_target = false # 나한테 쓰는 거니까 타겟 불필요
	cast_duration = 0.5 # 0.5초 동안 폼 잡기
	
	# 힐은 제자리에 서서 쓰는 게 국룰 (0.0이면 공중부양, 1.0이면 착지)
	gravity_multiplier = 1.0 

func _ready():
	super._ready()
	
	# 시작할 때 파티클 꺼두기
	if particles:
		particles.emitting = false

#region 스킬 실행
func execute(owner: CharacterBody2D, target: Node2D = null):
	super.execute(owner, target) # 소리 재생 및 상태 변경
	
	# 1. 체력 회복 로직
	# (플레이어 스크립트에 heal 함수가 있다고 가정)
	if owner.has_method("heal"):
		owner.heal(heal_amount)
	elif "health" in owner:
		# heal 함수 없으면 직접 변수 수정
		owner.health += heal_amount
		# 최대 체력 넘치지 않게 (max_health 변수가 있다면)
		if "max_health" in owner and owner.health > owner.max_health:
			owner.health = owner.max_health
			
	print("체력 " + str(heal_amount) + " 회복!")

	# 2. 이펙트 재생 (초록색 반짝반짝 ✨)
	if particles:
		particles.restart() # 파티클 다시 시작
		particles.emitting = true
	
	# 3. 종료 타이머
	# 힐은 즉발이지만, 시전 동작(cast_duration) 후 종료 처리
	get_tree().create_timer(cast_duration).timeout.connect(_on_skill_finished)

func _on_skill_finished():
	is_active = false
	# 파티클은 one_shot이라 알아서 꺼지지만 확실하게
	if particles: particles.emitting = false
#endregion

#region 물리 처리
func process_skill_physics(owner: CharacterBody2D, delta: float):
	# 시전 시간 동안 멈춰있기 (기도하는 느낌)
	owner.velocity.x = move_toward(owner.velocity.x, 0, 50)
#endregion
