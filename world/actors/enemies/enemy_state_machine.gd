extends Node
class_name EnemyStateMachine

## Mirrored state machine for enemies. Lives alongside the StateChart in the scene.
## Provides:
## - Debug label support (active states)
## - Expression properties pushed to the chart every frame (for guards if used)
## - Clean lookup of current leaf states per branch
##
## States extend EnemyState and live in a parallel tree under this node (see slime.tscn).

@export var debug: bool = false
@export_category("References")
@export var enemy: Enemy
@export var debug_label: Label3D

const STATE_BRANCH_PATHS: Dictionary = {
	"Life": [
		"Root/Life/Deploying",
		"Root/Life/Alive",
		"Root/Life/Dying",
		"Root/Life/Dead",
	],
	"Movement": [
		"Root/Movement/Idle",
		"Root/Movement/Chase",
	],
	"Action": [
		"Root/Action/Ready",
		"Root/Action/Windup",
		"Root/Action/Lunge",
		"Root/Action/Recover",
		"Root/Action/Hurt",
	],
}


func _ready() -> void:
	if debug_label:
		debug_label.visible = debug
		debug_label.text = ""


func _process(_delta: float) -> void:
	if not enemy or not enemy.state_chart:
		return

	if enemy.has_valid_target():
		enemy.state_chart.set_expression_property(&"Enemy Distance", enemy.distance_to_target())
	else:
		enemy.state_chart.set_expression_property(&"Enemy Distance", INF)

	enemy.state_chart.set_expression_property(&"Enemy Has Target", enemy.has_valid_target())
	enemy.state_chart.set_expression_property(&"Enemy Is Authority", enemy.is_network_authority)

	_update_debug_label()


func _update_debug_label() -> void:
	if not debug_label:
		return
	debug_label.visible = debug
	if not debug:
		return
	debug_label.text = get_active_state_debug_text()


func get_active_state_debug_text() -> String:
	if not enemy or not enemy.state_chart:
		return ""
	var lines: Array[String] = []
	for branch_name in STATE_BRANCH_PATHS.keys():
		lines.append("%s: %s" % [branch_name, _get_active_state_name(STATE_BRANCH_PATHS[branch_name])])
	return "\n".join(lines)


func _get_active_state_name(state_paths: Array) -> String:
	for state_path in state_paths:
		var state: StateChartState = enemy.state_chart.get_node_or_null(state_path) as StateChartState
		if state and state.active:
			return state.name
	return "-"
