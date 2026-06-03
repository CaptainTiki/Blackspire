extends "res://world/actors/enemies/enemy_base_state.gd"
class_name EnemyWindupState

var _windup_timer: float = 0.0


func _on_windup_state_entered() -> void:
	if not enemy:
		return
	enemy.set_is_attacking(true)
	_windup_timer = enemy.attack_windup
	enemy.stop_horizontal_movement()
	enemy.face_target()
	if enemy.has_valid_target():
		enemy.play_attack_tell(enemy.target)
	enemy.set_debug_state("WINDUP")


func _on_windup_state_physics_processing(delta: float) -> void:
	if not enemy or not enemy.is_network_authority or enemy.is_dead:
		return

	_windup_timer = maxf(_windup_timer - delta, 0.0)
	enemy.stop_horizontal_movement()
	enemy.move_with_gravity(delta)

	if enemy.has_valid_target():
		enemy.face_target()

	if _windup_timer <= 0.0:
		enemy.state_chart.send_event.call_deferred(&"onLunge")
