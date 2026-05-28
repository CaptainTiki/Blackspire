extends Entity
class_name Lever

## Basic lever for activating other entities (doors, etc.) via targetnames set in TrenchBroom.
##
## State rules:
## - is_active:     Current physical state of the lever (on/off).
## - has_been_used: Becomes true the first time the lever is turned on.
##                  Stays true forever, even if the lever is turned back off.
##                  Useful for one-shot levers or tracking progress.

@export var targetname: StringName = ""
@export var targets: Array[StringName] = []

var is_active := false
var has_been_used := false


func _ready() -> void:
	if targetname != "":
		var registry: MapEntityRegistry = _find_registry()
		if registry:
			registry.register(targetname, self)


func _on_interact(_interactable: Interactable, _actor: Node) -> void:
	# Toggle the lever
	var was_active := is_active
	is_active = !is_active

	if is_active and not was_active:
		has_been_used = true
		_activate_targets()
	# Note: Turning the lever off does NOT clear has_been_used


func _activate_targets() -> void:
	if targets.is_empty():
		return

	var registry: MapEntityRegistry = _find_registry()
	if not registry:
		push_error("Lever %s could not find a MapEntityRegistry to resolve targets." % name)
		return

	for target_name in targets:
		var node: Node = registry.get_entity(target_name)
		if node and node.has_method("unlock"):
			node.unlock()
		elif node and node.has_method("activate"):
			node.activate()
		elif node:
			push_warning("Lever target '%s' does not have unlock() or activate()." % target_name)
		else:
			push_warning("Lever could not find target with name: %s" % target_name)


func _find_registry() -> MapEntityRegistry:
	var current := get_owner()
	while current:
		if current.has_method("get_map_entity_registry"):
			var reg: MapEntityRegistry = current.get_map_entity_registry()
			if reg:
				return reg
		current = current.get_owner()
	return null
