# stage_boss.gd
extends World

enum Pattern {METEOR, AIMED_LASER, FIRE}

const BossMeteor = preload("res://Actors/Enemies/Boss/BossMeteor.tscn")
const BossFire = preload("res://Actors/Enemies/Boss/BossFire.tscn")


@export var map_pattern_timer: Timer
@export var map_lasers: Array[Node2D]
var map_patterns = [Pattern.METEOR, Pattern.AIMED_LASER, Pattern.FIRE]


func _ready():
	super() # World 클래스의 _ready() 호출 (적 신호 연결, 음악 재생 등)
	var stage_player = player if player != null else get_node_or_null("Player")
	if stage_player and stage_player.has_method("set_input_locked"):
		stage_player.set_input_locked(false)
		print("Stage4 시작: 플레이어 입력 잠금 해제")
		
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
		Pattern.FIRE:
			if check_fire_exist():
				print("Fires already exist, skipping FIRE pattern.")
				map_pattern_timer.wait_time = randf_range(0.1, 0.2)
				map_pattern_timer.start()
				return
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

func check_fire_exist():
	var fires = get_tree().get_nodes_in_group("boss_fire")
	
	if fires.size() > 0:
		return true
	else:
		return false
