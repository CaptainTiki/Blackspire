extends Node
class_name Interactable

## Base interactable component.
## Add this under an object's "Components" node.

signal focus_gained
signal focus_lost
signal interacted(actor: Node)

@export var prompt: String = "Interact"

## Called by the InteractionScanner when the player presses the interact button.
func interact(actor: Node) -> void:
	interacted.emit(actor)
	_perform_interaction(actor)

## Override this in child scripts for specific behavior.
func _perform_interaction(_actor: Node) -> void:
	pass


## Called by the owning Room after the FuncGodotMap has finished building.
## Override in derived classes if the interactable needs any setup.
func initialize() -> void:
	pass
