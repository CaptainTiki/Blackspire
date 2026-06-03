extends "res://world/actors/enemies/enemy_base_state.gd"
class_name EnemyDyingState


func _on_dying_state_entered() -> void:
	if enemy:
		enemy.set_debug_state("DYING")
		enemy.start_death_sequence()
		# The death_timer (started in start_death_sequence) will fire and send onDead.
