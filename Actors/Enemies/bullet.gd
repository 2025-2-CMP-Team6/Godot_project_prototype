# actors/enemies/bullet.gd
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 400.0

func _physics_process(delta: float):
	global_position += direction * speed * delta


# 이 총알(Area2D)이 다른 PhysicsBody2D와 충돌했을 때 호출됩니다.
func _on_body_entered(body):
	# 충돌한 body가 플레이어인지 'lose_life' 메서드를 가지고 있는지로 확인합니다.
	if body.has_method("lose_life"):
		# 플레이어의 생명을 깎는 함수를 호출합니다.
		body.lose_life()
		
		# 플레이어와 충돌했으므로 총알을 제거합니다.
		queue_free()
	
	# 충돌한 대상이 플레이어가 아니라면 (예: 다른 적, 벽 등) 아무 동작 없이 통과합니다.


# 'VisibleOnScreenNotifier2D'가 화면 밖으로 나갔을 때 호출됨
func _on_screen_exited():
	queue_free()
