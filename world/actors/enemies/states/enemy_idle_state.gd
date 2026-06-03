extends "res://world/actors/enemies/enemy_base_state.gd"
class_name EnemyIdleState


func _on_idle_state_entered() -> void:
	if enemy:
		enemy.stop_horizontal_movement()
		enemy.play_animation(&"idle")
		enemy.set_debug_state("IDLE")


func _on_idle_state_physics_processing(_delta: float) -> void:
	if not enemy or not enemy.is_network_authority or enemy.is_dead:
		return

	if enemy.is_attacking():
		# Let Action branch control during attacks.
		return

	enemy.update_target()
	enemy.stop_horizontal_movement()
	enemy.move_with_gravity(_delta)

	if enemy.has_valid_target() and enemy.distance_to_target() <= enemy.aggro_range:
		enemy.state_chart.send_event(&"onChase")
