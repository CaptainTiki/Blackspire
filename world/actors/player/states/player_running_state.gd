extends "res://world/actors/player/player_base_state.gd"
class_name PlayerRunningState


func _on_running_state_physics_processing(_delta: float) -> void:
	if player_controller.input_reader.is_sprint_pressed():
		player_controller.state_chart.send_event("onSprinting")


func _on_running_state_entered() -> void:
	player_controller.run()
