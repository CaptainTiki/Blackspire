extends Node
class_name EnemyState

## Base for all mirrored enemy state logic nodes (see enemy_state_machine.gd and StateChart).
## States should extend this by path (for load order) and implement:
##   _on_<state_name>_state_entered()
##   _on_<state_name>_state_physics_processing(_delta: float)
##   (optionally _on_<state_name>_state_exited() etc. as needed by the chart signals)

var enemy: Enemy


func _ready() -> void:
	var state_machine: Node = get_node_or_null("%StateMachine")
	if state_machine:
		enemy = state_machine.get("enemy")
