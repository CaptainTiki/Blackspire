extends "res://world/actors/enemies/enemy_base_state.gd"
class_name EnemyHurtState


func _on_hurt_state_entered() -> void:
	if enemy:
		enemy.set_is_attacking(true)
		enemy.stop_horizontal_movement()
		enemy.play_animation(&"hurt")
		enemy.set_debug_state("HURT")
		# Short hurt reaction then return to chase or idle
		call_deferred("_return_to_combat")


func _return_to_combat() -> void:
	if not is_instance_valid(enemy) or not is_instance_valid(enemy.state_chart) or enemy.is_dead:
		return
	enemy.update_target()
	# Exit the Hurt in Action branch
	enemy.state_chart.send_event.call_deferred(&"onReady")
	if enemy.has_valid_target():
		enemy.state_chart.send_event.call_deferred(&"onChase")
	else:
		enemy.state_chart.send_event.call_deferred(&"onIdle")
