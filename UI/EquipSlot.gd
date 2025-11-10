# EquipSlot.gd
extends PanelContainer

#region 변수 및 시그널
@export var slot_index: int = 1

signal skill_dropped_on_slot(skill_path: String, slot_index: int)

var default_stylebox: StyleBoxFlat
var can_drop_stylebox: StyleBoxFlat
var type_mismatch_stylebox: StyleBoxFlat
#endregion

func _ready():
	# 기본 스타일
	default_stylebox = StyleBoxFlat.new()
	default_stylebox.bg_color = Color(0, 0, 0, 0)
	custom_minimum_size = Vector2(160, 160)
	
	# 드롭 가능 스타일
	can_drop_stylebox = StyleBoxFlat.new()
	can_drop_stylebox.bg_color = Color(0.1, 1, 0.1, 0.3)
	can_drop_stylebox.set_border_width_all(2)
	can_drop_stylebox.border_color = Color.WHITE
	
	# 타입 불일치 스타일
	type_mismatch_stylebox = StyleBoxFlat.new()
	type_mismatch_stylebox.bg_color = Color(1, 0.1, 0.1, 0.3)
	type_mismatch_stylebox.set_border_width_all(2)
	type_mismatch_stylebox.border_color = Color.RED
	
	add_theme_stylebox_override("panel", default_stylebox)
	clear_skill_display()


#region 드래그 앤 드롭
func _can_drop_data(at_position, data) -> bool:
	# "skill" 타입 데이터만 허용
	var can_drop = (data is Dictionary and data.has("type") and data.type == "skill")
	if not can_drop:
		return false
		
	# 타입 일치 여부 확인 및 시각적 피드백
	if data.has("skill_type_int") and data.skill_type_int == slot_index:
		add_theme_stylebox_override("panel", can_drop_stylebox)
		return true
	else:
		add_theme_stylebox_override("panel", type_mismatch_stylebox)
		return true

func _notification(what):
	# 스타일 초기화
	if what == NOTIFICATION_DRAG_END or what == NOTIFICATION_MOUSE_EXIT:
		add_theme_stylebox_override("panel", default_stylebox)

func _drop_data(at_position, data):
	add_theme_stylebox_override("panel", default_stylebox)
	
	# 타입 일치 시 장착 시그널 발생
	if data.has("skill_type_int") and data.skill_type_int == slot_index:
		emit_signal("skill_dropped_on_slot", data.path, slot_index)
	else:
		print("UI: 타입 불일치로 장착이 거부되었습니다.")

func _get_drag_data(at_position):
	# 장착 해제 드래그 데이터 설정
	if $VBoxContainer/Icon.texture != null:
		var drag_data = {
			"type": "equipped_skill", # 장착 해제용 데이터 타입입니다.
			"slot_index_from": slot_index
		}
		
		# 드래그 시 마우스 커서에 표시될 미리보기 이미지를 생성합니다.
		var preview = TextureRect.new()
		preview.texture = $VBoxContainer/Icon.texture
		preview.custom_minimum_size = Vector2(128, 128)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		set_drag_preview(preview)
		return drag_data
	
	return null
#endregion

#region UI 업데이트
func set_skill_display(icon: Texture, name: String, description: String):
	# 스킬 정보 표시
	$VBoxContainer/NameLabel.text = name
	$VBoxContainer/Icon.texture = icon
	self.tooltip_text = description

func clear_skill_display():
	# 슬롯 비우기
	$VBoxContainer/NameLabel.text = "[Slot " + str(slot_index) + "]"
	$VBoxContainer/Icon.texture = null
	self.tooltip_text = "비어있는 슬롯"
#endregion