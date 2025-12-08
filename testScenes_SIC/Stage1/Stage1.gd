extends World

# Dialogue 리소스 로드
var dialogue_resource = preload("res://testScenes_SIC/dialogue/stage1.dialogue")

func _ready():
	super() #오디오매니저 세팅을 위해 필요합니다. 인스펙터의 Stage Settings에 원하는 음악을 넣으면 됩니다.

	# 카메라 인트로 효과 실행
	await camera_intro_effect()

	# 인트로 효과가 끝난 후 대화 시작
	DialogueManager.show_example_dialogue_balloon(dialogue_resource, "start")

# 카메라 인트로 효과: 맵 전체를 보여주고 플레이어로 줌인
func camera_intro_effect():
	# 플레이어 노드 찾기
	var player = get_node_or_null("Player")
	if player == null:
		print("경고: Player 노드를 찾을 수 없습니다.")
		return

	# 플레이어의 카메라 찾기
	var camera = player.get_node_or_null("Camera2D")
	if camera == null:
		print("경고: Player의 Camera2D를 찾을 수 없습니다.")
		return

	# 초기 줌 아웃 설정 (맵 전체를 보여주기 위해)
	var initial_zoom = Vector2(0.272, 0.3)  # 줌 아웃된 상태
	var target_zoom = Vector2(1.0, 1.0)     # 플레이어 중심 일반 줌

	camera.zoom = initial_zoom

	# 맵 전체를 잠시 보여주기 위해 대기
	await get_tree().create_timer(3).timeout

	# 플레이어 중심으로 줌 인 애니메이션
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(camera, "zoom", target_zoom, 2.0)

	# 애니메이션 완료까지 대기
	await tween.finished

func _on_portal_body_entered(body):
	if body.is_in_group("player"):
		print("플레이어가 포탈에 진입했습니다!")
		# 여기에 포탈 이동 로직을 추가하세요
		get_tree().change_scene_to_file("res://testScenes_SIC/Stage2/Stage2.tscn")
