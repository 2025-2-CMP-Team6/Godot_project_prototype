extends World

var spawn_position: Vector2 = Vector2(10095.0, 4196.0) # 플레이어 시작 위치
var current_respawn_position: Vector2 # 현재 리스폰 위치 (가장 최근 죽인 적의 위치)

func _ready():
	super() # World 클래스의 _ready() 호출 (적 신호 연결, 음악 재생 등)

	current_respawn_position = spawn_position

	# Stage2부터는 스킬창 자동 해제 (튜토리얼 이후)
	skill_ui_unlocked = true

	await camera_intro_effect(Vector2(0.23, 0.27))

	# 카메라 인트로 효과 후 플레이어 입력 잠금 해제
	var stage_player = player if player != null else get_node_or_null("Player")
	if stage_player and stage_player.has_method("set_input_locked"):
		stage_player.set_input_locked(false)
		print("Stage2 시작: 플레이어 입력 잠금 해제")

func _on_portal_body_entered(body):
	if not body.is_in_group("player"):
		return

	# World의 포탈 체크 먼저 실행 (모든 적 처치 확인)
	if not portal_enabled:
		print(">>> 아직 포탈을 사용할 수 없습니다! 모든 적을 처치하세요. <<<")
		return

	print("플레이어가 포탈에 진입했습니다!")
	SceneTransition.fade_to_scene("res://testScenes_SIC/Stage3/Stage3.tscn")
		
func _on_fall_prevention_body_entered(body: Node2D):
	if body.is_in_group("player"):
		respawn_player(body)		

func respawn_player(player: Node2D):
	if player:
		# 플레이어를 현재 체크포인트 위치로 이동
		player.global_position = current_respawn_position
		# 속도 초기화
		if player is CharacterBody2D:
			player.velocity = Vector2.ZERO
		print("플레이어가 리스폰되었습니다! 위치: ", current_respawn_position)
