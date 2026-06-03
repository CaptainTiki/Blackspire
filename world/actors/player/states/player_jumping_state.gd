extends "res://world/actors/player/player_base_state.gd"
class_name PlayerJumpingState


func _on_jumping_state_physics_processing(_delta: float) -> void:
	if player_controller.input_reader.is_sprint_pressed():
		player_controller.sprint()
	else:
		player_controller.run()


func _on_jumping_state_entered() -> void:
	if player_controller.consume_jump_launch_request():
		player_controller.jump()
