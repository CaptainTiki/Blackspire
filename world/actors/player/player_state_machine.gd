extends Node
class_name PlayerStateMachine

@export var debug : bool = false
@export_category("References")
@export var player_controller : PlayerController

func _process(_delta : float ) -> void:
	if not player_controller or not player_controller.state_chart:
		return

	player_controller.state_chart.set_expression_property(&"Player Velocity", player_controller.velocity)
	player_controller.state_chart.set_expression_property(&"Player Hitting Head", player_controller.is_head_blocked())
	player_controller.state_chart.set_expression_property(&"Looking At", player_controller.get_current_interaction_target())
