# res://InventoryManager.gd
extends Node

#region 변수
const SKILL_DIRECTORY = "res://SkillDatas/"

var skill_database: Array[String] = []

# ★ (수정) 인벤토리가 String 배열이 아닌, SkillInstance 배열을 저장합니다.
var player_inventory: Array[SkillInstance] = []

# ★ (수정) 장착된 스킬의 '경로'가 아닌 'SkillInstance' 자체를 저장합니다.
var equipped_skills: Dictionary = {
	1: null, # SkillInstance
	2: null, # SkillInstance
	3: null # SkillInstance
}
#endregion

#region 초기화 및 스킬 DB
func _ready():
	load_skills_from_directory(SKILL_DIRECTORY)
	
	# ★ (수정) 테스트용 인벤토리 (SkillInstance로 추가)
	add_skill_to_inventory("res://SkillDatas/Skill_Melee/Skill_Melee.tscn")
	add_skill_to_inventory("res://SkillDatas/Skill_Melee/Skill_Melee.tscn")
	add_skill_to_inventory("res://SkillDatas/Skill_BlinkSlash/Skill_BlinkSlash.tscn")
	add_skill_to_inventory("res://SkillDatas/Skill_Parry/Skill_Parry.tscn")

func load_skills_from_directory(path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name == "." or file_name == "..":
				file_name = dir.get_next()
				continue
			if dir.current_is_dir():
				load_skills_from_directory(path + file_name + "/")
			else:
				if file_name.ends_with(".tscn"):
					skill_database.append(path + file_name)
			file_name = dir.get_next()
#endregion

#region 인벤토리 관리
# (수정) 'String' 경로 또는 'SkillInstance'를 받아 인벤토리에 추가합니다.
func add_skill_to_inventory(skill_data):
	var instance_to_add: SkillInstance
	
	if skill_data is String:
		# String 경로로 받으면 -> 새 SkillInstance 생성
		instance_to_add = SkillInstance.new()
		instance_to_add.skill_path = skill_data
		instance_to_add.level = 0
		instance_to_add.bonus_points = 0.0
	elif skill_data is SkillInstance:
		# SkillInstance 객체로 받으면 -> 그대로 사용
		instance_to_add = skill_data
	else:
		print("InventoryManager 오류: add_skill_to_inventory에 잘못된 타입이 들어옴")
		return

	player_inventory.append(instance_to_add)

# ★ (수정) 'String'이 아닌 'SkillInstance' 객체를 받아 제거합니다.
func remove_skill_from_inventory(instance_to_remove: SkillInstance) -> bool:
	var index = player_inventory.find(instance_to_remove)
	if index != -1: # 인스턴스를 찾았다면
		player_inventory.pop_at(index)
		return true
	
	# 인스턴스가 인벤토리에 없는 경우 (이미 장착되었거나, 강화 슬롯에 있음)
	return false

# (새로 추가) _ready()에서 사용할, '경로'로 인스턴스를 찾아 제거하고 '반환'하는 함수
func pop_skill_by_path(skill_path: String) -> SkillInstance:
	for i in range(player_inventory.size()):
		if player_inventory[i].skill_path == skill_path:
			var instance = player_inventory.pop_at(i)
			return instance
	return null # 해당 경로의 스킬이 인벤토리에 없음
#endregion

#region 스킬 강화
# (새로 추가) 강화 로직
func attempt_upgrade(base_skill: SkillInstance, material_skill: SkillInstance) -> bool:
	# 1. 재료가 유효한지 확인
	if not (is_instance_valid(base_skill) and is_instance_valid(material_skill)):
		print("강화 오류: 슬롯이 비어있습니다.")
		return false

	# 2. '같은' 스킬인지 확인 (경로 비교)
	if base_skill.skill_path != material_skill.skill_path:
		print("강화 오류: 같은 종류의 스킬이 아닙니다.")
		return false
		
	# 3. 재료 스킬을 인벤토리에서 제거 (이미 인벤토리에서 빠져나와 UI에 있음)
	#    (이 함수는 SkillUI가 재료를 인벤토리에서 빼서 호출하므로,
	#     여기서는 재료 스킬을 '소멸'시키기만 하면 됨)
	#    (material_skill은 SkillUI에 의해 관리되므로 여기선 소멸시킬 필요 없음)
	
	# 4. 강화 확률 계산 (예시: 레벨 0->1 60%, 1->2 50%...)
	var base_chance = [0.6, 0.5, 0.4, 0.3, 0.2] # 레벨별 기본 성공 확률
	var current_level = base_skill.level
	var chance = 0.0
	if current_level < base_chance.size():
		chance = base_chance[current_level]
	else:
		chance = 0.1 # 최대 레벨 이후
		
	var success_chance = chance + (base_skill.bonus_points * 0.01) # 보너스 1 = 1%
	
	# 5. 성공/실패 판정
	if randf() < success_chance:
		# 성공!
		base_skill.level += 1
		base_skill.bonus_points = 0.0 # 보너스 초기화
		print("강화 성공! " + base_skill.skill_path + " (Lv. " + str(base_skill.level) + ")")
		return true
	else:
		# 실패!
		base_skill.bonus_points += 10.0 # 10% 보너스
		print("강화 실패... " + base_skill.skill_path + " (보너스: " + str(base_skill.bonus_points) + "%)")
		return false
#endregion