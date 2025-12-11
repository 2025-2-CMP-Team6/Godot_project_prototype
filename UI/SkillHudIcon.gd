# SkillHudIcon.gd
extends Control

#region 노드 참조
@onready var icon_rect: TextureRect = $Icon
@onready var cooldown_bar: ProgressBar = $CooldownBar
@onready var cooldown_label: Label = $CooldownLabel
@onready var keybind_label: Label = $KeybindLabel
#endregion

#region 변수
var skill_slot_node: Node = null
var keybind_text: String = ""
#endregion

#region 초기화
func _ready():
	# 아이콘/프로그레스바
	icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cooldown_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# 쿨타임 텍스트
	cooldown_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cooldown_label.add_theme_constant_override("outline_size", 6)
	cooldown_label.add_theme_color_override("font_outline_color", Color.BLACK)
	cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# 키 바인드 텍스트
	keybind_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	keybind_label.add_theme_font_size_override("font_size", 24)
	keybind_label.position = Vector2(8, -16)
	keybind_label.add_theme_constant_override("outline_size", 4)
	keybind_label.add_theme_color_override("font_outline_color", Color.BLACK)

	# 프로그레스바 스타일
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0, 0, 0, 0.7)
	fill_style.set_content_margin_all(0)
	fill_style.set_corner_radius_all(8)
	cooldown_bar.add_theme_stylebox_override("fill", fill_style)
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color.TRANSPARENT
	bg_style.set_content_margin_all(0)
	bg_style.set_corner_radius_all(8)
	cooldown_bar.add_theme_stylebox_override("background", bg_style)
	
	_clear_display()

func setup_hud(slot_node: Node, key_text: String):
	self.skill_slot_node = slot_node
	self.keybind_text = key_text
	keybind_label.text = key_text
#endregion

#region 매 프레임 업데이트
func _process(_delta):
	if not is_instance_valid(skill_slot_node) or skill_slot_node.get_child_count() == 0:
		_clear_display()
		return

	var skill = skill_slot_node.get_child(0) as BaseSkill
	if not is_instance_valid(skill):
		_clear_display()
		return

	icon_rect.texture = skill.skill_icon
	
	var time_left = skill.get_cooldown_time_left()
	var total_cooldown = skill.cooldown
	
	if time_left > 0:
		cooldown_label.visible = true
		cooldown_bar.visible = true
		
		cooldown_label.text = "%.1f" % time_left
		
		if total_cooldown > 0:
			cooldown_bar.value = (total_cooldown - time_left) / total_cooldown
		else:
			cooldown_bar.value = 1.0
		
		icon_rect.modulate = Color(0.5, 0.5, 0.5)
	else:
		_set_ready_display(skill.skill_icon)

#endregion

#region UI 상태 변경
func _clear_display():
	icon_rect.texture = null
	icon_rect.modulate = Color(0.2, 0.2, 0.2)
	cooldown_label.visible = false
	cooldown_bar.visible = false
	cooldown_bar.value = 0.0

func _set_ready_display(skill_icon: Texture):
	icon_rect.texture = skill_icon
	icon_rect.modulate = Color.WHITE
	cooldown_label.visible = false
	cooldown_bar.visible = false
	cooldown_bar.value = 0.0
#endregion
