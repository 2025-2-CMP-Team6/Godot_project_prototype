
extends CanvasLayer

@onready var color_rect = $ColorRect
var is_transitioning = false

func _ready():
	# Start with transparent (invisible)
	color_rect.modulate.a = 0.0

# Main function to transition between scenes with fade effect
func fade_to_scene(scene_path: String, duration: float = 0.5):
	if is_transitioning:
		return

	is_transitioning = true

	# Fade out (black screen appears)
	await fade_out(duration)

	# Change scene
	get_tree().change_scene_to_file(scene_path)

	# Fade in (black screen disappears)
	await fade_in(duration)

	is_transitioning = false

# Fade to black
func fade_out(duration: float = 0.5):
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, duration)
	await tween.finished

# Fade from black
func fade_in(duration: float = 0.5):
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 0.0, duration)
	await tween.finished

# Optional: Instant fade (for immediate transitions)
func instant_fade_out():
	color_rect.modulate.a = 1.0

func instant_fade_in():
	color_rect.modulate.a = 0.0
