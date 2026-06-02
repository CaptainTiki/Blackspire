extends PlayerState
class_name PlayerDownedState


func _on_downed_state_entered() -> void:
	player_controller.life_state.enter_downed()
	player_controller.enter_bleeding_out_state()
