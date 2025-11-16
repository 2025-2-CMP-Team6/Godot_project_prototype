# res://SkillInstance.gd
extends Resource
class_name SkillInstance

# 이 스킬의 원본 .tscn 파일 경로
@export var skill_path: String

# 현재 스킬 레벨
@export var level: int = 0

# 현재 쌓인 강화 보너스 확률 (예: 10.0 = 10%)
@export var bonus_points: float = 0.0
