# world.gd
class_name World extends Node2D

#test mode 활성화 시 모든 스킬 인벤토리에 존재
@export var is_test_mode: bool = false

# 씬에 배치한 노드들을 가져옵니다.
@export var player: CharacterBody2D
@export var skill_get_ui: SkillGetUI
@export var skill_ui: SkillUI

# 포탈 활성화 상태
var portal_enabled: bool = false

# 스킬창 잠금 관련 변수
var skill_ui_unlocked: bool = false # 스킬창 사용 가능 여부

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
		print("=== [⚠️ TEST MODE ACTIVATED] ===")
		
		# A. 모든 스킬 지급
		var all_skills = InventoryManager.skill_database
		print("--- 1. 모든 스킬 인벤토리 지급 ---")
		for skill_path in all_skills:
			InventoryManager.add_skill_to_inventory(skill_path)
			
		# B. 스킬창 강제 해금 
		skill_ui_unlocked = true
		print("--- 2. 스킬창(K) 잠금 해제 완료 ---")
		
		# C. 플레이어 입력 잠금 강제 해제 
		if is_instance_valid(player):
			player.set_input_locked(false)
			print("--- 3. 플레이어 조작 잠금 강제 해제 ---")
			
		# D. 포탈 즉시 활성화 
		portal_enabled = true 
		print("--- 4. 포탈 즉시 활성화 ---")
		
		print("==================================")

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
		portal_enabled = true
		print(">>> 포탈이 활성화되었습니다! <<<")
		skill_get_ui.open_reward_screen()
	else:
		print("적이 사망했습니다. 남은 적: " + str(remaining_enemies.size() - 1))

func _on_skill_get_ui_closed():
	if is_instance_valid(player) and (not is_instance_valid(skill_ui) or not skill_ui.visible):
		player.set_input_locked(false)

func _unhandled_input(event):
	# K 키로 스킬창 열기/닫기
	if event.is_action_pressed("ui_text_completion_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_K):
		toggle_skill_ui()
		return

	# 치트 모드 기능들
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

	# 카메라 limit을 현재 스테이지에 맞게 재설정
	if camera.has_method("find_and_set_limits"):
		camera.find_and_set_limits()
		print("카메라 limit 재설정 완료")

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

# 포탈 진입 처리 (각 Stage에서 오버라이드 가능)
func _on_portal_body_entered(body):
	if not body.is_in_group("player"):
		return

	# 포탈이 활성화되지 않았으면 진입 불가
	if not portal_enabled:
		print(">>> 아직 포탈을 사용할 수 없습니다! 모든 적을 처치하세요. <<<")
		return

	print("포탈이 활성화되어 있습니다. 다음 스테이지로 이동하려면 Stage에서 이 함수를 오버라이드하세요.")
	# 각 Stage에서 이 함수를 오버라이드해서 SceneTransition.fade_to_scene() 호출

# 스킬창 토글 함수
func toggle_skill_ui():
	# 스킬창이 아직 잠겨있는지 확인
	if not skill_ui_unlocked:
		print("스킬창이 아직 잠겨있습니다.")
		return

	# skill_ui 확인
	if not is_instance_valid(skill_ui):
		print("경고: SkillUI를 찾을 수 없습니다.")
		return

	# 스킬창 토글
	skill_ui.visible = not skill_ui.visible

	var stage_player = player if player != null else get_node_or_null("Player")
	if is_instance_valid(stage_player):
		# 플레이어 입력 잠금/해제
		if stage_player.has_method("set_input_locked"):
			stage_player.set_input_locked(skill_ui.visible)
			print("스킬창 ", "열림" if skill_ui.visible else "닫힘")

		# 스킬창이 열렸을 때 UI 갱신
		if skill_ui.visible and skill_ui.has_method("refresh_ui"):
			skill_ui.refresh_ui(stage_player)

# 스킬창 잠금 해제
func unlock_skill_ui():
	skill_ui_unlocked = true
	print("=== 스킬창이 해제되었습니다! K 키를 눌러 스킬창을 열 수 있습니다. ===")
