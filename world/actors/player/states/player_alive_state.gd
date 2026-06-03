extends "res://world/actors/player/player_base_state.gd"
class_name PlayerAliveState


func _on_alive_state_entered() -> void:
	player_controller.life_state.enter_alive()
