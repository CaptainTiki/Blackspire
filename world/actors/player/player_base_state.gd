extends Node
class_name PlayerState

var player_controller : PlayerController

func _ready() -> void:
	var state_machine := get_node_or_null("%StateMachine")
	if state_machine:
		player_controller = state_machine.get("player_controller")
