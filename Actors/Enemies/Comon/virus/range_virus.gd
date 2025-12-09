extends BaseEnemy

#region 설정 변수
@export var move_speed: float = 50.0
@export var attack_range: float = 800.0 # 사거리
@export var current_bullet_speed: float = 400.0
@export var attack_cooldown: float = 3.0

# 상태 변수
var is_attacking: bool = false
var on_cooldown: bool = false
var patrol_direction: int = 1
var patrol_timer: float = 0.0
var player: Node = null
#endregion

#region 노드 참조 (스크린샷 경로 기준)
@onready var main_sprite = $Visuals/AnimatedSprite2D
@onready var wave_effect = $ShockwaveHolder/AttakVisual
# 총알 발사 관련
const BULLET_SCENE = preload("res://Actors/Enemies/bullet.tscn")

#endregion

func _ready():
	super._ready()
	
	wave_effect.visible = false
	
	if not wave_effect.animation_finished.is_connected(_on_wave_finished):
		wave_effect.animation_finished.connect(_on_wave_finished)
		
	if not main_sprite.frame_changed.is_connected(_on_main_sprite_frame_changed):
		main_sprite.frame_changed.connect(_on_main_sprite_frame_changed)

func _process_movement(delta):
	if is_attacking or current_health <= 0:
		velocity.x = move_toward(velocity.x, 0, 200 * delta)
		return

	# 쿨타임 중일 때는 멈춤 또는 회
	if on_cooldown:
		velocity.x = move_toward(velocity.x, 0, 100 * delta)
		main_sprite.play("idle")
		return

	# 플레이어 찾기
	player = get_tree().get_first_node_in_group("player")
	
	if player:
		var dist = global_position.distance_to(player.global_position)
		
		if dist <= attack_range:
			start_attack_sequence()
			print("virus start attack")
			
		elif dist <= (attack_range * 2.0):
			chase_player(player)
			
		else:
			patrol_behavior(delta)
	else:
		patrol_behavior(delta)

	if velocity.x != 0:
		main_sprite.flip_h = (velocity.x < 0)


func chase_player(p):
	var direction = (p.global_position - global_position).normalized()
	velocity.x = direction.x * move_speed
	main_sprite.play("walk")

func patrol_behavior(delta):
	patrol_timer -= delta
	
	# 0.5 ~ 1.0초마다 행동을 바꿈 뽈뽈거리기
	if patrol_timer <= 0:
		patrol_timer = randf_range(0.5, 1.0)
		var random_choice = randi() % 5
		
		# 0, 1 나오면 멈춤 (40% 확률)
		if random_choice <= 1:
			patrol_direction = 0
		# 2: 오른쪽, 3: 왼쪽
		elif random_choice == 2:
			patrol_direction = 1
		elif random_choice == 3:
			patrol_direction = -1
		# 4: 반대 방향으로 턴
		else:
			patrol_direction = - patrol_direction
			
	velocity.x = patrol_direction * (move_speed * 0.5)
	
	if velocity.x == 0:
		main_sprite.play("idle")
	else:
		main_sprite.play("walk")


func start_attack_sequence():
	is_attacking = true
	on_cooldown = true
	velocity = Vector2.ZERO
	main_sprite.play("shockwave")

# 프레임 감지 함수
func _on_main_sprite_frame_changed():
	if main_sprite.animation == "shockwave" and main_sprite.frame == 4:
		fire_wave_effect()

# 파동 발사
func fire_wave_effect():
	wave_effect.visible = true
	wave_effect.frame = 0
	wave_effect.play("wave")
	shoot()
	
func shoot():
	if current_health <= 0: return
	var direction = (player.global_position - global_position).normalized()
	var bullet = BULLET_SCENE.instantiate()
	bullet.direction = direction
	bullet.global_position = global_position
	bullet.speed = current_bullet_speed
	get_parent().add_child(bullet)

func _on_wave_finished():
	wave_effect.visible = false
	wave_effect.stop()
	is_attacking = false
	main_sprite.play("idle")
	
	await get_tree().create_timer(attack_cooldown).timeout
	
	on_cooldown = false
