# player.gd
extends CharacterBody2D

const BaseSkill = preload("res://SkillDatas/BaseSkill.gd")

#region 플레이어 속성 (Player Attributes)
@export var max_speed: float = 400.0
@export var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var jump_velocity: float = -600.0
@export var dash_speed: float = 1200.0
@export var dash_duration: float = 0.05
@export var dash_cooldown: float = 0.8
@export var max_lives: int = 3
@export var life_icon: Texture
@export var i_frames_duration: float = 1.0
@export var max_stamina: float = 100.0
@export var dash_cost: float = 35.0
@export var stamina_regen_rate: float = 20.0
#endregion

#region 상태 머신 (State Machine)
enum State {
	IDLE,
	MOVE,
	DASH,
	SKILL_CASTING
}
#endregion

#region 상태 관리 변수
var current_state = State.IDLE
var can_dash: bool = true
var dash_direction: Vector2 = Vector2.ZERO
var current_stamina: float = 0.0
var current_casting_skill: BaseSkill = null
var current_cast_target: Node2D = null
var is_invincible: bool = false
var current_lives: int = 0
var is_input_locked: bool = false
#endregion

#region 노드 참조 (Node Cache)
# --- 내부 노드 ---
@export var duration_timer: Timer
@export var cooldown_timer: Timer
@export var skill_cast_timer: Timer
@export var state_label: Label
@export var stamina_bar: ProgressBar
@export var visuals: Node2D
@export var lives_container: HBoxContainer
@export var i_frames_timer: Timer
@export var skill_1_slot: Node
@export var skill_2_slot: Node
@export var skill_3_slot: Node
@export var camera_node: Camera2D
@export var screen_flash_rect: ColorRect

# --- 외부 HUD 노드 ---
@export var skill_ui: SkillUI
@export var hud_skill_1_icon: Control
@export var hud_skill_2_icon: Control
@export var hud_skill_3_icon: Control
#endregion

#region 디버그용 시각화
var show_range: bool = true
func _draw():
	if show_range and skill_1_slot.get_child_count() > 0:
		var skill = skill_1_slot.get_child(0)
		if is_instance_valid(skill):
			if "max_cast_range" in skill and skill.max_cast_range > 0:
				draw_circle(Vector2(0, 0), skill.max_cast_range, Color(1, 0, 0, 0.3))
#endregion

#region 초기화 (Initialization)
func _ready():
	await InventoryManager.ready
	
	if duration_timer: duration_timer.timeout.connect(_on_dash_duration_timeout)
	if cooldown_timer: cooldown_timer.timeout.connect(_on_dash_cooldown_timeout)
	if i_frames_timer: i_frames_timer.timeout.connect(_on_i_frames_timeout)
	if skill_cast_timer: skill_cast_timer.timeout.connect(_on_skill_cast_timeout)
	
	current_stamina = max_stamina
	if stamina_bar:
		stamina_bar.max_value = max_stamina
		stamina_bar.value = current_stamina

	current_lives = max_lives
	update_lives_ui()

	if is_instance_valid(hud_skill_1_icon):
		hud_skill_1_icon.setup_hud(skill_1_slot, "LMB")
	if is_instance_valid(hud_skill_2_icon):
		hud_skill_2_icon.setup_hud(skill_2_slot, "Q")
	if is_instance_valid(hud_skill_3_icon):
		hud_skill_3_icon.setup_hud(skill_3_slot, "E")

	var has_saved_skills = false
	for slot_index in InventoryManager.equipped_skill_paths:
		if InventoryManager.equipped_skill_paths[slot_index] != null:
			has_saved_skills = true
			break

	if has_saved_skills:
		var path1 = InventoryManager.equipped_skill_paths[1]
		if path1 != null: _load_skill_into_slot(path1, 1)
		var path2 = InventoryManager.equipped_skill_paths[2]
		if path2 != null: _load_skill_into_slot(path2, 2)
		var path3 = InventoryManager.equipped_skill_paths[3]
		if path3 != null: _load_skill_into_slot(path3, 3)
	else:
		var initial_skill_1_path = "res://SkillDatas/Skill_BlinkSlash/Skill_BlinkSlash.tscn"
		if InventoryManager.remove_skill_from_inventory(initial_skill_1_path):
			equip_skill(initial_skill_1_path, 1)
		var initial_skill_2_path = "res://SkillDatas/Skill_Melee/Skill_Melee.tscn"
		if InventoryManager.remove_skill_from_inventory(initial_skill_2_path):
			equip_skill(initial_skill_2_path, 2)
		var initial_skill_3_path = "res://SkillDatas/Skill_Parry/Skill_Parry.tscn"
		if InventoryManager.remove_skill_from_inventory(initial_skill_3_path):
			equip_skill(initial_skill_3_path, 3)

	if camera_node and screen_flash_rect:
		EffectManager.register_effects(camera_node, screen_flash_rect)
		
	change_state(State.IDLE)
#endregion

