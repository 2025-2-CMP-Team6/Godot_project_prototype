# boss_laser.gd
extends Node2D

#region Settings
@export var max_length: float = 5000.0 # Laser max range
@export var warning_time: float = 1.5 # Aiming (warning) time
@export var stop_time: float = 1.0 # Aiming (lock) time
@export var fire_duration: float = 0.3 # Fire duration
@export var damage: float = 30.0 # Damage
@export var pos: Vector2 # Position
@export var size: Vector2 # Size
#endregion

#region Node References
@onready var line_2d = $Line2D
@onready var hitbox = $Hitbox
@onready var collision_shape = $Hitbox/CollisionShape2D
#endregion

var is_tracking: bool = false
var target_player: Node2D = null

func _ready():
	pos = collision_shape.position # Position
	size = collision_shape.shape.size # Size
	line_2d.visible = false
	hitbox.monitoring = false
	line_2d.points = [Vector2.ZERO, Vector2.ZERO]
	

func _physics_process(_delta):
	if is_tracking and is_instance_valid(target_player):
		look_at(target_player.global_position)
		_update_beam_visual(20.0, Color(1, 0, 0, 0.3))

func start_laser_pattern():
	target_player = get_tree().get_first_node_in_group("player")
	if not target_player: return
	
	print("Map laser: start aiming")
	is_tracking = true
	line_2d.visible = true
	
	await get_tree().create_timer(warning_time).timeout

	is_tracking = false
	await get_tree().create_timer(stop_time).timeout
	
	is_tracking = false
	fire()

func fire():
	print("Map laser: fire!")
	hitbox.monitoring = true
	_update_beam_visual(300.0, Color(1, 0, 0, 0.8))
	await get_tree().create_timer(fire_duration).timeout
	stop()

func stop():
	line_2d.visible = false
	hitbox.monitoring = false
	collision_shape.position = pos
	collision_shape.shape.size = size
	line_2d.points = [Vector2.ZERO, Vector2.ZERO]

func _update_beam_visual(width: float, color: Color):
	var end_point = Vector2(max_length, 0)

	line_2d.width = width
	line_2d.default_color = color
	line_2d.points[1] = end_point
	
	if hitbox.monitoring:
		var length = end_point.length()
		collision_shape.shape.size = Vector2(length, width)
		collision_shape.position = Vector2(length / 2, 0)

func _on_hitbox_body_entered(body):
	print("Map laser: player collision detected")
	if body.has_method("lose_life"):
		print("Map laser: applying damage to player")
		body.lose_life()

func _get_item_rect() -> Rect2:
	return Rect2(-50000, -50000, 100000, 100000)
