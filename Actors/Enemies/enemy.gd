# actors/enemies/enemy.gd
extends CharacterBody2D

#region 총알 발사
const BULLET_SCENE = preload("res://Actors/Enemies/bullet.tscn")
@onready var fire_timer = $FireTimer
@onready var muzzle = $Muzzle
#endregion

#region 속성
@export var max_health: float = 100.0
var current_health: float
# 사망 시그널
signal enemy_died
@export var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
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
	# 시그널 중복 연결 방지
	if fire_timer != null:
		for conn in fire_timer.timeout.get_connections():
			fire_timer.timeout.disconnect(conn.callable)
	
	if hurtbox != null:
		for conn in hurtbox.area_entered.get_connections():
			hurtbox.area_entered.disconnect(conn.callable)
	
	if i_frames_timer != null:
		for conn in i_frames_timer.timeout.get_connections():
			i_frames_timer.timeout.disconnect(conn.callable)
		
	# 시그널 연결
	if fire_timer != null:
		fire_timer.timeout.connect(shoot)
	
	if hurtbox != null:
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	
	if i_frames_timer != null:
		i_frames_timer.timeout.connect(_on_i_frames_timeout)
	
	current_health = max_health
	
	# 쉐이더 머티리얼 복제
	if sprite and sprite.material:
		sprite.material = sprite.material.duplicate()
	
	# 쉐이더 초기화
	if sprite:
		EffectManager.set_hit_flash_amount(sprite, 0.0)
#endregion

#region 물리 처리
func _physics_process(delta: float):
	# 1. (추가) 중력 적용
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. 무적 상태일 때 점멸 효과
	if is_invincible:
		var is_flash_on = (int(Time.get_ticks_msec() / 100) % 2) == 0
		if is_flash_on:
			if sprite:
				EffectManager.set_hit_flash_amount(sprite, 1.0)
		else:
			if sprite:
				EffectManager.set_hit_flash_amount(sprite, 0.0)
	else:
		if sprite:
			EffectManager.set_hit_flash_amount(sprite, 0.0)
	
	# 3. (추가) 이동 적용
	move_and_slide()
#endregion

#region 전투
# 총알을 발사합니다.
func shoot():
	var random_angle = randf_range(0, TAU)
	var direction = Vector2.RIGHT.rotated(random_angle)
	var bullet = BULLET_SCENE.instantiate()
	bullet.direction = direction
	bullet.global_position = muzzle.global_position
	get_parent().add_child(bullet)

# 데미지를 받아 체력을 깎습니다.
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

# Hurtbox 영역에 다른 Area가 들어왔을 때 호출됩니다.
func _on_hurtbox_area_entered(area):
	if area.is_in_group("player_attack"):
		var skill_node = area.get_parent()
		if skill_node != null and "damage" in skill_node:
			take_damage(skill_node.damage)
		else:
			take_damage(10.0) # 기본 데미지

# 적이 사망했을 때 처리 로직입니다.
func die():
	print(self.name + " 사망.")
	if fire_timer != null:
		fire_timer.stop()
	is_invincible = false
	if sprite:
		EffectManager.set_hit_flash_amount(sprite, 0.0)
	emit_signal("enemy_died") # 시그널
	queue_free()

# 무적 시간이 종료되었을 때 호출됩니다.
func _on_i_frames_timeout():
	is_invincible = false
	if sprite:
		EffectManager.set_hit_flash_amount(sprite, 0.0)
#endregion