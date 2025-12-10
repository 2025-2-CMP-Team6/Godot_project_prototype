extends World

func _ready():
	await camera_intro_effect(Vector2(0.5, 0.6))

func _on_portal_body_entered(body):
	if body.is_in_group("player"):
		print("플레이어가 포탈에 진입했습니다!")
		# 여기에 포탈 이동 로직을 추가하세요
		SceneTransition.fade_to_scene("res://testScenes_SIC/Stage3/Stage3.tscn")
