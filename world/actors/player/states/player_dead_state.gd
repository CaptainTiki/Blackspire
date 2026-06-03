extends "res://world/actors/player/player_base_state.gd"
class_name PlayerDeadState


func _on_dead_state_entered() -> void:
	player_controller.life_state.enter_dead()
	player_controller.enter_dead_state()
