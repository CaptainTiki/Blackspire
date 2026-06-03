extends "res://world/actors/enemies/enemy_base_state.gd"
class_name EnemyDeadState


func _on_dead_state_entered() -> void:
	if enemy:
		enemy.stop_horizontal_movement()
		enemy.velocity = Vector3.ZERO
		# Animation "death" is already played from Enemy.die()
		enemy.set_debug_state("DEAD")
		# No further processing; decompose timer is in Enemy
