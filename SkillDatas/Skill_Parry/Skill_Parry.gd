# Skill_Parry.gd
extends BaseSkill

#region 노드 참조
@onready var parry_box = $ParryBox
#endregion

#region 초기화
func _init():
	# ★ 'ignore_gravity' 대신 이 변수를 사용해야 합니다.
	gravity_multiplier = 0.2
	
func _ready():
	super._ready()
	if parry_box:
		parry_box.monitoring = false
#endregion

#region 스킬 로직
func execute(owner: CharacterBody2D, target: Node2D = null):
	super.execute(owner, target) # ★ 필수: 상태값 변경
	print(owner.name + "가 " + skill_name + " 시전!")
	if parry_box:
		parry_box.monitoring = true
	get_tree().create_timer(cast_duration).timeout.connect(_on_parry_finished)

func _on_parry_finished():
	if parry_box:
		parry_box.monitoring = false

func process_skill_physics(owner: CharacterBody2D, delta: float):
	owner.velocity.x = 0

func _on_parry_box_area_entered(area):
	if area.is_in_group("enemy_attacks"):
		print("★★★ 패링 성공! ★★★")
		area.queue_free()
		_on_parry_finished()
#endregion
