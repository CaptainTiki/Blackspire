extends Node
class_name MapEntityRegistry

## Central registry for entities placed via TrenchBroom / FuncGodot.
## Entities register themselves with a targetname (StringName).
## Levers and other activators can then look up live nodes by targetname.

var _entities: Dictionary[StringName, Node] = {}


func register(targetname: StringName, node: Node) -> void:
	if targetname == "":
		return

	if _entities.has(targetname):
		push_warning("MapEntityRegistry: Duplicate targetname '%s' registered. Overwriting." % targetname)

	_entities[targetname] = node


func unregister(targetname: StringName) -> void:
	_entities.erase(targetname)


func get_entity(targetname: StringName) -> Node:
	return _entities.get(targetname)


func get_entities(targetnames: Array[StringName]) -> Array[Node]:
	var result: Array[Node] = []
	for name in targetnames:
		var node: Node = _entities.get(name)
		if node:
			result.append(node)
	return result
