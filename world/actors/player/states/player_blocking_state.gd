extends "res://world/actors/player/player_base_state.gd"
class_name PlayerBlockingState


func _on_blocking_state_entered() -> void:
	if player_controller:
		player_controller.start_block()
	# If start failed for some reason (e.g. lost item), bail back to ready.
	if player_controller and not player_controller.is_blocking():
		player_controller.state_chart.send_event(&"onReady")

func _on_blocking_state_physics_processing(_delta: float) -> void:
	if not player_controller or not player_controller.input_reader:
		player_controller.state_chart.send_event(&"onReady")
		return

	if not player_controller.input_reader.is_secondary_action_pressed() or not player_controller.can_act():
		player_controller.state_chart.send_event(&"onReady")
		return

func _on_blocking_state_exited() -> void:
	if player_controller:
		player_controller.stop_block()
