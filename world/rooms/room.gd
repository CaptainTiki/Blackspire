extends Node3D
class_name Room

## Base class for all rooms.

## Per-room junk container for temporary debris, particles, etc.
## Created on demand so we don't force every room to have one in the scene.
var _junk_container: Node3D = null


func get_junk_container() -> Node3D:
	if not _junk_container:
		_junk_container = Node3D.new()
		_junk_container.name = "Junk"
		add_child(_junk_container)
	return _junk_container
