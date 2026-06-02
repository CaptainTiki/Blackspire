extends PlayerState
class_name PlayerReadyState


func _on_ready_state_physics_processing(_delta: float) -> void:
	if not player_controller.input_reader.is_primary_action_just_pressed():
		return
	if not player_controller.can_primary_attack():
		return

	player_controller.state_chart.send_event(&"onPrimaryAttack")
