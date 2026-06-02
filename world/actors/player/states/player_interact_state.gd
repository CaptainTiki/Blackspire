extends PlayerState
class_name PlayerInteractState


func _on_interact_state_entered() -> void:
	player_controller.interact()
	call_deferred("_return_to_ready")


func _return_to_ready() -> void:
	if not is_instance_valid(player_controller) or not is_instance_valid(player_controller.state_chart):
		return

	player_controller.state_chart.send_event(&"onReady")
