extends World

func _ready():
	super() # World 클래스의 _ready() 호출 (적 신호 연결, 음악 재생 등)
	
	skill_ui_unlocked = true
	# 카메라 인트로 효과 후 플레이어 입력 잠금 해제
	var stage_player = player if player != null else get_node_or_null("Player")
	if stage_player and stage_player.has_method("set_input_locked"):
		stage_player.set_input_locked(false)
		print("Stage3 시작: 플레이어 입력 잠금 해제")
		
func _on_portal_body_entered(body):
	if not body.is_in_group("player"):
		return

	# World의 포탈 체크 먼저 실행 (모든 적 처치 확인)
	if not portal_enabled:
		print(">>> 아직 포탈을 사용할 수 없습니다! 모든 적을 처치하세요. <<<")
		return

	print("플레이어가 포탈에 진입했습니다!")
	SceneTransition.fade_to_scene("res://testScenes_SIC/Stage4/Stage4.tscn")


func _on_booby_trap_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
