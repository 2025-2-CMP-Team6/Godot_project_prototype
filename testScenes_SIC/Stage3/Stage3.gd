extends World

func _ready():
	super() # World 클래스의 _ready() 호출 (적 신호 연결, 음악 재생 등)

	# Stage3부터는 스킬창 자동 해제
	skill_ui_unlocked = true
	# 카메라 인트로 효과 후 플레이어 입력 잠금 해제
	var stage_player = player if player != null else get_node_or_null("Player")
	if stage_player and stage_player.has_method("set_input_locked"):
		stage_player.set_input_locked(false)
		print("Stage3 시작: 플레이어 입력 잠금 해제")
