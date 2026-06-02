extends PlayerState
class_name PlayerPrimaryAttackState

var _attack_finished_connected := false


func _ready() -> void:
	super()
	call_deferred("_connect_attack_finished_signal")


func _on_primary_attack_state_entered() -> void:
	_connect_attack_finished_signal()

	if not player_controller.primary_attack():
		player_controller.state_chart.send_event(&"onReady")


func _connect_attack_finished_signal() -> void:
	if _attack_finished_connected:
		return
	if not player_controller or not player_controller.melee_attack:
		return

	if not player_controller.melee_attack.attack_finished.is_connected(_on_attack_finished):
		player_controller.melee_attack.attack_finished.connect(_on_attack_finished)
	_attack_finished_connected = true


func _on_attack_finished(player: PlayerController) -> void:
	if player != player_controller:
		return

	player_controller.state_chart.send_event(&"onReady")
