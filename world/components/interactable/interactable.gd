extends Node
class_name Interactable

## Thin interaction component.
## Add this under an object's "Components" node.
##
## Responsibilities (kept deliberately small):
## - Expose a prompt
## - Emit focus signals
## - Forward interaction to the owning Entity
##
## The actual behavior lives in an Entity subclass on the root of the scene.

signal focus_gained
signal focus_lost
signal interacted(actor: Node)

@export var prompt: String = "Interact"


## Called by the InteractionScanner.
func interact(actor: Node) -> void:
	interacted.emit(actor)

	var entity := _find_parent_entity()
	if entity:
		entity._on_interact(self, actor)
	else:
		push_error("Interactable %s could not find a parent Entity to forward interaction to." % get_path())


## Walks up the tree to find the owning Entity.
## This keeps the Interactable component decoupled from exact scene structure.
func _find_parent_entity() -> Entity:
	var current := get_parent()
	while current:
		if current is Entity:
			return current as Entity
		current = current.get_parent()
	return null
