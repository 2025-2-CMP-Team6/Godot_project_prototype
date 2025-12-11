extends BaseSkill

#region 스킬 설정
@export_group("ThunderSlash Settings")
@export var slash_count: int = 3           # 연속 공격 횟수
@export var slash_interval: float = 0.3    # 공격 속
@export var search_radius: float = 400.0   # 다음 적 찾는 범위

@export_group("Movement Settings")
@export var teleport_distance: float = 60.0
@export var safety_margin: float = 16.0
@export var hitbox_width: float = 50.0
@export var slash_visual_texture: Texture

@export_group("Audio Settings")
@export var slash_sound: AudioStream # 효과음
#endregion

var is_slashing_sequence: bool = false

func _init():
	skill_name = "ThunderSlash"
	requires_target = true
	ends_on_condition = false
	gravity_multiplier = 0.0

# -----------------------------------------------------------
# 1. 실행 (Execute)
# -----------------------------------------------------------
func execute(owner: CharacterBody2D, target: Node2D = null):
	if is_slashing_sequence: return
	super.execute(owner, target)
	
	if not _is_valid_target(target):
		_on_skill_finished()
		return

	is_slashing_sequence = true
	var current_target = target
	
	for i in range(slash_count):
		# 타겟 생존 확인
		if not _is_valid_target(current_target):
			current_target = _find_nearest_enemy(owner)
			if current_target == null: break
		
		_play_sound()
		
		# 베기 실행
		_perform_slash(owner, current_target)
		
		# 대기 (0.3초)
		await get_tree().create_timer(slash_interval).timeout
	
	is_slashing_sequence = false
	_on_skill_finished()

# -----------------------------------------------------------
# 2. 베기 동작
# -----------------------------------------------------------
func _perform_slash(owner: CharacterBody2D, target: Node2D):
	if not _is_valid_target(target): return

	var start_pos = owner.global_position
	var end_pos = _calc_teleport_pos(owner, target)

	owner.global_position = end_pos
	
	# 방향 전환
	var look_dir = target.global_position.x - owner.global_position.x
	if look_dir > 0: owner.scale.x = abs(owner.scale.x)
	else: owner.scale.x = -abs(owner.scale.x)

	# 데미지 & 이펙트
	_apply_damage(start_pos, end_pos, owner)
	EffectManager.play_screen_shake(8.0, 0.1)
	EffectManager.play_multi_flash(Color(1, 1, 0.8), 0.05, 1)

# -----------------------------------------------------------
# 3. 유틸리티 함수들 (소리 재생 추가됨)
# -----------------------------------------------------------

# 소리 재생 함수 (일회용 스피커 생성)
func _play_sound():
	if slash_sound == null: return
	
	var asp = AudioStreamPlayer.new()
	asp.stream = slash_sound
	asp.volume_db = -5.0 # 소리 조절
	asp.pitch_scale = randf_range(0.9, 1.1) # 음높이 랜덤
	
	get_tree().current_scene.add_child(asp)
	asp.play()
	
	# 소리가 끝나면 스피커 삭제
	asp.finished.connect(asp.queue_free)

func _is_valid_target(target) -> bool:
	return target != null and is_instance_valid(target) and not target.is_queued_for_deletion()

func _find_nearest_enemy(owner: CharacterBody2D) -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest = null
	var min_dist = search_radius
	for enemy in enemies:
		if not _is_valid_target(enemy): continue
		var dist = owner.global_position.distance_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			closest = enemy
	return closest

func _calc_teleport_pos(owner: CharacterBody2D, target: Node2D) -> Vector2:
	var dir = (target.global_position - owner.global_position).normalized()
	if dir == Vector2.ZERO: dir = Vector2.RIGHT
	var ray_from = target.global_position
	var ray_to = ray_from + (dir * teleport_distance)
	var space = owner.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(ray_from, ray_to)
	query.exclude = [owner.get_rid(), target.get_rid()]
	var result = space.intersect_ray(query)
	if result: return result.position - (dir * safety_margin)
	return ray_to

func _apply_damage(start: Vector2, end: Vector2, owner: CharacterBody2D):
	var space = owner.get_world_2d().direct_space_state
	var shape = RectangleShape2D.new()
	shape.size = Vector2(hitbox_width, start.distance_to(end))
	var xform = Transform2D((end - start).angle() + PI/2, (start + end)/2)
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = xform
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [owner.get_rid()]
	_draw_debug(shape, xform, owner)

	var results = space.intersect_shape(query)
	var hit_list = []
	for res in results:
		var node = res.collider
		if node.is_in_group("enemies"): pass
		elif node is Area2D and node.get_parent().is_in_group("enemies"): node = node.get_parent()
		else: continue
		if node not in hit_list:
			if node.has_method("take_damage"): node.take_damage(damage)
			hit_list.append(node)

func _draw_debug(shape, xform, owner):
	if not slash_visual_texture: return
	var spr = Sprite2D.new()
	spr.texture = slash_visual_texture
	if spr.texture.get_width() > 0: spr.scale = shape.size / spr.texture.get_size()
	spr.global_transform = xform
	spr.modulate = Color(1, 1, 0.5, 0.8)
	owner.get_parent().add_child(spr)
	get_tree().create_timer(0.15).timeout.connect(spr.queue_free)

func _on_skill_finished():
	is_active = false
