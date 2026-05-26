extends Node3D
class_name Room

## Base class for all rooms.
## Handles post-spawn initialization of entities inside the FuncGodotMap.

func _ready() -> void:
	_initialize_entities()


func _initialize_entities() -> void:
	var map := $FuncGodotMap
	if not map:
		push_warning("Room: No FuncGodotMap child found in %s" % name)
		return

	for child in map.get_children():
		if child.has_method("initialize"):
			child.initialize()
