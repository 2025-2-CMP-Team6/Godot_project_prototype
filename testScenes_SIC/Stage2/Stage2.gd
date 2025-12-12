extends World

var spawn_position: Vector2 = Vector2(10095.0, 4196.0) # 플레이어 시작 위치
var current_respawn_position: Vector2 # 현재 리스폰 위치 (가장 최근 죽인 적의 위치)

# 체크포인트 그룹 정의
# 각 그룹: { enemies: [적 이름들], respawn_provider: 리스폰 위치를 제공할 적 이름 }
var checkpoint_groups = {
	"group1": {
		"enemies": ["Virus", "Virus2"],
		"respawn_provider": "Virus"
	},
	"group2": {
		"enemies": ["RangeVirus", "RangeVirus2", "RangeVirus3"],
		"respawn_provider": "RangeVirus3"
	},
	"group3": {
		"enemies": ["Virus3", "Virus4", "RangeVirus3"],
		"respawn_provider": "Virus3"
	}
}

# 적 사망 여부 추적
var dead_enemies: Dictionary = {}

# 체크포인트 달성 여부 추적 (중복 메시지 방지)
var completed_checkpoints: Dictionary = {}

func _ready():
	super() # World 클래스의 _ready() 호출 (적 신호 연결, 음악 재생 등)

	current_respawn_position = spawn_position

	# Stage2부터는 스킬창 자동 해제 (튜토리얼 이후)
	skill_ui_unlocked = true

	# 체크포인트 그룹의 적들 신호 연결
	_connect_checkpoint_enemies()

	await camera_intro_effect(Vector2(0.23, 0.27))

	# 카메라 인트로 효과 후 플레이어 입력 잠금 해제
	var stage_player = player if player != null else get_node_or_null("Player")
	if stage_player and stage_player.has_method("set_input_locked"):
		stage_player.set_input_locked(false)
		print("Stage2 시작: 플레이어 입력 잠금 해제")

# 체크포인트 그룹의 적들 신호 연결
func _connect_checkpoint_enemies():
	# 모든 그룹의 모든 적을 수집 (중복 제거)
	var all_enemies_set = {}
	for group_name in checkpoint_groups:
		var group = checkpoint_groups[group_name]
		for enemy_name in group.enemies:
			all_enemies_set[enemy_name] = true

	# 각 적의 enemy_died 신호 연결
	for enemy_name in all_enemies_set:
		var enemy = get_node_or_null(enemy_name)
		if enemy and enemy.has_signal("enemy_died"):
			enemy.enemy_died.connect(func(): _on_checkpoint_enemy_died(enemy, enemy_name))
			print("체크포인트 적 연결됨: ", enemy_name)
			# 초기 사망 상태는 false
			dead_enemies[enemy_name] = false

# 체크포인트 적이 죽었을 때 호출
func _on_checkpoint_enemy_died(enemy: Node2D, enemy_name: String):
	print("=== 적 처치: ", enemy_name, " ===")

	# 사망 처리
	dead_enemies[enemy_name] = true

	# 이 적이 속한 모든 그룹 확인
	for group_name in checkpoint_groups:
		var group = checkpoint_groups[group_name]

		# 이미 이 그룹의 체크포인트를 달성했으면 스킵
		if completed_checkpoints.get(group_name, false):
			continue

		# 이 적이 이 그룹에 속하는지 확인
		if enemy_name in group.enemies:
			# 그룹의 모든 적이 죽었는지 확인
			var all_dead = true
			for group_enemy_name in group.enemies:
				if not dead_enemies.get(group_enemy_name, false):
					all_dead = false
					break

			# 모두 죽었으면 리스폰 위치 업데이트
			if all_dead:
				var respawn_provider_name = group.respawn_provider
				var respawn_provider = get_node_or_null(respawn_provider_name)

				if respawn_provider:
					current_respawn_position = respawn_provider.global_position
					completed_checkpoints[group_name] = true
					print(">>> 체크포인트 달성! (", group_name, ") 새 리스폰 위치: ", respawn_provider_name, " - ", current_respawn_position)
				else:
					print("경고: 리스폰 제공자를 찾을 수 없음: ", respawn_provider_name)

func _on_portal_body_entered(body):
	if not body.is_in_group("player"):
		return

	# World의 포탈 체크 먼저 실행 (모든 적 처치 확인)
	if not portal_enabled:
		print(">>> 아직 포탈을 사용할 수 없습니다! 모든 적을 처치하세요. <<<")
		return

	print("플레이어가 포탈에 진입했습니다!")
	SceneTransition.fade_to_scene("res://testScenes_SIC/Stage3/Stage3.tscn")
		
func _on_fall_prevention_body_entered(body: Node2D):
	if body.is_in_group("player"):
		respawn_player(body)		

func respawn_player(player: Node2D):
	if player:
		# 플레이어를 현재 체크포인트 위치로 이동
		player.global_position = current_respawn_position
		# 속도 초기화
		if player is CharacterBody2D:
			player.velocity = Vector2.ZERO
		print("플레이어가 리스폰되었습니다! 위치: ", current_respawn_position)
