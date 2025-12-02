# bullet.gd
extends Area2D

var velocity: Vector2 = Vector2.ZERO
var gravity_acceleration: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_falling = false

func _ready():
	$Timer.wait_time = randf_range(0.3, 1.0)
	$Timer.timeout.connect(_on_Timer_timeout)
	$Timer.start()

func _physics_process(delta):
	if is_falling:
		velocity.y += gravity_acceleration * delta
		position += velocity * delta

func _on_body_entered(body):
	if body.name == "wall":
		queue_free()
	if body.has_method("lose_life"):
		body.lose_life()
		queue_free()
	
func _on_screen_exited():
	queue_free()

func _on_Timer_timeout():
	is_falling = true
