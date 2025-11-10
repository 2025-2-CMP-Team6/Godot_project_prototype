# Skill_Melee.gd
extends BaseSkill

#region 노드 참조
@onready var hitbox = $Hitbox
@onready var hitbox_shape = $Hitbox/CollisionShape2D
#endregion

func _ready():
	super._ready()
	# 히트박스 비활성화
	if hitbox_shape:
		hitbox_shape.disabled = true
		
	# 충돌 시그널 연결
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	hitbox.body_entered.connect(_on_hitbox_body_entered)

#region 스킬 로직
func execute(owner: CharacterBody2D, target: Node2D = null):
	super.execute(owner, target)
	# 히트박스 활성화
	if hitbox_shape:
		hitbox_shape.disabled = false
	
	# 공격 종료 타이머
	get_tree().create_timer(cast_duration).timeout.connect(_on_attack_finished)

func _on_attack_finished():
	if hitbox_shape:
		hitbox_shape.disabled = true
		
func process_skill_physics(owner: CharacterBody2D, delta: float):
	owner.velocity = Vector2.ZERO

func _on_hitbox_area_entered(area):
	if area.is_in_group("enemies"):
		EffectManager.play_screen_shake(8.0, 0.1)
		EffectManager.play_screen_flash(Color.WHITE, 0.05)

func _on_hitbox_body_entered(body):
	if body.is_in_group("enemies"):
		EffectManager.play_screen_shake(8.0, 0.1)
		EffectManager.play_screen_flash(Color.WHITE, 0.05)
#endregion