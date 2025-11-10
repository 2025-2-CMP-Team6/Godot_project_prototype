# res://InventoryManager.gd
extends Node

#region 변수
const SKILL_DIRECTORY = "res://SkillDatas/"

var skill_database: Array[String] = []
var player_inventory: Array[String] = []

var equipped_skill_paths: Dictionary = {
	1: null,
	2: null,
	3: null
}
#endregion

#region 초기화 및 스킬 DB
func _ready():
	load_skills_from_directory(SKILL_DIRECTORY)
	
	# 테스트용 인벤토리
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
func add_skill_to_inventory(skill_path: String):
	player_inventory.append(skill_path)

func remove_skill_from_inventory(skill_path: String) -> bool:
	var index = player_inventory.find(skill_path)
	if index != -1:
		player_inventory.pop_at(index)
		return true
	
	return false
#endregion