extends CharacterBody2D

const BaseSkill = preload("res://BaseSkill.gd")

# [조작감 세팅 - 이동]
@export var max_speed: float = 400.0     # 평소 최고 속도
@export var acceleration: float = 2000.0 # 가속도
@export var friction: float = 800.0      # 마찰력 (미끄러지는 정도)

# [조작감 세팅 - 대시]
@export var dash_speed: float = 1000.0   # 대시 속도
@export var dash_friction: float = 2500.0 # 대시 전용 마찰력
@export var dash_duration: float = 0.1   # 대시 지속 시간
@export var dash_cooldown: float = 0.8   # 대시 쿨타임

# [조작감 세팅 - 전이 상태]
@export var anticipation_duration: float = 0.1 # 대시 준비 시간

# [조작감 세팅 - 스태미나]
@export var max_stamina: float = 100.0
@export var dash_cost: float = 35.0         # 대시 1회 소모값
@export var stamina_regen_rate: float = 20.0  # 초당 회복량

# -------------------------------------------------------------------
# ★ 상태 머신 핵심 ★
# -------------------------------------------------------------------
enum State {
	IDLE,          # 완전 정지
	MOVE,          # 이동 (가속/등속)
	MOVE_TO_IDLE,  # 감속 (미끄러짐)
	MOVE_TO_DASH,  # 대시 준비 (움찔!)
	DASH,          # 대시 돌진
	DASH_TO_IDLE,  # 대시 후 감속 (미끄러짐)
	SKILL_CASTING  # ★ 모든 스킬을 위한 '범용' 시전 상태
}

# --- 상태 변수 ---
var current_state = State.IDLE
var can_dash: bool = true
var dash_direction: Vector2 = Vector2.ZERO
var current_stamina: float = 0.0
var current_casting_skill: BaseSkill = null # ★ 현재 시전 중인 스킬 (타입 지정)

# -------------------------------------------------------------------
# --- 노드 캐시 ---
# -------------------------------------------------------------------
# 타이머
@onready var duration_timer = $DashDurationTimer       # 대시 지속시간
@onready var cooldown_timer = $DashCooldownTimer       # 대시 쿨타임
@onready var anticipation_timer = $AnticipationTimer   # 대시 준비
@onready var skill_cast_timer = $SkillCastTimer        # 범용 스킬 시전시간

# UI
@onready var state_label = $StateDebugLabel
@onready var stamina_bar = $StaminaBar

# 스킬 슬롯 (빈 노드)
@onready var skill_1_slot = $Skill1Slot # (마우스 좌클릭)
@onready var skill_2_slot = $Skill2Slot # (Q키)
@onready var skill_3_slot = $Skill3Slot # (E키)
# -------------------------------------------------------------------

func _ready():
	# 타이머 시그널 연결
	duration_timer.timeout.connect(_on_dash_duration_timeout)
	cooldown_timer.timeout.connect(_on_dash_cooldown_timeout)
	anticipation_timer.timeout.connect(_on_anticipation_timeout)
	skill_cast_timer.timeout.connect(_on_skill_cast_timeout)
	
	# 스태미나 초기화
	current_stamina = max_stamina
	stamina_bar.max_value = max_stamina
	stamina_bar.value = current_stamina
	
	# ★ 테스트용: 1번 슬롯에 '평타' 스킬 강제 장착
	# (BaseSkill.gd를 상속받는 Skill_Melee.tscn 씬이 res:// 경로에 있어야 함)
	equip_skill("res://Skill_Melee.tscn", 1) 
	
	change_state(State.IDLE)


func _physics_process(delta: float):
	# 디버그 레이블 업데이트
	state_label.text = State.keys()[current_state]

	# 스태미나 재생 로직
	# 스킬 시전, 대시 준비, 대시 중이 아닐 때만 스태미나 회복
	match current_state:
		State.IDLE, State.MOVE, State.MOVE_TO_IDLE, State.DASH_TO_IDLE:
			regenerate_stamina(delta)

	# 현재 상태에 맞는 로직 실행
	match current_state:
		State.IDLE:
			state_logic_idle(delta)
		State.MOVE:
			state_logic_move(delta)
		State.MOVE_TO_IDLE:
			state_logic_move_to_idle(delta)
		State.MOVE_TO_DASH:
			state_logic_move_to_dash(delta)
		State.DASH:
			state_logic_dash(delta)
		State.DASH_TO_IDLE:
			state_logic_dash_to_idle(delta)
		State.SKILL_CASTING:
			state_logic_skill_casting(delta)
	
	# 스태미나 바 UI
	stamina_bar.value = current_stamina
	
	move_and_slide()


