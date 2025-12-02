# stage_boss.gd
extends Node2D

const BossMeteor = preload("res://Actors/Enemies/Boss/BossMeteor.tscn")

func _on_boss_pattern_started(pattern_name):
	if pattern_name == "pattern1":
		# 맵 패턴 1 실행
		print("Executing map pattern 1")
		var num_meteors = randi_range(4, 8)
		var meteorX: float
		var meteorA = get_random_positions(256, 3840, num_meteors)
		for i in range(num_meteors):
			var meteor = BossMeteor.instantiate()
			meteorX = meteorA[i]
			print("Meteor X Position: ", meteorX)
			add_child(meteor)
			meteor.position = Vector2(meteorX, -560)
	elif pattern_name == "pattern2":
		# 맵 패턴 2 실행
		print("Executing map pattern 2")
	elif pattern_name == "pattern3":
		# 맵 패턴 3 실행
		print("Executing map pattern 3")


func get_random_positions(step_size: int, max_size: int, count_to_pick: int) -> Array:
	var possible_positions = []
	var max_step = floor(max_size / step_size)
	for i in range(-max_step, max_step + 1):
		possible_positions.append(i * step_size)
	possible_positions.shuffle()
	print(possible_positions)
	return possible_positions.slice(0, count_to_pick)
