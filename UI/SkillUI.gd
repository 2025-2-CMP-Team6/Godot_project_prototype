# SkillUI.gd
extends CanvasLayer
class_name SkillUI

const SkillCard = preload("res://UI/SkillCard.gd")

#region 노드 참조
@export var inventory_grid: GridContainer
@export var equipped_slot_1: Control
@export var equipped_slot_2: Control
@export var equipped_slot_3: Control
@export var inventory_drop_area: ScrollContainer
@export var tab_container: TabContainer

# ★ (새로 추가) 강화 탭 UI 요소 (인스펙터에서 할당 필요!)
@export var upgrade_base_slot: Control # '강화할 스킬' 슬롯 (EquipSlot.gd 재활용)
@export var upgrade_material_slot: Control # '재료 스킬' 슬롯 (EquipSlot.gd 재활용)
@export var upgrade_button: Button
@export var upgrade_info_label: Label
#endregion

var player_node_ref: CharacterBody2D

# (추가) 강화 탭에 올려진 스킬 인스턴스
var current_upgrade_base: SkillInstance = null
var current_upgrade_material: SkillInstance = null

func _ready():
	if is_instance_valid(tab_container):
		tab_container.add_theme_font_size_override("font_size", 24)

	# --- 시그널 연결 ---
	if is_instance_valid(equipped_slot_1) and equipped_slot_1.has_signal("skill_dropped_on_slot"):
		equipped_slot_1.skill_dropped_on_slot.connect(_on_skill_dropped)
	if is_instance_valid(equipped_slot_2) and equipped_slot_2.has_signal("skill_dropped_on_slot"):
		equipped_slot_2.skill_dropped_on_slot.connect(_on_skill_dropped)
	if is_instance_valid(equipped_slot_3) and equipped_slot_3.has_signal("skill_dropped_on_slot"):
		equipped_slot_3.skill_dropped_on_slot.connect(_on_skill_dropped)
		
	if is_instance_valid(inventory_drop_area):
		inventory_drop_area.skill_unequipped.connect(_on_skill_unequipped)
		
	# ★ (추가) 강화 탭 시그널 연결
	# (참고: 강화 슬롯은 'slot_index'가 0 (기본값)이므로, '타입' 검사 없이 아무 스킬이나 받음)
	if is_instance_valid(upgrade_base_slot) and upgrade_base_slot.has_signal("skill_dropped_on_slot"):
		upgrade_base_slot.skill_dropped_on_slot.connect(_on_upgrade_base_dropped)
	if is_instance_valid(upgrade_material_slot) and upgrade_material_slot.has_signal("skill_dropped_on_slot"):
		upgrade_material_slot.skill_dropped_on_slot.connect(_on_upgrade_material_dropped)
	if is_instance_valid(upgrade_button):
		upgrade_button.pressed.connect(_on_upgrade_button_pressed)

#region UI 관리
func refresh_ui(player_node: CharacterBody2D):
	self.player_node_ref = player_node
	
	# --- 1. 인벤토리 UI 새로고침 ---
	if is_instance_valid(inventory_grid):
		for child in inventory_grid.get_children():
			child.queue_free()
			
		var inventory_skills: Array[SkillInstance] = InventoryManager.player_inventory
		
		# (수정) 'SkillInstance'를 순회합니다.
		for skill_instance in inventory_skills:
			# (카드가 강화 슬롯에 올라가있지 않을 때만 인벤토리에 표시)
			if skill_instance != current_upgrade_base and skill_instance != current_upgrade_material:
				var card = SkillCard.new()
				card.custom_minimum_size = Vector2(160, 160)
				card.skill_instance = skill_instance
				card.setup_card_ui()
				inventory_grid.add_child(card)
	
	# --- 2. 장착 슬롯 UI 새로고침 ---
	if is_instance_valid(player_node):
		update_equip_slot_display(player_node.skill_1_slot, equipped_slot_1)
		update_equip_slot_display(player_node.skill_2_slot, equipped_slot_2)
		update_equip_slot_display(player_node.skill_3_slot, equipped_slot_3)
	
	# --- 3. 강화 탭 UI 새로고침 ---
	refresh_upgrade_tab()


