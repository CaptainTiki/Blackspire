extends "res://world/actors/enemies/enemy_base_state.gd"
class_name EnemyAliveState


func _on_alive_state_entered() -> void:
	if enemy:
		enemy.set_debug_state("ALIVE")
		# Behavior branch (parallel) handles AI while we are Alive.
