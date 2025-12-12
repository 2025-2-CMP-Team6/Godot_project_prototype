# SkillCard.gd
extends PanelContainer
class_name SkillCard

#region 변수
var skill_instance: SkillInstance

var skill_icon: Texture
var skill_name: String
var skill_description: String
var skill_type: int

var hover_stylebox: StyleBoxFlat
var default_stylebox: StyleBoxFlat
#endregion

#region UI 설정
func _ready():
	hover_stylebox = StyleBoxFlat.new()
	hover_stylebox.bg_color = Color(1, 1, 1, 0.15)
	hover_stylebox.set_corner_radius_all(4)

	default_stylebox = StyleBoxFlat.new()
	default_stylebox.bg_color = Color(0, 0, 0, 0)
	
	if default_stylebox:
		add_theme_stylebox_override("panel", default_stylebox)

func setup_card_ui():
	if not is_instance_valid(skill_instance):
		print("SkillCard 오류: SkillInstance가 없습니다.")
		return

	var skill_scene = load(skill_instance.skill_path)
	if not skill_scene:
		print("SkillCard 오류: 경로를 로드할 수 없음: " + skill_instance.skill_path)
		return
		
	var skill_template = skill_scene.instantiate() as BaseSkill
	if not is_instance_valid(skill_template):
		print("SkillCard 오류: BaseSkill이 아님: " + skill_instance.skill_path)
		return

	skill_icon = skill_template.skill_icon
	skill_name = skill_template.skill_name
	skill_description = skill_template.skill_description
	skill_type = skill_template.type
	
	tooltip_text = skill_description

	var vbox = get_node_or_null("VBoxContainer") as VBoxContainer
	if not is_instance_valid(vbox):
		vbox = VBoxContainer.new()
		vbox.name = "VBoxContainer"
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		add_child(vbox)

	var icon = vbox.get_node_or_null("Icon") as TextureRect
	if not is_instance_valid(icon):
		icon = TextureRect.new()
		icon.name = "Icon"
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(128, 128)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		vbox.add_child(icon)
	
	icon.texture = skill_icon
	
	var name_label = vbox.get_node_or_null("NameLabel") as Label
	if not is_instance_valid(name_label):
		name_label = Label.new()
		name_label.name = "NameLabel"
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.custom_minimum_size = Vector2(160, 0)
		vbox.add_child(name_label)

	if skill_instance.level > 0:
		name_label.text = skill_name + " + " + str(skill_instance.level)
	else:
		name_label.text = skill_name
	
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)
	
	skill_template.queue_free()
	
	if default_stylebox:
		add_theme_stylebox_override("panel", default_stylebox)
#endregion

#region 툴팁
func _make_custom_tooltip(_for_text):
	var scene = load("res://UI/SkillSelect.tscn")
	if not scene:
		return null
		
	var tooltip = scene.instantiate()
	
	var icon_node = tooltip.get_node_or_null("icon")
	var name_node = tooltip.get_node_or_null("name")
	var text_node = tooltip.get_node_or_null("text")
	
	if icon_node:
		if icon_node is TextureRect:
			icon_node.texture = skill_icon
			icon_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		elif icon_node is Sprite2D:
			icon_node.texture = skill_icon
			
	if name_node is Label:
		if skill_instance and skill_instance.level > 0:
			name_node.text = skill_name + " + " + str(skill_instance.level)
		else:
			name_node.text = skill_name
			
	if text_node is Label:
		text_node.text = skill_description
		
	return tooltip
#endregion

#region 드래그 앤 드롭
func _get_drag_data(at_position):
	var drag_data = {
		"type": "skill_instance",
		"instance": skill_instance,
		"skill_type_int": skill_type
	}
	
	var preview = TextureRect.new()
	preview.texture = skill_icon
	preview.custom_minimum_size = Vector2(128, 128)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	set_drag_preview(preview)
	return drag_data
#endregion

#region 호버 효과
func _on_mouse_entered():
	if hover_stylebox:
		add_theme_stylebox_override("panel", hover_stylebox)

func _on_mouse_exited():
	if default_stylebox:
		add_theme_stylebox_override("panel", default_stylebox)
#endregion
