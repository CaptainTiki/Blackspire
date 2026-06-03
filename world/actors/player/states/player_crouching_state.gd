extends "res://world/actors/player/player_base_state.gd"
class_name PlayerCrouchingState


func _on_crouching_state_physics_processing(delta: float) -> void:
	player_controller.update_camera_height(delta, -1.0)

	if not player_controller.input_reader.is_crouch_pressed() and player_controller.can_stand():
		player_controller.state_chart.send_event("onStanding")

func _on_crouching_state_entered() -> void:
	player_controller.crouch()
