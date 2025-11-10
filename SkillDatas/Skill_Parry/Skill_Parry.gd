# Skill_Parry.gd
extends BaseSkill

#region 노드 참조
@onready var parry_box = $ParryBox
#endregion

func _ready():
    super._ready()
    # 패링 판정 비활성화
    if parry_box:
        parry_box.monitoring = false

#region 스킬 로직
func execute(owner: CharacterBody2D, target: Node2D = null):
    print(owner.name + "가 " + skill_name + " 시전!")
    
    # 패링 판정 활성화
    if parry_box:
        parry_box.monitoring = true
    
    # 패링 종료 타이머
    get_tree().create_timer(cast_duration).timeout.connect(_on_parry_finished)

func _on_parry_finished():
    # 패링 판정 비활성화
    if parry_box:
        parry_box.monitoring = false

func process_skill_physics(owner: CharacterBody2D, delta: float):
    # 플레이어 고정
    owner.velocity = Vector2.ZERO

func _on_parry_box_area_entered(area):
    if area.is_in_group("enemy_attacks"):
        print("★★★ 패링 성공! ★★★")
        # 투사체 제거
        area.queue_free()
        
        # TODO: 패링 성공 시 보상 로직을 추가합니다. (예: 스태미나 회복)
        
        # 패링 즉시 종료
        _on_parry_finished()
#endregion