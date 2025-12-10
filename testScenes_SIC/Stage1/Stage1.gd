extends World

# Dialogue 리소스 로드
var dialogue_resource = preload("res://testScenes_SIC/dialogue/stage1.dialogue")

# 리스폰 관련 변수
var spawn_position: Vector2 = Vector2(310.99988, 5081.0005) # 플레이어 시작 위치

func _ready():
	super() #오디오매니저 세팅을 위해 필요합니다. 인스펙터의 Stage Settings에 원하는 음악을 넣으면 됩니다.

	# 카메라 인트로 효과 실행 (world.gd의 공통 함수 사용)
	await camera_intro_effect()

	# 인트로 효과가 끝난 후 대화 시작
	DialogueManager.show_example_dialogue_balloon(dialogue_resource, "start")

func _on_fall_prevention_body_entered(body: Node2D):
	if body.is_in_group("player"):
		respawn_player(body)

func respawn_player(player: Node2D):
	if player:
		# 플레이어를 시작 위치로 이동
		player.global_position = spawn_position
		# 속도 초기화
		if player is CharacterBody2D:
			player.velocity = Vector2.ZERO
		print("플레이어가 리스폰되었습니다!")

func _on_portal_body_entered(body):
	if body.is_in_group("player"):
		print("플레이어가 포탈에 진입했습니다!")
		# 여기에 포탈 이동 로직을 추가하세요
		SceneTransition.fade_to_scene("res://testScenes_SIC/Stage2/Stage2.tscn")
