# Skill_Melee.gd
extends BaseSkill

# 'BaseSkill.gd'에 있는 'execute' 함수의 내용을 
# 이 스킬에 맞게 덮어씁니다.
func execute(owner: CharacterBody2D):
	
	print(owner.name + "가 " + skill_name + " 실행! (근접 공격 로직)")
	
	# ★★★
	# 바로 여기가 나중에 '히트박스'를 켜는 코드가 들어갈 자리입니다.
	# ★★★
