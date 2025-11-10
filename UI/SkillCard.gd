# SkillCard.gd
extends PanelContainer

#region 변수
var skill_path: String
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
	
	setup_card_ui()


func setup_card_ui():
	tooltip_text = skill_description
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(vbox)
	
	var icon = TextureRect.new()
	icon.texture = skill_icon
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(128, 128)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	var name_label = Label.new()
	name_label.text = skill_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size = Vector2(160, 0)
	
	vbox.add_child(icon)
	vbox.add_child(name_label)
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	if default_stylebox:
		add_theme_stylebox_override("panel", default_stylebox)

#endregion

#region 드래그 앤 드롭
func _get_drag_data(at_position):
	var drag_data = {
		"type": "skill",
		"path": skill_path,
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