# res://EffectManager.gd
extends Node

#region 노드 참조 및 타이머
var camera: Camera2D
var flash_rect: ColorRect = null
var shake_timer: Timer = null
var shake_tween: Tween = null
var flash_tween: Tween = null
const HIT_EFFECT_SCENE = preload("res://effects/HitEffect.tscn")

func _ready():
	shake_timer = Timer.new()
	shake_timer.one_shot = true
	shake_timer.timeout.connect(_on_shake_timer_timeout)
	add_child(shake_timer)
#endregion

#region 초기화
func register_effects(cam_node: Camera2D, rect_node: ColorRect):
	self.camera = cam_node
	self.flash_rect = rect_node
#endregion
#region 화면 흔들림
func play_screen_shake(amplitude: float = 10.0, duration: float = 0.1):
	if not is_instance_valid(camera): return
	if shake_timer.time_left > 0:
		shake_timer.stop()
		_on_shake_timer_timeout()
	shake_timer.wait_time = duration
	shake_timer.start()
	shake_tween = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	shake_tween.tween_property(camera, "offset:x", amplitude, duration * 0.25)
	shake_tween.tween_property(camera, "offset:x", -amplitude, duration * 0.25)
	shake_tween.tween_property(camera, "offset:x", 0.0, duration * 0.5)

func _on_shake_timer_timeout():
	if shake_tween:
		shake_tween.kill()
	if is_instance_valid(camera):
		camera.offset = Vector2.ZERO
#endregion

#region 화면 점멸
func play_screen_flash(color: Color = Color.WHITE, duration: float = 0.1):
	if not is_instance_valid(flash_rect): return
	if flash_tween:
		flash_tween.kill()
	flash_rect.color = color
	flash_rect.modulate.a = 0.7
	flash_tween = get_tree().create_tween().set_ease(Tween.EASE_IN)
	flash_tween.tween_property(flash_rect, "modulate:a", 0.0, duration)

func play_multi_flash(color: Color = Color.WHITE, duration_per_flash: float = 0.05, flash_count: int = 3):
	if not is_instance_valid(flash_rect): return
	
	if flash_tween:
		flash_tween.kill()
		
	flash_tween = get_tree().create_tween().set_loops(flash_count)
	
	flash_rect.color = color
	flash_tween.tween_property(flash_rect, "modulate:a", 0.7, duration_per_flash * 0.5).set_ease(Tween.EASE_OUT)
	flash_tween.tween_property(flash_rect, "modulate:a", 0.0, duration_per_flash * 0.5).set_ease(Tween.EASE_IN)
#endregion

#region 쉐이더 제어
func set_hit_flash_amount(sprite_node: Sprite2D, amount: float):
	if is_instance_valid(sprite_node) and sprite_node.material:
		sprite_node.material.set_shader_parameter("flash_mix", amount)
#endregion

#region 히트 파티클
func play_hit_effect(pos: Vector2, scale_amount: float = 1.0):
	if not HIT_EFFECT_SCENE: return
	
	var effect = HIT_EFFECT_SCENE.instantiate()
	effect.global_position = pos
	effect.scale = Vector2(scale_amount, scale_amount)
	
	get_tree().current_scene.add_child(effect)
#endregion
