# EquipSlot.gd
extends PanelContainer

#region 변수 및 시그널
@export var slot_index: int = 1

# ★ (수정) String이 아닌 'SkillInstance'를 전달하도록 시그널 변경
# (이전 7-파일 패치에서 이미 적용되었어야 함)
signal skill_dropped_on_slot(skill_instance: SkillInstance, slot_index: int)

var default_stylebox: StyleBoxFlat
var can_drop_stylebox: StyleBoxFlat
var type_mismatch_stylebox: StyleBoxFlat

# (추가) 노드 참조
@onready var icon_rect: TextureRect = $VBoxContainer/Icon
@onready var name_label: Label = $VBoxContainer/NameLabel
#endregion

func _ready():
	# (기존 스타일 설정 코드는 동일...)
	default_stylebox = StyleBoxFlat.new()
	default_stylebox.bg_color = Color(0, 0, 0, 0)
	custom_minimum_size = Vector2(160, 160)
	can_drop_stylebox = StyleBoxFlat.new()
	can_drop_stylebox.bg_color = Color(0.1, 1, 0.1, 0.3)
	can_drop_stylebox.set_border_width_all(2)
	can_drop_stylebox.border_color = Color.WHITE
	type_mismatch_stylebox = StyleBoxFlat.new()
	type_mismatch_stylebox.bg_color = Color(1, 0.1, 0.1, 0.3)
	type_mismatch_stylebox.set_border_width_all(2)
	type_mismatch_stylebox.border_color = Color.RED
	add_theme_stylebox_override("panel", default_stylebox)
	
	if is_instance_valid(icon_rect):
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	clear_skill_display()


#region 드래그 앤 드롭
func _can_drop_data(at_position, data) -> bool:
	# ★ (수정) "skill_instance" 타입만 허용
	var can_drop = (data is Dictionary and data.has("type") and data.type == "skill_instance")
	if not can_drop:
		return false
		
	# -----------------------------------------------------------------
	# ★ (추가) slot_index가 0이면 (강화 슬롯), 타입 검사 없이 항상 허용
	# -----------------------------------------------------------------
	if slot_index == 0:
		add_theme_stylebox_override("panel", can_drop_stylebox)
		return true

	# (기존 로직)
	if data.has("skill_type_int") and data.skill_type_int == slot_index:
		add_theme_stylebox_override("panel", can_drop_stylebox)
		return true
	else:
		add_theme_stylebox_override("panel", type_mismatch_stylebox)
		return true

func _notification(what):
	if what == NOTIFICATION_DRAG_END or what == NOTIFICATION_MOUSE_EXIT:
		add_theme_stylebox_override("panel", default_stylebox)

func _drop_data(at_position, data):
	add_theme_stylebox_override("panel", default_stylebox)
	
	# -----------------------------------------------------------------
	# ★ (추가) slot_index가 0이면 (강화 슬롯), 타입 검사 없이 즉시 시그널 전송
	# -----------------------------------------------------------------
	if slot_index == 0:
		emit_signal("skill_dropped_on_slot", data.instance, slot_index)
		return

	# (기존 로직)
	if data.has("skill_type_int") and data.skill_type_int == slot_index:
		emit_signal("skill_dropped_on_slot", data.instance, slot_index)
	else:
		print("UI: 타입 불일치로 장착이 거부되었습니다.")

func _get_drag_data(at_position):
	if $VBoxContainer/Icon.texture != null:
		var drag_data = {
			"type": "equipped_skill",
			"slot_index_from": slot_index
		}
		var preview = TextureRect.new()
		preview.texture = $VBoxContainer/Icon.texture
		preview.custom_minimum_size = Vector2(128, 128)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_SCALE
		set_drag_preview(preview)
		return drag_data
	
	return null
#endregion

#region UI 업데이트
# (수정) 레벨도 표시하도록 함수 시그니처 변경
func set_skill_display(icon: Texture, name: String, description: String, level: int = 0):
	if level > 0:
		name_label.text = name + " + " + str(level)
	else:
		name_label.text = name
		
	icon_rect.texture = icon
	self.tooltip_text = description

func clear_skill_display():
	name_label.text = "[Slot " + str(slot_index) + "]"
	icon_rect.texture = null
	self.tooltip_text = "비어있는 슬롯"
#endregion