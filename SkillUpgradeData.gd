# res://SkillUpgradeData.gd
extends Resource
class_name SkillUpgradeData

# 1. 변경할 스탯의 '변수 이름' (예: "damage", "cooldown")
@export var stat_name: StringName

# 2. 레벨별로 적용될 값의 배열 (0레벨, 1레벨, 2레벨...)
@export var stat_values_by_level: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
