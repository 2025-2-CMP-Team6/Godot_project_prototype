# RangedEnemy.gd (기존 enemy.gd 자리에 넣거나 새로 만드세요)
extends BaseEnemy

#region 총알 발사 관련
const BULLET_SCENE = preload("res://Actors/Enemies/bullet.tscn")
@onready var fire_timer = $FireTimer
@onready var muzzle = $Muzzle
#endregion

func _ready():
	super._ready() # ★ 부모(BaseEnemy)의 _ready()를 먼저 실행! (필수)
	
	# 총알 발사 타이머 연결
	if fire_timer != null:
		for conn in fire_timer.timeout.get_connections():
			fire_timer.timeout.disconnect(conn.callable)
		fire_timer.timeout.connect(shoot)

# 공격 패턴 구현
func shoot():
	if current_health <= 0: return # 죽었으면 쏘지 않음
	
	var random_angle = randf_range(0, TAU)
	var direction = Vector2.RIGHT.rotated(random_angle)
	var bullet = BULLET_SCENE.instantiate()
	bullet.direction = direction
	
	if muzzle:
		bullet.global_position = muzzle.global_position
	else:
		bullet.global_position = global_position
		
	get_parent().add_child(bullet)

# (선택 사항) 사망 시 타이머 정지 로직 추가
func die():
	if fire_timer != null:
		fire_timer.stop()
	super.die() # 부모의 die() 실행 (시그널 발송, queue_free 등)