func update_equip_slot_display(player_skill_slot: Node, ui_equip_slot: Control):
	if not is_instance_valid(ui_equip_slot): return
	if not ui_equip_slot.has_method("set_skill_display"): return

	if player_skill_slot.get_child_count() > 0:
		var skill = player_skill_slot.get_child(0) as BaseSkill
		if skill:
			# ★ (수정) 레벨 정보(skill.current_level)도 함께 전달
			ui_equip_slot.set_skill_display(skill.skill_icon, skill.skill_name, skill.skill_description, skill.current_level)
	else:
		ui_equip_slot.clear_skill_display()
		
func refresh_upgrade_tab():
	# (새로 추가) 강화 탭 UI를 현재 데이터에 맞게 새로고침
	if is_instance_valid(upgrade_base_slot):
		if is_instance_valid(current_upgrade_base):
			var t = load(current_upgrade_base.skill_path).instantiate()
			upgrade_base_slot.set_skill_display(t.skill_icon, t.skill_name, t.skill_description, current_upgrade_base.level)
			t.queue_free()
		else:
			upgrade_base_slot.clear_skill_display()
			
	if is_instance_valid(upgrade_material_slot):
		if is_instance_valid(current_upgrade_material):
			var t = load(current_upgrade_material.skill_path).instantiate()
			upgrade_material_slot.set_skill_display(t.skill_icon, t.skill_name, t.skill_description, current_upgrade_material.level)
			t.queue_free()
		else:
			upgrade_material_slot.clear_skill_display()
			
	if is_instance_valid(upgrade_info_label):
		if is_instance_valid(current_upgrade_base):
			upgrade_info_label.text = "현재 보너스: " + str(current_upgrade_base.bonus_points) + "%"
		else:
			upgrade_info_label.text = "강화할 스킬을 올려주세요."
#endregion

#region 시그널 콜백
# ★ (수정) 'skill_path' 대신 'SkillInstance'를 받음
func _on_skill_dropped(skill_instance: SkillInstance, slot_index: int):
	print(str(slot_index) + "번 슬롯에 " + skill_instance.skill_path + " 장착 시도!")
	
	if player_node_ref:
		# ★ (수정) 'SkillInstance'를 전달
		if InventoryManager.remove_skill_from_inventory(skill_instance):
			player_node_ref.equip_skill(skill_instance, slot_index)
			get_tree().create_timer(0.01).timeout.connect(refresh_ui.bind(player_node_ref))
		else:
			print("UI 오류: 인벤토리에 없는 스킬을 장착 시도함")

func _on_skill_unequipped(slot_index: int):
	if player_node_ref:
		player_node_ref.unequip_skill(slot_index)
		get_tree().create_timer(0.01).timeout.connect(refresh_ui.bind(player_node_ref))

# -----------------------------------------------------------------
# ★ (새로 추가) 강화 탭 시그널
# -----------------------------------------------------------------
func _on_upgrade_base_dropped(skill_instance: SkillInstance, slot_index: int):
	# (slot_index는 사용 안 함)
	# 재료 슬롯에 있던 스킬은 인벤토리로 되돌림
	if is_instance_valid(current_upgrade_base):
		InventoryManager.add_skill_to_inventory(current_upgrade_base)
		
	# 인벤토리에서 제거하고 새 스킬로 설정 (SkillCard에서 이미 제거됨)
	current_upgrade_base = skill_instance
	
	get_tree().create_timer(0.01).timeout.connect(refresh_ui.bind(player_node_ref))

func _on_upgrade_material_dropped(skill_instance: SkillInstance, slot_index: int):
	# (slot_index는 사용 안 함)
	if is_instance_valid(current_upgrade_material):
		InventoryManager.add_skill_to_inventory(current_upgrade_material)
		
	current_upgrade_material = skill_instance
	
	get_tree().create_timer(0.01).timeout.connect(refresh_ui.bind(player_node_ref))

func _on_upgrade_button_pressed():
	# InventoryManager에 강화 시도
	var success = InventoryManager.attempt_upgrade(current_upgrade_base, current_upgrade_material)
	
	if success:
		# 성공 시, 재료 슬롯만 비움
		current_upgrade_material = null
	else:
		# 실패 시, 재료 슬롯만 비움
		current_upgrade_material = null
		
	# (공통) UI 새로고침
	get_tree().create_timer(0.01).timeout.connect(refresh_ui.bind(player_node_ref))
#endregion
