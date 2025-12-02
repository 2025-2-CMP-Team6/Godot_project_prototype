extends AnimatedSprite2D

var player: CharacterBody2D = null

func _ready():
	player = get_parent().get_parent() if get_parent() else null

func _process(_delta):
	match GameManager.state:
		GameManager.State.IDLE: play("idle")
		GameManager.State.MOVE: play("run")
		GameManager.State.DASH: play("DASH") # 일단 임시로 Dash 애니메이션
		GameManager.State.SKILL_CASTING: play("attack", 3) # 스킬 캐스팅 시간에 따라 조정해야 할듯?
	if player and not player.is_on_floor():
		play("jump")
