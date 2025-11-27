# BaseEnemy.gd
class_name BaseEnemy extends CharacterBody2D

#region 속성
@export var max_health: float = 100.0
var current_health: float
@export var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# 사망 시그널 (모든 적 공통)
signal enemy_died
#endregion

#region 노드 참조
@onready var sprite = $Sprite2D
@onready var hurtbox = $Hurtbox
@onready var i_frames_timer = $IFramesTimer
#endregion

#region 상태 변수
var is_invincible: bool = false
#endregion

#region 초기화
func _ready():
	current_health = max_health
	
	# Hurtbox 연결
	if hurtbox != null:
		# 시그널 중복 연결 방지
		for conn in hurtbox.area_entered.get_connections():
			hurtbox.area_entered.disconnect(conn.callable)
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	
	# 무적 시간 타이머 연결
	if i_frames_timer != null:
		for conn in i_frames_timer.timeout.get_connections():
			i_frames_timer.timeout.disconnect(conn.callable)
		i_frames_timer.timeout.connect(_on_i_frames_timeout)
	
	# 쉐이더 초기화
	if sprite:
		if sprite.material:
			sprite.material = sprite.material.duplicate()
		EffectManager.set_hit_flash_amount(sprite, 0.0)
#endregion

#region 물리 처리

func _physics_process(delta: float):
	# 중력
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# 무적 상태 점멸 효과
	if is_invincible:
		var is_flash_on = (int(Time.get_ticks_msec() / 100) % 2) == 0
		if sprite:
			EffectManager.set_hit_flash_amount(sprite, 1.0 if is_flash_on else 0.0)
	else:
		if sprite:
			EffectManager.set_hit_flash_amount(sprite, 0.0)

	# 이동
	_process_movement(delta)
	move_and_slide()

# 자식 클래스로 오버라이드
func _process_movement(_delta: float):
	pass
#endregion

#region 피격 및 사망
func take_damage(amount: float):
	if is_invincible or current_health <= 0:
		return

	current_health -= amount
	print(self.name + " 피격! 남은 체력: ", current_health)
	
	is_invincible = true
	if i_frames_timer != null:
		i_frames_timer.start()
	
	if current_health <= 0:
		die()

func _on_hurtbox_area_entered(area):
	if area.is_in_group("player_attack"):
		var skill_node = area.get_parent()
		if skill_node != null and "damage" in skill_node:
			take_damage(skill_node.damage)
		else:
			take_damage(10.0)

func die():
	is_invincible = false
	if sprite:
		EffectManager.set_hit_flash_amount(sprite, 0.0)
	emit_signal("enemy_died")
	queue_free()

func _on_i_frames_timeout():
	is_invincible = false
	if sprite:
		EffectManager.set_hit_flash_amount(sprite, 0.0)
#endregion
