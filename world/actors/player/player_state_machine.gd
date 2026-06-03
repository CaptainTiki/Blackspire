extends Node
class_name PlayerStateMachine

@export var debug : bool = false
@export_category("References")
@export var player_controller : PlayerController
@export var debug_label: Label3D

const STATE_BRANCH_PATHS := {
	"Movement": [
		"Root/Movement/Grounded/Idle",
		"Root/Movement/Grounded/Moving/Running",
		"Root/Movement/Grounded/Moving/Sprinting",
		"Root/Movement/Airborne/Jumping",
	],
	"Posture": [
		"Root/Posture/Standing",
		"Root/Posture/Crouching",
	],
	"Life": [
		"Root/Life/Deploying",
		"Root/Life/Alive",
		"Root/Life/Downed",
		"Root/Life/Dead",
	],
	"Action": [
		"Root/Action/Ready",
		"Root/Action/PrimaryAttack",
		"Root/Action/Interact",
		"Root/Action/Revive",
		"Root/Action/Extract",
	],
}


func _ready() -> void:
	if debug_label:
		debug_label.visible = debug
		debug_label.text = ""


func _process(_delta : float ) -> void:
	if not player_controller or not player_controller.state_chart:
		return

	player_controller.state_chart.set_expression_property(&"Player Velocity", player_controller.velocity)
	player_controller.state_chart.set_expression_property(&"Player Hitting Head", player_controller.is_head_blocked())
	player_controller.state_chart.set_expression_property(&"Looking At", player_controller.get_current_interaction_target())
	_update_debug_label()


func _update_debug_label() -> void:
	if not debug_label:
		return

	debug_label.visible = debug
	if not debug:
		return

	debug_label.text = get_active_state_debug_text()


func get_active_state_debug_text() -> String:
	if not player_controller or not player_controller.state_chart:
		return ""

	var lines: Array[String] = []
	for branch_name in STATE_BRANCH_PATHS.keys():
		lines.append("%s: %s" % [branch_name, _get_active_state_name(STATE_BRANCH_PATHS[branch_name])])

	return "\n".join(lines)


func _get_active_state_name(state_paths: Array) -> String:
	for state_path in state_paths:
		var state := player_controller.state_chart.get_node_or_null(state_path) as StateChartState
		if state and state.active:
			return state.name

	return "-"
