extends "res://world/actors/enemies/enemy_base_state.gd"
class_name EnemyChaseState


func _on_chase_state_entered() -> void:
	if enemy:
		enemy.play_animation(&"move")
		enemy.set_debug_state("CHASE")


func _on_chase_state_physics_processing(delta: float) -> void:
	if not enemy or not enemy.is_network_authority or enemy.is_dead:
		return

	if enemy.is_attacking():
		# Let Action branch control velocity/movement during attacks (e.g. lunge, windup stop).
		return

	enemy.update_target()

	if not enemy.has_valid_target():
		enemy.state_chart.send_event(&"onIdle")
		return

	var dist: float = enemy.distance_to_target()
	if dist <= enemy.attack_range:
		enemy.state_chart.send_event(&"onWindup")
		return

	var dir: Vector3 = (enemy.target.global_position - enemy.global_position)
	enemy.face_target()
	enemy.apply_horizontal_velocity(dir, enemy.move_speed)
	enemy.move_with_gravity(delta)
