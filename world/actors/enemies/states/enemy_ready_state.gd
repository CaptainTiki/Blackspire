extends "res://world/actors/enemies/enemy_base_state.gd"
class_name EnemyReadyState


func _on_ready_state_entered() -> void:
	if enemy:
		enemy.set_is_attacking(false)
		# Debug label controlled by Movement branch when not attacking.
		# No velocity or anim here; Movement or other states handle when Ready.
