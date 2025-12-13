# world.gd
class_name World extends Node2D

# If test mode is enabled, all skills exist in the inventory
@export var is_test_mode: bool = false

# Fetch nodes placed in the scene.
@export var player: CharacterBody2D
@export var skill_get_ui: SkillGetUI
@export var skill_ui: SkillUI

# Portal activation state
var portal_enabled: bool = false

# Skill window lock-related variables
var skill_ui_unlocked: bool = false # Whether the skill window can be used

# Variables to assign stage-specific music in the inspector
@export_category("Stage Settings")
@export var stage_bgm: AudioStream # Put the mp3 file here
@export var bgm_volume_db: float = -10.0 # Default volume setting

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

func _ready():
	# Give test skills only when the checkbox is enabled
	if is_test_mode:
		print("=== [⚠️ TEST MODE ACTIVATED] ===")
		
		# A. Grant all skills
		var all_skills = InventoryManager.skill_database
		print("--- 1. Grant all skills to inventory ---")
		for skill_path in all_skills:
			InventoryManager.add_skill_to_inventory(skill_path)
			
		# B. Force-unlock the skill window
		skill_ui_unlocked = true
		print("--- 2. Skill window (K) unlocked ---")
		
		# C. Force-unlock player input lock
		if is_instance_valid(player):
			player.set_input_locked(false)
			print("--- 3. Player control lock released ---")
			
		# D. Enable portal immediately
		portal_enabled = true
		print("--- 4. Portal enabled immediately ---")
		
		print("==================================")

	# Audio setup and playback
	_setup_stage_music()
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() > 0:
		for enemy in enemies:
			if not enemy.enemy_died.is_connected(_on_enemy_died):
				enemy.enemy_died.connect(_on_enemy_died)
	else:
		print("Warning: There are no enemies in the map with the 'enemies' group.")
	if is_instance_valid(skill_get_ui):
		skill_get_ui.closed.connect(_on_skill_get_ui_closed)

func _on_enemy_died():
	var remaining_enemies = get_tree().get_nodes_in_group("enemies")
	if remaining_enemies.size() <= 1:
		print("All enemies defeated! Opening reward selection screen.")
		portal_enabled = true
		print(">>> The portal has been activated! <<<")
		if is_instance_valid(skill_get_ui):
			skill_get_ui.open_reward_screen()
		else:
			print("Warning: SkillGetUI is not set. Cannot open the reward screen.")
	else:
		print("An enemy has died. Remaining enemies: " + str(remaining_enemies.size() - 1))

func _on_skill_get_ui_closed():
	if is_instance_valid(player) and (not is_instance_valid(skill_ui) or not skill_ui.visible):
		player.set_input_locked(false)

func _unhandled_input(event):
	# Open/close the skill window with the K key
	if event.is_action_pressed("ui_text_completion_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_K):
		toggle_skill_ui()
		return

	# Cheat mode features
	if !GameManager.is_cheat:
		return
	# Reward test
	if event.is_action_pressed("get_skill_test"):
		if is_instance_valid(skill_get_ui):
			skill_get_ui.open_reward_screen()
			if is_instance_valid(player):
				player.set_input_locked(true)
		return

	# Skill window test
	if Input.is_action_just_pressed("ui_inventory"):
		if is_instance_valid(skill_ui):
			skill_ui.visible = not skill_ui.visible
			if is_instance_valid(player):
				player.set_input_locked(skill_ui.visible)
			if skill_ui.visible:
				skill_ui.refresh_ui(player)
		return

# Camera intro effect: show the entire map, then zoom in to the player
# Reusable across all stages
func camera_intro_effect(
	initial_zoom: Vector2 = Vector2(0.272, 0.3),
	show_duration: float = 3.0,
	zoom_duration: float = 2.0,
	enable_parallax_transition: bool = true
):
	# Find the player node
	var stage_player = player if player != null else get_node_or_null("Player")
	if stage_player == null:
		print("Warning: Cannot find the Player node.")
		return

	# Find the player's camera
	var camera = stage_player.get_node_or_null("Camera2D")
	if camera == null:
		print("Warning: Cannot find the Player's Camera2D.")
		return

	# Reset camera limits to match the current stage
	if camera.has_method("find_and_set_limits"):
		camera.find_and_set_limits()
		print("Camera limits reset complete.")

	# Find Background node
	var background = get_node_or_null("Background")
	var parallax_nodes = []
	var original_scroll_scales = []

	# If Parallax effect is enabled and Background exists, process it
	if enable_parallax_transition and background != null:
		for child in background.get_children():
			if child is Parallax2D:
				parallax_nodes.append(child)
				original_scroll_scales.append(child.scroll_scale)
				child.scroll_scale = Vector2(1.0, 1.0)

	# Set initial zoom-out (to show the whole map)
	var target_zoom = Vector2(1.0, 1.0) # Normal zoom centered on the player
	camera.zoom = initial_zoom

	# Wait to show the whole map briefly
	await get_tree().create_timer(show_duration).timeout

	# Zoom-in animation centered on the player
	var zoom_tween = create_tween()
	zoom_tween.set_ease(Tween.EASE_IN_OUT)
	zoom_tween.set_trans(Tween.TRANS_CUBIC)
	zoom_tween.tween_property(camera, "zoom", target_zoom, zoom_duration)

	# Smoothly restore scroll_scale of Parallax2D nodes (at the same time as the zoom)
	if enable_parallax_transition and parallax_nodes.size() > 0:
		var parallax_tween = create_tween()
		parallax_tween.set_ease(Tween.EASE_IN_OUT)
		parallax_tween.set_trans(Tween.TRANS_CUBIC)
		parallax_tween.set_parallel(true) # Run all tweens simultaneously

		for i in range(parallax_nodes.size()):
			parallax_tween.tween_property(parallax_nodes[i], "scroll_scale", original_scroll_scales[i], zoom_duration)

	# Wait until the animation finishes
	await zoom_tween.finished

# Portal entry handling (can be overridden in each Stage)
func _on_portal_body_entered(body):
	if not body.is_in_group("player"):
		return

	# Cannot enter if the portal is not enabled
	if not portal_enabled:
		print(">>> You can't use the portal yet! Defeat all enemies first. <<<")
		return

	print("The portal is enabled. Override this function in the Stage to move to the next stage.")
	# Override this function in each Stage to call SceneTransition.fade_to_scene()

# Skill window toggle function
func toggle_skill_ui():
	# Check if the skill window is still locked
	if not skill_ui_unlocked:
		print("The skill window is still locked.")
		return

	# Validate skill_ui
	if not is_instance_valid(skill_ui):
		print("Warning: Cannot find SkillUI.")
		return

	# Toggle the skill window
	skill_ui.visible = not skill_ui.visible

	var stage_player = player if player != null else get_node_or_null("Player")
	if is_instance_valid(stage_player):
		# Lock/unlock player input
		if stage_player.has_method("set_input_locked"):
			stage_player.set_input_locked(skill_ui.visible)
			print("Skill window ", "opened" if skill_ui.visible else "closed")

		# Refresh UI when the skill window opens
		if skill_ui.visible and skill_ui.has_method("refresh_ui"):
			skill_ui.refresh_ui(stage_player)

# Unlock the skill window
func unlock_skill_ui():
	skill_ui_unlocked = true
	print("=== Skill window unlocked! Press K to open the skill window. ===")
