extends "res://world/actors/player/player_base_state.gd"
class_name PlayerExtractState


func _on_extract_state_entered() -> void:
	player_controller.extract_interaction()
	call_deferred("_return_to_ready")


func _return_to_ready() -> void:
	if not is_instance_valid(player_controller) or not is_instance_valid(player_controller.state_chart):
		return

	player_controller.state_chart.send_event(&"onReady")