# 스태미나 회복
func regenerate_stamina(delta: float):
	current_stamina = clamp(current_stamina + stamina_regen_rate * delta, 0, max_stamina)

# -------------------------------------------------------------------
# 상태별 실행(Logic) 로직 함수
# -------------------------------------------------------------------

# 1. IDLE
func state_logic_idle(_delta: float):
	velocity = Vector2.ZERO
	
	# 이동 입력이 있으면 MOVE 상태로 전환
	if Input.get_vector("move_left", "move_right", "move_up", "move_down"):
		change_state(State.MOVE)
	else:
		handle_inputs() # 이동 외 다른 입력 처리

# 2. MOVE 
func state_logic_move(delta: float):
	# 입력 감지
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if direction:
		# 가속
		velocity = velocity.move_toward(direction.normalized() * max_speed, acceleration * delta)
	else:
		# 감속 상태로 전환
		change_state(State.MOVE_TO_IDLE)
	
	handle_inputs() # 이동 중 다른 입력 처리

# 3. MOVE_TO_IDLE
func state_logic_move_to_idle(delta: float):
	# 감속
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	if velocity == Vector2.ZERO:
		change_state(State.IDLE)
		
	# 이동 입력이 있으면 다시 MOVE 상태로 전환 (감속 캔슬)
	if Input.get_vector("move_left", "move_right", "move_up", "move_down"):
		change_state(State.MOVE)
	else:
		handle_inputs() # 이동 외 다른 입력 처리

# 4. MOVE_TO_DASH
func state_logic_move_to_dash(_delta: float):
	velocity = Vector2.ZERO # 준비 상태에선 멈춤

# 5. DASH
func state_logic_dash(_delta: float):
	velocity = dash_direction * dash_speed # 고정 속도로 돌진

# 6. DASH_TO_IDLE
func state_logic_dash_to_idle(delta: float):
	velocity = velocity.move_toward(Vector2.ZERO, dash_friction * delta)
	if velocity == Vector2.ZERO:
		change_state(State.IDLE)
	
	# 이동 입력이 있으면 다시 MOVE 상태로 전환
	if Input.get_vector("move_left", "move_right", "move_up", "move_down"):
		change_state(State.MOVE)
	else:
		handle_inputs() # 이동 외 다른 입력 처리 (미끄러지는 중 캔슬 가능)

# 7. SKILL_CASTING
func state_logic_skill_casting(_delta: float):
	# 기본적으로 멈춤. (특수 스킬은 이 함수를 오버라이드해야 함)
	velocity = Vector2.ZERO


# -------------------------------------------------------------------
# ★ 입력 처리 함수 ★
# -------------------------------------------------------------------

# 이동을 제외한 입력을 처리하는 함수
func handle_inputs():
	# 1순위: 스킬 1 (마우스 좌클릭)
	if Input.is_action_just_pressed("skill_1"):
		try_cast_skill(skill_1_slot)
		
	# 2순위: 스킬 2 (Q) - (Input Map에 "skill_2"로 Q키 등록 필요)
	elif Input.is_action_just_pressed("skill_2"):
		try_cast_skill(skill_2_slot)
		
	# 3순위: 스킬 3 (E) - (Input Map에 "skill_3"로 E키 등록 필요)
	elif Input.is_action_just_pressed("skill_3"):
		try_cast_skill(skill_3_slot)

	# 4순위: 대시 (Shift)
	elif Input.is_action_just_pressed("dash") and can_dash:
		# 스태미나 체크
		if current_stamina >= dash_cost:
			change_state(State.MOVE_TO_DASH)
		else:
			pass # 스태미나 부족

# -------------------------------------------------------------------
# ★ 스킬 시도 및 장착 함수 ★
# -------------------------------------------------------------------

