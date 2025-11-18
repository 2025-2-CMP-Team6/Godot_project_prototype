# world.gd
extends Node2D

# 씬에 배치한 노드들을 가져옵니다.
@export var player: CharacterBody2D
@export var enemy: CharacterBody2D
@export var skill_get_ui: SkillGetUI
@export var skill_ui: SkillUI

func _ready():
	if is_instance_valid(enemy):
		enemy.enemy_died.connect(_on_enemy_died)
	if is_instance_valid(skill_get_ui):
		skill_get_ui.closed.connect(_on_skill_get_ui_closed)

func _on_enemy_died():
	if is_instance_valid(skill_get_ui):
		skill_get_ui.open_reward_screen()
		if is_instance_valid(player):
			player.set_input_locked(true)

func _on_skill_get_ui_closed():
	if is_instance_valid(player) and (not is_instance_valid(skill_ui) or not skill_ui.visible):
		player.set_input_locked(false)

func _unhandled_input(event):
	# 보상 테스트
	if event.is_action_pressed("get_skill_test"):
		if is_instance_valid(skill_get_ui):
			skill_get_ui.open_reward_screen()
			if is_instance_valid(player):
				player.set_input_locked(true)
		return
		
	# 스킬창 테스트
	if Input.is_action_just_pressed("ui_inventory"):
		if is_instance_valid(skill_ui):
			skill_ui.visible = not skill_ui.visible
			if is_instance_valid(player):
				player.set_input_locked(skill_ui.visible)
			if skill_ui.visible:
				skill_ui.refresh_ui(player)
		return
