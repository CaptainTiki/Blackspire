extends "res://world/actors/enemies/enemy_base_state.gd"
class_name EnemyDeployingState


func _on_deploying_state_entered() -> void:
	if enemy:
		enemy.set_debug_state("DEPLOYING")
	# Auto-complete deploy immediately (for now). Future versions can wait for
	# network handshakes, animations, etc. before sending onAlive.
	if is_instance_valid(enemy) and is_instance_valid(enemy.state_chart):
		enemy.state_chart.send_event.call_deferred(&"onAlive")
