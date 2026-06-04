extends "res://world/actors/player/player_base_state.gd"
class_name PlayerReadyState


func _on_ready_state_physics_processing(_delta: float) -> void:
	if player_controller.input_reader.is_secondary_action_pressed():
		if player_controller.can_block():
			player_controller.state_chart.send_event(&"onBlock")
			return

	if player_controller.input_reader.is_primary_action_just_pressed():
		if not player_controller.can_primary_attack():
			return

		player_controller.state_chart.send_event(&"onPrimaryAttack")
		return

	if not player_controller.input_reader.is_interact_just_pressed():
		return

	match player_controller.get_interaction_action_kind():
		InteractionScanner.INTERACTION_REVIVE:
			player_controller.state_chart.send_event(&"onRevive")
		InteractionScanner.INTERACTION_EXTRACT:
			player_controller.state_chart.send_event(&"onExtract")
		InteractionScanner.INTERACTION_INTERACT:
			player_controller.state_chart.send_event(&"onInteract")