#region 물리 처리 (Physics Process)
func _physics_process(delta: float):
	var current_gravity_multiplier = 1.0
	if current_state == State.SKILL_CASTING and is_instance_valid(current_casting_skill):
		current_gravity_multiplier = current_casting_skill.gravity_multiplier
	
	if current_state != State.DASH and not is_on_floor():
		velocity.y += gravity * current_gravity_multiplier * delta

	if is_invincible:
		if visuals: visuals.visible = (int(Time.get_ticks_msec() / 100) % 2) == 0
	else:
		if visuals: visuals.visible = true

	if velocity.x > 0.1:
		if visuals: visuals.scale.x = 1
	elif velocity.x < -0.1:
		if visuals: visuals.scale.x = -1
		
	if state_label: state_label.text = State.keys()[current_state]

	match current_state:
		State.IDLE, State.MOVE:
			if not is_input_locked:
				regenerate_stamina(delta)

	match current_state:
		State.IDLE: state_logic_idle(delta)
		State.MOVE: state_logic_move(delta)
		State.DASH: state_logic_dash(delta)
		State.SKILL_CASTING: state_logic_skill_casting(delta)
	
	if stamina_bar: stamina_bar.value = current_stamina
	move_and_slide()
#endregion

#region 상태별 로직 (State Logic)
func regenerate_stamina(delta: float):
	current_stamina = clamp(current_stamina + stamina_regen_rate * delta, 0, max_stamina)

func state_logic_idle(_delta: float):
	velocity.x = 0
	handle_inputs()
	if is_input_locked: return
	if Input.get_axis("move_left", "move_right") != 0:
		change_state(State.MOVE)

func state_logic_move(_delta: float):
	handle_inputs()
	if is_input_locked:
		velocity.x = 0
		return
	var move_input = Input.get_axis("move_left", "move_right")
	velocity.x = move_input * max_speed
	if move_input == 0:
		change_state(State.IDLE)

func state_logic_dash(_delta: float):
	velocity = dash_direction * dash_speed

func state_logic_skill_casting(delta: float):
	if current_casting_skill != null:
		current_casting_skill.process_skill_physics(self, delta)
		if current_casting_skill.ends_on_condition:
			if not current_casting_skill.is_active:
				_on_skill_cast_timeout()
	else:
		change_state(State.IDLE)
#endregion

#region 입력 처리 (Input Handling)
func handle_inputs():
	if Input.is_action_just_pressed("ui_inventory"):
		if skill_ui:
			skill_ui.visible = not skill_ui.visible
			is_input_locked = skill_ui.visible
			if skill_ui.visible:
				skill_ui.refresh_ui(self)
		return

	if is_input_locked:
		return
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		
	if Input.is_action_just_pressed("skill_1"):
		var target = find_nearest_enemy()
		try_cast_skill(skill_1_slot, target)
	elif Input.is_action_just_pressed("skill_2"):
		try_cast_skill(skill_2_slot, null)
	elif Input.is_action_just_pressed("skill_3"):
		try_cast_skill(skill_3_slot)
	elif Input.is_action_just_pressed("dash") and can_dash:
		if current_stamina >= dash_cost:
			change_state(State.DASH)
		else:
			pass
#endregion

#region 스킬 관련 기능 (Skill Functions)
func find_nearest_enemy() -> Node2D:
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	var nearest_enemy: Node2D = null
	var min_distance = INF
	for enemy in all_enemies:
		if enemy is CharacterBody2D:
			var distance = global_position.distance_to(enemy.global_position)
			if distance < min_distance:
				min_distance = distance
				nearest_enemy = enemy
	return nearest_enemy

func try_cast_skill(slot_node: Node, target: Node2D = null):
	if not is_instance_valid(slot_node): return
	if slot_node.get_child_count() == 0:
		print("슬롯이 비어있음")
		return
	var skill: BaseSkill = slot_node.get_child(0)
	if skill == null: return
	if skill.requires_target and target == null:
		print(skill.skill_name + "은(는) 적을 클릭해야 합니다.")
		return
	if skill.requires_target and skill.max_cast_range > 0:
		var distance = global_position.distance_to(target.global_position)
		if distance > skill.max_cast_range:
			print(skill.skill_name + "의 사거리가 닿지 않습니다!")
			return
		print(str(distance) + "거리")
		print(str(skill.max_cast_range) + "사거리")
	if not skill.is_ready():
		var time_left = skill.get_cooldown_time_left()
		print(skill.skill_name + " 스킬 준비 안 됨 (쿨타임). 남은 시간: " + str(time_left) + "초")
		return
	if current_stamina < skill.stamina_cost:
		print(skill.skill_name + " 스킬 준비 안 됨 (스태미나 부족! 현재: " + str(current_stamina) + " / 필요: " + str(skill.stamina_cost) + ")")
		return
	current_casting_skill = skill
	current_cast_target = target
	change_state(State.SKILL_CASTING)

