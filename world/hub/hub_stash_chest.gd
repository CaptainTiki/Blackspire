@tool
extends Entity
class_name HubStashChest

@export var prompt := "Open Stash"
@export var placeholder_message := "Stash placeholder ready"

@onready var interactable: Interactable = $Components/Interactable
@onready var label: Label3D = $Label3D


func _ready() -> void:
	_apply_display_state()


func _on_interact(_interactable: Interactable, actor: Node) -> void:
	var player := actor as PlayerController
	if not player:
		push_error("HubStashChest %s can only be used by a PlayerController." % get_path())
		return

	if player.inventory:
		player.inventory.inventory_toast.emit(placeholder_message)


func _apply_display_state() -> void:
	interactable.prompt = prompt
	label.text = "STASH"
