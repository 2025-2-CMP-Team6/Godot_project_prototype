# world.gd
class_name World extends Node2D

# 씬에 배치한 노드들을 가져옵니다.
@export var player: CharacterBody2D
@export var enemy: CharacterBody2D
@export var skill_get_ui: SkillGetUI
@export var skill_ui: SkillUI

# 인스펙터에서 스테이지별 음악을 넣을 수 있는 변수
@export_category("Stage Settings")
@export var stage_bgm: AudioStream  # 여기에 mp3 파일을 넣기
@export var bgm_volume_db: float = -10.0 # 기본 볼륨 설정

# 오디오 매니저 변수
var _audio_manager: AudioManager 
var _bgm_key: String = "StageBGM"

# 음악 세팅 함수
func _setup_stage_music():
	if stage_bgm == null:
		return 

	# AudioManager 생성 및 씬에 추가
	_audio_manager = AudioManager.new()
	add_child(_audio_manager) 

	# AudioManagerPlus (배경음악용) 설정
	var bgm_plus = AudioManagerPlus.new()
	bgm_plus.stream = stage_bgm
	bgm_plus.loop = true # 반복 설정
	bgm_plus.volume_db = bgm_volume_db
	bgm_plus.audio_name = _bgm_key # 나중에 멈추거나 제어하기 위한 이름

	# 매니저에 등록, 재생
	_audio_manager.add_plus(_bgm_key, bgm_plus)
	_audio_manager.play_plus(_bgm_key)

func _ready():
	# 오디오 설정 및 재생
	_setup_stage_music()
	
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
	if !GameManager.is_cheat:
		return
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
