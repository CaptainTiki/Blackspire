extends Node
class_name Interactable

## Thin interaction component.
## Add this under an object's "Components" node.
##
## Responsibilities (kept deliberately small per architecture):
## - Expose a prompt
## - Emit signals when focused / interacted
## - Forward interaction to the owning Entity (preferred) or fall back to legacy _perform_interaction
##
## Specific behavior (breakable, openable, etc.) should live in an Entity subclass
## on the root of the placed scene, not by subclassing Interactable.

signal focus_gained
signal focus_lost
signal interacted(actor: Node)

@export var prompt: String = "Interact"

## Called by the InteractionScanner when the player presses the interact button.
func interact(actor: Node) -> void:
	interacted.emit(actor)

	# Preferred path: forward to parent Entity if one exists
	var parent_entity := _find_parent_entity()
	if parent_entity:
		parent_entity._on_interact(self, actor)
		return

	# Legacy fallback (will be removed as we migrate)
	_perform_interaction(actor)


## Tries to find an Entity ancestor. This lets the thin Interactable component
## delegate real work to the root entity script.
func _find_parent_entity() -> Entity:
	var current := get_parent()
	while current:
		if current is Entity:
			return current as Entity
		current = current.get_parent()
	return null


## Legacy hook for old subclasses. New code should not override this.
## Will be removed once all interactables are migrated to Entity + thin Interactable.
func _perform_interaction(_actor: Node) -> void:
	pass


## Initialization is now primarily handled by the owning Entity via Room.initialize().
## This remains for any component-level setup that doesn't need the full entity context.
func initialize(room: Room = null) -> void:
	pass