func _load_skill_into_slot(skill_scene_path: String, slot_number: int):
	var slot_node: Node = null
	match slot_number:
		1: slot_node = skill_1_slot
		2: slot_node = skill_2_slot
		3: slot_node = skill_3_slot
	if not is_instance_valid(slot_node): return
	if slot_node.get_child_count() > 0:
		for child in slot_node.get_children():
			child.queue_free()
	var skill_scene = load(skill_scene_path)
	if skill_scene == null: return
	var new_skill_instance = skill_scene.instantiate()
	if new_skill_instance is BaseSkill:
		if new_skill_instance.type == slot_number:
			slot_node.add_child(new_skill_instance)
		else:
			print("부활 오류: 스킬 타입 불일치! " + skill_scene_path)
			new_skill_instance.queue_free()
	else:
		new_skill_instance.queue_free()

func equip_skill(skill_scene_path: String, slot_number: int):
	var slot_node: Node = null
	match slot_number:
		1: slot_node = skill_1_slot
		2: slot_node = skill_2_slot
		3: slot_node = skill_3_slot
	if not is_instance_valid(slot_node): return
	var old_skill_path = InventoryManager.equipped_skill_paths[slot_number]
	if old_skill_path != null:
		InventoryManager.add_skill_to_inventory(old_skill_path)
	if slot_node.get_child_count() > 0:
		for child in slot_node.get_children():
			child.queue_free()
	var skill_scene = load(skill_scene_path)
	if skill_scene == null: return
	var new_skill_instance = skill_scene.instantiate()
	if new_skill_instance is BaseSkill:
		if new_skill_instance.type == slot_number:
			print(new_skill_instance.skill_name + "을(를) " + str(slot_number) + "번 슬롯에 장착!")
			slot_node.add_child(new_skill_instance)
			InventoryManager.equipped_skill_paths[slot_number] = skill_scene_path
		else:
			print("타입 불일치")
			new_skill_instance.queue_free()
			InventoryManager.add_skill_to_inventory(skill_scene_path)
			return
	else:
		new_skill_instance.queue_free()

func unequip_skill(slot_number: int):
	var slot_node: Node = null
	match slot_number:
		1: slot_node = skill_1_slot
		2: slot_node = skill_2_slot
		3: slot_node = skill_3_slot
	if not is_instance_valid(slot_node): return
	if slot_node.get_child_count() > 0:
		print(str(slot_number) + "번 슬롯 장착 해제")
		for child in slot_node.get_children():
			child.queue_free()
		var unequipped_path = InventoryManager.equipped_skill_paths[slot_number]
		if unequipped_path != null:
			InventoryManager.equipped_skill_paths[slot_number] = null
			InventoryManager.add_skill_to_inventory(unequipped_path)
#endregion

#region 상태 변경 로직 (State Change)
func change_state(new_state: State):
	if current_state == new_state:
		return
	current_state = new_state
	match new_state:
		State.IDLE: pass
		State.MOVE: pass
		State.DASH:
			current_stamina -= dash_cost
			if visuals: dash_direction = Vector2(visuals.scale.x, 0).normalized()
			if dash_direction == Vector2.ZERO:
				dash_direction = Vector2.RIGHT
			can_dash = false
			if duration_timer:
				duration_timer.wait_time = dash_duration
				duration_timer.start()
		State.SKILL_CASTING:
			if current_casting_skill == null: return
			current_casting_skill.execute(self, current_cast_target)
			current_stamina -= current_casting_skill.stamina_cost
			current_casting_skill.start_cooldown()
			if not current_casting_skill.ends_on_condition:
				if skill_cast_timer:
					skill_cast_timer.wait_time = current_casting_skill.cast_duration
					skill_cast_timer.start()
#endregion

#region 타이머 콜백 (Timer Callbacks)
func _on_dash_duration_timeout():
	velocity = Vector2.ZERO
	change_state(State.IDLE)
	if cooldown_timer:
		cooldown_timer.wait_time = dash_cooldown
		cooldown_timer.start()

func _on_dash_cooldown_timeout():
	can_dash = true

func _on_skill_cast_timeout():
	change_state(State.IDLE)
	current_casting_skill = null
	current_cast_target = null
#endregion

#region 피격 및 생명 관리
func update_lives_ui():
	if not is_instance_valid(lives_container): return
	for child in lives_container.get_children():
		child.queue_free()
	if life_icon:
		for i in range(current_lives):
			var icon = TextureRect.new()
			icon.texture = life_icon
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(32, 32)
			lives_container.add_child(icon)

func lose_life():
	if is_invincible or current_state == State.DASH or current_lives <= 0:
		return
	current_lives -= 1
	print("생명 1 잃음! 남은 생명: ", current_lives)
	update_lives_ui()
	if current_lives <= 0:
		die()
	else:
		is_invincible = true
		if i_frames_timer:
			i_frames_timer.wait_time = i_frames_duration
			i_frames_timer.start()

func die():
	print("플레이어가 사망했습니다.")
	is_invincible = false
	if visuals: visuals.visible = true
	get_tree().reload_current_scene()
	
func _on_i_frames_timeout():
	is_invincible = false
	if visuals: visuals.visible = true
#endregion
