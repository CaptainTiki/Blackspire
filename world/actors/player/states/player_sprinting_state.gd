extends PlayerState
class_name PlayerSprintingState


func _on_sprinting_state_physics_processing(_delta: float) -> void:
	if not player_controller.input_reader.is_sprint_pressed():
		player_controller.state_chart.send_event("onRunning")

func _on_sprinting_state_entered() -> void:
	player_controller.sprint()
