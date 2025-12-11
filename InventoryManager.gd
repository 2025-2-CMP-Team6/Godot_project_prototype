# res://InventoryManager.gd
extends Node

#region 변수
const SKILL_DIRECTORY = "res://SkillDatas/"

var skill_database: Array[String] = []

var player_inventory: Array[SkillInstance] = []

var equipped_skills: Dictionary = {
	1: null, # SkillInstance
	2: null, # SkillInstance
	3: null # SkillInstance
}
#endregion

#region 초기화 및 스킬 DB
func _ready():
	load_skills_from_directory(SKILL_DIRECTORY)
	
	add_skill_to_inventory("res://SkillDatas/Skill_Melee/Skill_Melee.tscn")
	add_skill_to_inventory("res://SkillDatas/Skill_Melee/Skill_Melee.tscn")
	add_skill_to_inventory("res://SkillDatas/Skill_Melee/Skill_Melee.tscn")
	add_skill_to_inventory("res://SkillDatas/Skill_Melee/Skill_Melee.tscn")
	add_skill_to_inventory("res://SkillDatas/Skill_PiercingShot/Skill_PiercingShot.tscn")
	add_skill_to_inventory("res://SkillDatas/Skill_IceBall/Skill_IceBall.tscn")
	add_skill_to_inventory("res://SkillDatas/Skill_FireBall/Skill_FireBall.tscn")
	add_skill_to_inventory("res://SkillDatas/Skill_BlinkSlash/Skill_BlinkSlash.tscn")
	add_skill_to_inventory("res://SkillDatas/Skill_Parry/Skill_Parry.tscn")

func load_skills_from_directory(path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name == "." or file_name == ".." or file_name.ends_with(".tmp"):
				file_name = dir.get_next()
				continue
			
			var full_path = path.path_join(file_name)
			if dir.current_is_dir():
				load_skills_from_directory(full_path)
			elif file_name.ends_with(".tscn"):
				var scene = load(full_path) as PackedScene
				if scene:
					var instance = scene.instantiate()
					if instance is BaseSkill:
						skill_database.append(full_path)
					instance.queue_free() # 메모리 누수 방지
			
			file_name = dir.get_next()
#endregion

#region 스킬 정보 조회
# 모든 스킬 종류의 개수 반환
func get_skill_type_count() -> int:
	return skill_database.size()

# 랜덤 스킬 경로 반환
func get_random_skill_path() -> String:
	if skill_database.is_empty():
		printerr("Skill database is empty. Cannot get a random skill.")
		return ""
	var random_index = randi() % skill_database.size()
	return skill_database[random_index]
#endregion

#region 인벤토리 관리
# 스킬 추가
func add_skill_to_inventory(skill_data):
	var instance_to_add: SkillInstance
	
	if skill_data is String:
		instance_to_add = SkillInstance.new()
		instance_to_add.skill_path = skill_data
		instance_to_add.level = 0
		instance_to_add.bonus_points = 0.0
	elif skill_data is SkillInstance:
		instance_to_add = skill_data
	else:
		print("InventoryManager 오류: add_skill_to_inventory에 잘못된 타입이 들어옴")
		return

	player_inventory.append(instance_to_add)
# 스킬 제거
func remove_skill_from_inventory(instance_to_remove: SkillInstance) -> bool:
	var index = player_inventory.find(instance_to_remove)
	if index != -1:
		player_inventory.pop_at(index)
		return true
	
	return false
# 스킬 팝
func pop_skill_by_path(skill_path: String) -> SkillInstance:
	for i in range(player_inventory.size()):
		if player_inventory[i].skill_path == skill_path:
			var instance = player_inventory.pop_at(i)
			return instance
	return null
#endregion

#region 스킬 강화
# 강화 시도
func attempt_upgrade(base_skill: SkillInstance, material_skill: SkillInstance) -> bool:
	if not (is_instance_valid(base_skill) and is_instance_valid(material_skill)):
		print("강화 오류: 슬롯이 비어있습니다.")
		return false

	if base_skill.skill_path != material_skill.skill_path:
		print("강화 오류: 같은 종류의 스킬이 아닙니다.")
		return false
		
	var base_chance = [0.6, 0.5, 0.4, 0.3, 0.2]
	var current_level = base_skill.level
	var chance = 0.0
	if current_level < base_chance.size():
		chance = base_chance[current_level]
	else:
		chance = 0.1 # 최대 레벨 이후
		
	var success_chance = chance + (base_skill.bonus_points * 0.01)
	
	if randf() < success_chance:
		# 성공
		base_skill.level += 1
		base_skill.bonus_points = 0.0 # 보너스 초기화
		print("강화 성공! " + base_skill.skill_path + " (Lv. " + str(base_skill.level) + ")")
		return true
	else:
		# 실패
		base_skill.bonus_points += 10.0 # 보너스
		print("강화 실패... " + base_skill.skill_path + " (보너스: " + str(base_skill.bonus_points) + "%)")
		return false
#endregion
