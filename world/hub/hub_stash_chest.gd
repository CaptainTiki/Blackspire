@tool
extends Entity
class_name HubStashChest

@export var prompt := "Open Stash"

@onready var interactable: Interactable = $Components/Interactable
@onready var label: Label3D = $Label3D


func _ready() -> void:
	_apply_display_state()


func _on_interact(_interactable: Interactable, actor: Node) -> void:
	var player := actor as PlayerController
	if not player:
		push_error("HubStashChest %s can only be used by a PlayerController." % get_path())
		return

	var hub := _find_parent_hub()
	if not hub:
		push_error("HubStashChest %s could not find a parent Hub." % get_path())
		return

	hub.request_stash(player)


func _apply_display_state() -> void:
	interactable.prompt = prompt
	label.text = "STASH"


func _find_parent_hub() -> Node:
	var current := get_parent()
	while current:
		if current.has_method("request_stash"):
			return current
		current = current.get_parent()
	return null
