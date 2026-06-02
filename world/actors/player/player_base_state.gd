extends Node
class_name PlayerState

var player_controller : PlayerController

func _ready() -> void:
	if %StateMachine and %StateMachine is PlayerStateMachine:
		player_controller = %StateMachine.player_controller
