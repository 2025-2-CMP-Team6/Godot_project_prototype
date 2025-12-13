# boss_hp_bar.gd
extends CanvasLayer

@onready var health_bar = $Control/VBoxContainer/ProgressBar
@onready var label = $Control/VBoxContainer/Label
@onready var disappear_timer = $DisappearTimer

# Initial setup
func initialize(enemy_name: String, max_hp: float, current_hp: float):
	if label:
		label.text = enemy_name
	
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	visible = false

# Update on hit
func update_health(current_hp: float):
	visible = true
	# Smooth decrease effect (optional)
	var tween = create_tween()
	tween.tween_property(health_bar, "value", current_hp, 0.2)
	# health_bar.value = current_hp # If you don't want to use a tween, just do this
	disappear_timer.start()
	
func _on_disappear_timer_timeout() -> void:
		visible = false

# Remove UI when the boss dies
func on_boss_died():
	queue_free()
