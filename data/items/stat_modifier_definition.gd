extends Resource
class_name StatModifierDefinition

enum StatType {
	ATTACK_DAMAGE,
	ARMOR,
	MAX_HEALTH,
	MOVE_SPEED,
	BACKPACK_SLOTS,
	HOTBAR_SLOTS,
	BLOCK,
}

@export var stat_type := StatType.ATTACK_DAMAGE
@export var value := 0.0


func applies_to(target_stat_type: int) -> bool:
	return stat_type == target_stat_type
