# bullet.gd
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 400.0

func _physics_process(delta: float):
	global_position += direction * speed * delta


func _on_body_entered(body):
	if body.has_method("lose_life"):
		body.lose_life()
		
		queue_free()
	
func _on_screen_exited():
	queue_free()
