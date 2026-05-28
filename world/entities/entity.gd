# world/entities/entity.gd
#
# Base class for gameplay entities that are placed in the world (props, interactables,
# doors, levers, chests, etc.).
#
# These are distinct from Actors (which have health, combat, targeting, etc.).
#
# Actual behavior is preferred via composition (Components nodes).

extends Node3D
class_name Entity


func on_interacted(_interactable: Interactable, _actor: Node) -> void:
	pass
