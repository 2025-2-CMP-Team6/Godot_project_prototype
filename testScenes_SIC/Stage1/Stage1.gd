extends Node2D

@onready var player = $Player_test

# Dialogue 리소스 로드
var dialogue_resource = preload("res://testScenes_SIC/dialogue/test.dialogue")
var balloon_scene = preload("res://addons/dialogue_manager/example_balloon/example_balloon.tscn")

func _ready():
	# 플레이어 초기 상태 설정
	player.modulate.a = 0.0  # 완전 투명

	# Dialogue 표시 (balloon scene 직접 지정)
	print("Showing dialogue...")
	DialogueManager.show_example_dialogue_balloon(dialogue_resource, "start")

	# 페이드인 효과
	start_player_intro()

func start_player_intro():
	# Tween을 사용한 부드러운 애니메이션
	var tween = create_tween()

	# 페이드인 (투명도 0 -> 1)
	tween.tween_property(player, "modulate:a", 1.0, 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# 애니메이션 완료 후 dialogue 표시
	tween.finished.connect(_on_intro_finished)

func _on_intro_finished():
	# Intro 애니메이션 완료 후 dialogue 실행
	DialogueManager.show_dialogue_balloon(dialogue_resource, "start")