# 스킬 시도 함수
func try_cast_skill(slot_node: Node):
	# 1. 슬롯이 비었는지 확인
	if slot_node.get_child_count() == 0:
		print("슬롯이 비어있음")
		return

	# 2. 장착된 스킬 가져오기 (BaseSkill.gd 타입으로)
	var skill: BaseSkill = slot_node.get_child(0)
	if skill == null: return

	# 3. 스킬 사용 조건 체크 (쿨타임, 스태미나)
	if skill.is_ready() and current_stamina >= skill.stamina_cost:
		current_casting_skill = skill # "현재 이 스킬을 시전합니다"라고 저장
		change_state(State.SKILL_CASTING) # "플레이어"는 시전 상태로
	else:
		print(skill.skill_name + " 스킬 준비 안 됨 (쿨타임 또는 스태미나 부족)")


# 스킬 '장착/갈아끼우기' 함수
func equip_skill(skill_scene_path: String, slot_number: int):
	var slot_node: Node = null
	
	# 1. 어느 슬롯에 장착할지 찾기
	match slot_number:
		1:
			slot_node = skill_1_slot
		2:
			slot_node = skill_2_slot
		3:
			slot_node = skill_3_slot
		_:
			print("잘못된 슬롯 번호입니다.")
			return

	# 2. 해당 슬롯에 이미 스킬이 있다면 파괴
	if slot_node.get_child_count() > 0:
		for child in slot_node.get_children():
			child.queue_free()

	# 3. 새 스킬 프리팹(씬) 로드 및 인스턴스화
	var skill_scene = load(skill_scene_path)
	if skill_scene == null:
		print("스킬 씬 경로 오류: " + skill_scene_path)
		return
		
	var new_skill_instance = skill_scene.instantiate()
	
	# 4. 슬롯 노드의 자식으로 스킬 인스턴스 추가 (장착!)
	slot_node.add_child(new_skill_instance)
	
	# BaseSkill.gd에 접근 가능한지 확인
	if new_skill_instance is BaseSkill:
		print(new_skill_instance.skill_name + "을(를) " + str(slot_number) + "번 슬롯에 장착!")
	else:
		print("장착된 씬이 BaseSkill.gd를 상속받지 않았습니다.")

# -------------------------------------------------------------------
# ★ 상태 '변경(Change)' 로직 함수 (진입 로직) ★
# -------------------------------------------------------------------

func change_state(new_state: State):
	if current_state == new_state:
		return

	current_state = new_state

	match new_state:
		State.IDLE:
			pass
			
		State.MOVE:
			pass
		
		State.MOVE_TO_IDLE:
			pass
			
		State.MOVE_TO_DASH:
			current_stamina -= dash_cost
			
			var mouse_position = get_global_mouse_position()
			dash_direction = (mouse_position - global_position).normalized()
			
			if dash_direction == Vector2.ZERO:
				change_state(State.IDLE)
				return # ★ 중요: 타이머 시작 방지

			can_dash = false
			anticipation_timer.wait_time = anticipation_duration
			anticipation_timer.start()
			
		State.DASH:
			duration_timer.wait_time = dash_duration
			duration_timer.start()
	
		State.DASH_TO_IDLE:
			pass

		State.SKILL_CASTING:
			if current_casting_skill == null: return

			# 1. 스태미나 소모
			current_stamina -= current_casting_skill.stamina_cost
			
			# 2. 장착된 스킬의 'execute' 함수 호출 (스킬 효과 발동!)
			current_casting_skill.execute(self) 
			
			# 3. 스킬 쿨타임 시작
			current_casting_skill.start_cooldown()
			
			# 4. '플레이어'가 멈춰있을 시간을 '스킬'로부터 받아옴
			skill_cast_timer.wait_time = current_casting_skill.cast_duration
			skill_cast_timer.start()


# -------------------------------------------------------------------
# ★ 타이머 시그널 함수 ★
# -------------------------------------------------------------------

func _on_anticipation_timeout():
	change_state(State.DASH)

func _on_dash_duration_timeout():
	change_state(State.DASH_TO_IDLE)
	cooldown_timer.wait_time = dash_cooldown
	cooldown_timer.start()

func _on_dash_cooldown_timeout():
	can_dash = true

func _on_skill_cast_timeout():
	change_state(State.IDLE)
	current_casting_skill = null
