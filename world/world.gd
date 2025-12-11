# world.gd
class_name World extends Node2D

@export var is_test_mode: bool = false

# 씬에 배치한 노드들을 가져옵니다.
@export var player: CharacterBody2D
@export var skill_get_ui: SkillGetUI
@export var skill_ui: SkillUI

# 인스펙터에서 스테이지별 음악을 넣을 수 있는 변수
@export_category("Stage Settings")
@export var stage_bgm: AudioStream # 여기에 mp3 파일을 넣기
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
	
	# 체크박스가 켜진 경우에만 테스트 스킬 지급
	if is_test_mode:
		var all_skills = InventoryManager.skill_database
		
		print("--- [테스트 모드 ON] 스킬 지급 시작 ---")
		for skill_path in all_skills:
			InventoryManager.add_skill_to_inventory(skill_path)

	# 오디오 설정 및 재생
	_setup_stage_music()
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() > 0:
		for enemy in enemies:
			if not enemy.enemy_died.is_connected(_on_enemy_died):
				enemy.enemy_died.connect(_on_enemy_died)
	else:
		print("주의: 맵에 'enemies' 그룹인 적이 하나도 없습니다.")
	if is_instance_valid(skill_get_ui):
		skill_get_ui.closed.connect(_on_skill_get_ui_closed)

func _on_enemy_died():
	var remaining_enemies = get_tree().get_nodes_in_group("enemies")
	if remaining_enemies.size() <= 1:
		print("모든 적 처치 완료! 보상 선택 창 오픈")
		skill_get_ui.open_reward_screen()
	else:
		print("적이 사망했습니다. 남은 적: " + str(remaining_enemies.size() - 1))

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

# 카메라 인트로 효과: 맵 전체를 보여주고 플레이어로 줌인
# 모든 스테이지에서 재사용 가능
func camera_intro_effect(
	initial_zoom: Vector2 = Vector2(0.272, 0.3),
	show_duration: float = 3.0,
	zoom_duration: float = 2.0,
	enable_parallax_transition: bool = true
):
	# 플레이어 노드 찾기
	var stage_player = player if player != null else get_node_or_null("Player")
	if stage_player == null:
		print("경고: Player 노드를 찾을 수 없습니다.")
		return

	# 플레이어의 카메라 찾기
	var camera = stage_player.get_node_or_null("Camera2D")
	if camera == null:
		print("경고: Player의 Camera2D를 찾을 수 없습니다.")
		return

	# Background 노드 찾기
	var background = get_node_or_null("Background")
	var parallax_nodes = []
	var original_scroll_scales = []

	# Parallax 효과가 활성화되어 있고 Background 노드가 있으면 처리
	if enable_parallax_transition and background != null:
		for child in background.get_children():
			if child is Parallax2D:
				parallax_nodes.append(child)
				original_scroll_scales.append(child.scroll_scale)
				child.scroll_scale = Vector2(1.0, 1.0)

	# 초기 줌 아웃 설정 (맵 전체를 보여주기 위해)
	var target_zoom = Vector2(1.0, 1.0)  # 플레이어 중심 일반 줌
	camera.zoom = initial_zoom

	# 맵 전체를 잠시 보여주기 위해 대기
	await get_tree().create_timer(show_duration).timeout

	# 플레이어 중심으로 줌 인 애니메이션
	var zoom_tween = create_tween()
	zoom_tween.set_ease(Tween.EASE_IN_OUT)
	zoom_tween.set_trans(Tween.TRANS_CUBIC)
	zoom_tween.tween_property(camera, "zoom", target_zoom, zoom_duration)

	# Parallax2D 노드들의 scroll_scale을 부드럽게 복원 (줌과 동시에)
	if enable_parallax_transition and parallax_nodes.size() > 0:
		var parallax_tween = create_tween()
		parallax_tween.set_ease(Tween.EASE_IN_OUT)
		parallax_tween.set_trans(Tween.TRANS_CUBIC)
		parallax_tween.set_parallel(true)  # 모든 트윈을 동시에 실행

		for i in range(parallax_nodes.size()):
			parallax_tween.tween_property(parallax_nodes[i], "scroll_scale", original_scroll_scales[i], zoom_duration)

	# 애니메이션 완료까지 대기
	await zoom_tween.finished
