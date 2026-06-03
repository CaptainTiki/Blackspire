extends "res://world/actors/player/player_base_state.gd"
class_name PlayerGroundedState


func _on_grounded_state_physics_processing(_delta: float) -> void:
	if player_controller.input_reader.is_jump_just_pressed() and player_controller.is_on_floor():
		player_controller.request_jump_launch()
		player_controller.state_chart.send_event("onAirborne")
	
	if not player_controller.is_on_floor():
		player_controller.state_chart.send_event("onAirborne")
