# BaseSkill.gd
# 모든 스킬 씬(프리팹)이 상속받을 '부모' 스크립트
extends Node
class_name BaseSkill

# --- 모든 스킬이 공통으로 가질 데이터 (프리팹에서 수정 가능) ---
@export var skill_name: String = "기본 스킬"
@export var cast_duration: float = 0.3  # 이 스킬을 시전하는 동안 플레이어가 멈출 시간
@export var stamina_cost: float = 10.0  # 스태미나 소모량
@export var cooldown: float = 1.0       # 쿨타임

# --- 스킬 내부 관리용 ---
var cooldown_timer: Timer # 각 스킬 인스턴스가 자신의 쿨타임 타이머를 가짐

func _ready():
    # 스킬 씬이 생성될 때, 스스로 쿨타임 타이머를 만듦
    cooldown_timer = Timer.new()
    cooldown_timer.one_shot = true
    add_child(cooldown_timer) # 타이머를 스킬 씬의 자식으로 추가

# 1. "스킬 사용 준비됐나요?" (플레이어가 물어볼 함수)
func is_ready() -> bool:
    return cooldown_timer.is_stopped()

# 2. "스킬 발사!" (플레이어가 호출할 함수)
#    'owner'는 이 스킬을 사용하는 'Player' 노드 자신입니다.
func execute(owner: CharacterBody2D):
    print(owner.name + "가 " + skill_name + " 시전!")
    # (실제 스킬 효과는 자식 스크립트에서 이 함수를 '오버라이드'해서 구현)
    pass

# 3. "쿨타임 돌리세요!" (플레이어가 호출할 함수)
func start_cooldown():
    cooldown_timer.wait_time = cooldown
    cooldown_timer.start()