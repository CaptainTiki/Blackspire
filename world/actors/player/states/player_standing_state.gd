extends PlayerState
class_name PlayerStandingState


func _on_standing_state_physics_processing(delta: float) -> void:
	player_controller.update_camera_height(delta, 1.0)
	
	if player_controller.input_reader.is_crouch_pressed() and player_controller.is_on_floor():
		player_controller.state_chart.send_event("onCrouching")


func _on_standing_state_entered() -> void:
	player_controller.stand()
