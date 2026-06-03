extends "res://world/actors/player/player_base_state.gd"
class_name PlayerDeployingState


func _on_deploying_state_entered() -> void:
	player_controller.life_state.enter_deploying()
	player_controller.life_state.complete_deploying.call_deferred()
