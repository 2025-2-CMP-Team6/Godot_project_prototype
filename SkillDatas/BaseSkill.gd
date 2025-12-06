# BaseSkill.gd
extends Node
class_name BaseSkill

#region 스킬 속성
@export var skill_name: String = "기본 스킬"
@export var skill_description: String = "스킬 설명."
@export var skill_icon: Texture
@export var cast_duration: float = 0.3
@export var stamina_cost: float = 10.0
@export var cooldown: float = 1.0
@export var type: int = 1
@export var requires_target: bool = false
@export var ends_on_condition: bool = false
@export var damage: float = 10.0
@export var max_cast_range: float = 0.0
@export var gravity_multiplier: float = 1.0

# 스킬 사운드 설정
@export_group("Sound Settings")
@export var cast_sound: AudioStream # 여기에 파일을 넣
@export var sound_volume_db: float = 1.0
@export var sound_pitch_scale: float = 1.0
@export var random_pitch: bool = true # 피치 섞을지 여부(지루함 감소)
#endregion

var cooldown_timer: Timer
var is_active: bool = false

# ★ (추가) 이 스킬 노드의 현재 레벨 (SkillInstance로부터 받아옴)
var current_level: int = 0

# ★ (추가) 이 스킬이 참조하는 인벤토리의 원본 데이터 (SkillInstance)
var skill_instance_ref: SkillInstance = null

# 오디오 플레이어 매니
var _audio_manager: AudioManager

# 사운드 설정 함수
func _setup_sound():
	if cast_sound:
		# 매니저 실행, 자식으로 추가
		_audio_manager = AudioManager.new()
		add_child(_audio_manager)

		# 2. 소리 설정(AudioManagerPlus) 생성가
		var sound_config = AudioManagerPlus.new()
		sound_config.stream = cast_sound
		sound_config.volume_db = sound_volume_db
		sound_config.pitch_scale = sound_pitch_scale
		sound_config.audio_name = "skill_cast" # 식별할 이름
		
		# 소리 등록
		_audio_manager.add_plus("skill_cast", sound_config)
		
# 재생 함수
func _play_sound():
	if _audio_manager:
		# 랜덤 피치 로직 
		if random_pitch: #지루함 감소
			var config = _audio_manager.get_plus("skill_cast")
			if config:
				# 원본 피치에서 약간만 변형
				config.pitch_scale = sound_pitch_scale + randf_range(-0.2, 0.2)
		
		# 재생 명령
		_audio_manager.play_plus("skill_cast")

func _ready():
	cooldown_timer = Timer.new()
	cooldown_timer.one_shot = true
	add_child(cooldown_timer)
	
	_setup_sound()

# 스킬 사용 가능 여부
func is_ready() -> bool:
	if cooldown_timer == null:
		return false
	return cooldown_timer.is_stopped()

#region 스킬 시전
func execute(owner: CharacterBody2D, target: Node2D = null):
	is_active = true
	print(owner.name + "가 " + skill_name + " 시전!")
	# 소리 재생
	_play_sound()
	

func start_cooldown():
	if cooldown_timer != null:
		cooldown_timer.wait_time = cooldown
		cooldown_timer.start()
		
func process_skill_physics(owner: CharacterBody2D, delta: float):
	pass

func get_cooldown_time_left() -> float:
	if cooldown_timer != null:
		return cooldown_timer.time_left
	return 0.0
#endregion
