# BaseSkill.gd
extends Node
class_name BaseSkill

#region 스킬 속성
@export var skill_name: String = "기본 스킬"
@export var skill_description: String = "스킬 설명."
@export var skill_icon: Texture
@export var cast_duration: float = 0.3
@export var stamina_cost: float = 10.0
@export var cooldown: float = 1.0
@export var type: int = 1
@export var requires_target: bool = false
@export var ends_on_condition: bool = false
@export var damage: float = 10.0
@export var max_cast_range: float = 0.0
@export var gravity_multiplier: float = 1.0
#endregion

var cooldown_timer: Timer
var is_active: bool = false

# ★ (추가) 이 스킬 노드의 현재 레벨 (SkillInstance로부터 받아옴)
var current_level: int = 0

# ★ (추가) 이 스킬이 참조하는 인벤토리의 원본 데이터 (SkillInstance)
var skill_instance_ref: SkillInstance = null

func _ready():
	cooldown_timer = Timer.new()
	cooldown_timer.one_shot = true
	add_child(cooldown_timer)

# 스킬 사용 가능 여부
func is_ready() -> bool:
	if cooldown_timer == null:
		return false
	return cooldown_timer.is_stopped()

#region 스킬 시전
func execute(owner: CharacterBody2D, target: Node2D = null):
	is_active = true
	print(owner.name + "가 " + skill_name + " 시전!")

func start_cooldown():
	if cooldown_timer != null:
		cooldown_timer.wait_time = cooldown
		cooldown_timer.start()
		
func process_skill_physics(owner: CharacterBody2D, delta: float):
	pass

func get_cooldown_time_left() -> float:
	if cooldown_timer != null:
		return cooldown_timer.time_left
	return 0.0
#endregion