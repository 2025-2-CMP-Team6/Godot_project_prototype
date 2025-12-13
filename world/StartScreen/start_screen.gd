extends Control

# Variables to assign stage-specific music in the inspector
@export_category("Stage Settings")
@export var stage_bgm: AudioStream # Put the mp3 file here
@export var bgm_volume_db: float = -10.0 # Default volume setting
@export var start_button_effect_sound: AudioStream

func _ready():
	# Audio setup and playback
	_setup_stage_music()


func _on_start_button_pressed():
	var sfx_key = "StartSFX"
	var sfx_plus = AudioManagerPlus.new()
	sfx_plus.stream = start_button_effect_sound
	sfx_plus.volume_db = bgm_volume_db
	sfx_plus.audio_name = sfx_key
	sfx_plus.loop = false
	_audio_manager.add_plus(sfx_key, sfx_plus)
	_audio_manager.play_plus(sfx_key)
	# Load and change to the world scene with fade transition
	SceneTransition.fade_to_scene("res://testScenes_SIC/Stage1/Stage1.tscn")


func _on_options_button_pressed():
	# Load and change to the options scene
	get_tree().change_scene_to_file("res://world/Option/option.tscn")


func _on_quit_button_pressed():
	# Quit the game
	get_tree().quit()

# Audio manager variables
var _audio_manager: AudioManager
var _bgm_key: String = "StageBGM"

# Music setup function
func _setup_stage_music():
	if stage_bgm == null:
		return

	# Create AudioManager and add it to the scene
	_audio_manager = AudioManager.new()
	add_child(_audio_manager)

	# Configure AudioManagerPlus (for background music)
	var bgm_plus = AudioManagerPlus.new()
	bgm_plus.stream = stage_bgm
	bgm_plus.loop = true # Loop setting
	bgm_plus.volume_db = bgm_volume_db
	bgm_plus.audio_name = _bgm_key # Name used later for stopping/control

	# Register in manager and play
	_audio_manager.add_plus(_bgm_key, bgm_plus)
	_audio_manager.play_plus(_bgm_key)
