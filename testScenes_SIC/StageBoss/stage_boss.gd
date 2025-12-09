# stage_boss.gd
extends Node2D

enum Pattern {METEOR, AIMED_LASER, PATTERN_3}

const BossMeteor = preload("res://Actors/Enemies/Boss/BossMeteor.tscn")
const BossFire = preload("res://Actors/Enemies/Boss/BossFire.tscn")


@export var map_pattern_timer: Timer
@export var map_lasers: Array[Node2D]
var map_patterns = [Pattern.METEOR, Pattern.AIMED_LASER, Pattern.PATTERN_3]


func _ready():
	if map_pattern_timer:
		map_pattern_timer.timeout.connect(_on_map_pattern_timer_timeout)
		map_pattern_timer.wait_time = randf_range(3.0, 5.0)
		map_pattern_timer.start()


func _on_map_pattern_timer_timeout():
	var chosen_pattern = map_patterns.pick_random()
	match chosen_pattern:
		Pattern.METEOR:
			# 맵 패턴 1
			print("Executing map pattern 1")
			var num_meteors = randi_range(4, 8)
			var meteorX: float
			var meteorA = get_random_positions(256, 1920, num_meteors)
			for i in range(num_meteors):
				var meteor = BossMeteor.instantiate()
				meteorX = meteorA[i]
				print("Meteor X Position: ", meteorX)
				add_child(meteor)
				meteor.position = Vector2(meteorX, -560)
		Pattern.AIMED_LASER:
			trigger_lasers()
			print("Executing map pattern 2")
		Pattern.PATTERN_3:
			var num_fires = randi_range(2, 4)
			var fireX: float
			var fireA = get_random_positions(256, 1920, num_fires)

			for i in range(num_fires):
				var fire = BossFire.instantiate()
				fireX = fireA[i]
				print("Fire X Position: ", fireX)
				add_child(fire)
				fire.position = Vector2(fireX, 776)

	
	map_pattern_timer.wait_time = randf_range(3.0, 5.0)
	map_pattern_timer.start()


func get_random_positions(step_size: int, max_size: int, count_to_pick: int) -> Array:
	var possible_positions = []
	var max_step = floor(max_size / step_size)
	for i in range(-max_step, max_step + 1):
		possible_positions.append(i * step_size)
	possible_positions.shuffle()
	print(possible_positions)
	return possible_positions.slice(0, count_to_pick)

func trigger_lasers():
	for laser in map_lasers:
		if is_instance_valid(laser) and laser.has_method("start_laser_pattern"):
			laser.start_laser_pattern()