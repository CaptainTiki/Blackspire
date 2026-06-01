extends Node3D
class_name Hub

signal deploy_requested(actor: PlayerController)

@export var hub_name := "Prototype Hub"

@onready var summary_label: Label3D = $SummaryBoard/SummaryLabel


func _ready() -> void:
	show_run_summary("No run completed yet")


func get_player_spawns() -> Array[Marker3D]:
	var spawns: Array[Marker3D] = []
	_find_player_spawns_recursive(self, spawns)
	return spawns


func request_deploy(actor: PlayerController) -> void:
	deploy_requested.emit(actor)


func show_run_summary(summary: String) -> void:
	if not summary_label:
		return

	summary_label.text = "LAST RUN\n%s" % summary


func _find_player_spawns_recursive(node: Node, results: Array[Marker3D]) -> void:
	for child in node.get_children():
		var child_name := child.name.to_lower()
		if child is Marker3D and ("player_start" in child_name or "playerstart" in child_name):
			results.append(child)
		_find_player_spawns_recursive(child, results)
