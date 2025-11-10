# ui/InventoryDropArea.gd
extends ScrollContainer

signal skill_unequipped(slot_index: int)

# 스킬 장착 가능 여부
func _can_drop_data(_at_position, data) -> bool:
	return (data is Dictionary and data.has("type") and data.type == "equipped_skill")

# 마우스 뗄때 호출
func _drop_data(_at_position, data):
	print("장착 해제 드롭 감지: " + str(data.slot_index_from) + "번 슬롯")
	emit_signal("skill_unequipped", data.slot_index_from)