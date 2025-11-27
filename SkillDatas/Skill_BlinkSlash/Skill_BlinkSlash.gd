# skills/blink_slash/Skill_BlinkSlash.gd
extends BaseSkill

#region 스킬 고유 속성
@export var teleport_distance: float = 60.0
@export var safety_margin: float = 16.0
@export var hitbox_width: float = 50.0
@export var slash_visual_texture: Texture
#endregion

var slide_direction: Vector2 = Vector2.ZERO

# -----------------------------------------------------------------
# ★ (새로 추가) _init 함수
# -----------------------------------------------------------------
func _init():
	# 1. 이 스킬은 타겟이 필수입니다.
	requires_target = true
	
	# 2. 이 스킬은 '시간제'로 종료됩니다. (미끄러짐 삭제)
	ends_on_condition = false
	
	# 3. (오류 수정) 중력 배율을 1.0 (100%)로 설정합니다.
	gravity_multiplier = 1.0
# -----------------------------------------------------------------

#region 스킬 로직
func execute(owner: CharacterBody2D, target: Node2D = null):
	super.execute(owner, target)
	
	if target == null:
		is_active = false
		return
	if not target.has_method("get_rid"):
		is_active = false
		return
	
	var start_pos = owner.global_position
	slide_direction = (target.global_position - start_pos).normalized()
	if slide_direction == Vector2.ZERO:
		slide_direction = Vector2.RIGHT
	
	var ray_from = target.global_position
	var ray_to = ray_from + (slide_direction * teleport_distance)
	var space_state = owner.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(ray_from, ray_to)
	query.exclude = [owner.get_rid(), target.get_rid()]
	var result = space_state.intersect_ray(query)
	
	var target_position: Vector2
	if result:
		target_position = result.position - (slide_direction * safety_margin)
	else:
		target_position = ray_to

	owner.global_position = target_position
	
	apply_slash_damage(start_pos, target_position, owner)
# Skill_BlinkSlash.gd

func apply_slash_damage(start_pos: Vector2, end_pos: Vector2, owner: CharacterBody2D):
	var length = start_pos.distance_to(end_pos)
	var space_state = owner.get_world_2d().direct_space_state
	var shape = RectangleShape2D.new()
	shape.size = Vector2(hitbox_width, length)
	
	var angle = (end_pos - start_pos).angle() + deg_to_rad(90)
	var center_pos = (start_pos + end_pos) / 2
	var xform = Transform2D(angle, center_pos)

	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = xform
	
	# ★ 수정 1: Area2D(히트박스)도 감지하도록 변경
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	query.exclude = [owner.get_rid()] # 플레이어 자신은 제외
	
	_debug_draw_hitbox(shape, xform, owner)

	var results = space_state.intersect_shape(query)
	
	var did_hit_enemy = false
	var hit_enemies = [] # 중복 타격 방지용 목록
	
	for res in results:
		var collider = res.collider
		var enemy_node = null
		
		# ★ 수정 2: 부딪힌 게 적 본체인지, 적의 히트박스인지 확인
		if collider.is_in_group("enemies"):
			# 적 본체(Body)와 충돌한 경우
			enemy_node = collider
			
		elif collider is Area2D and collider.get_parent().is_in_group("enemies"):
			# 적의 히트박스(Area)와 충돌한 경우 -> 부모를 적 본체로 설정
			enemy_node = collider.get_parent()
			
		# ★ 수정 3: 적을 찾았고, 아직 때리지 않았다면 데미지 적용
		if enemy_node != null and not enemy_node in hit_enemies:
			if enemy_node.has_method("take_damage"):
				enemy_node.take_damage(damage)
				print("벽력일섬 히트: " + enemy_node.name)
				hit_enemies.append(enemy_node) # 타격 목록에 추가
				did_hit_enemy = true

	# 이펙트
	if did_hit_enemy:
		EffectManager.play_screen_shake(12.0, 0.15)
		EffectManager.play_multi_flash(Color.WHITE, 0.05, 3)
		
# 히트박스 시각화
func _debug_draw_hitbox(shape: Shape2D, xform: Transform2D, owner: Node):
	var debug_sprite = Sprite2D.new()
	
	if slash_visual_texture:
		debug_sprite.texture = slash_visual_texture
	else:
		return

	if debug_sprite.texture.get_width() > 0:
		debug_sprite.scale.x = shape.size.x / debug_sprite.texture.get_width()
		debug_sprite.scale.y = shape.size.y / debug_sprite.texture.get_height()

	debug_sprite.modulate = Color(1, 1, 1, 0.5)
	debug_sprite.global_transform = xform
	
	owner.get_parent().add_child(debug_sprite)
	
	var timer = get_tree().create_timer(0.5)
	timer.timeout.connect(debug_sprite.queue_free)
#endregion
