extends SceneTree


func _initialize() -> void:
	var paths := [
		"res://world/actors/enemies/states/enemy_alive_state.gd",
		"res://world/actors/enemies/states/enemy_dying_state.gd",
		"res://world/actors/enemies/states/enemy_ready_state.gd",
	]

	for path in paths:
		var uid := ResourceLoader.get_resource_uid(path)
		print("%s -> %s" % [path, ResourceUID.id_to_text(uid) if uid != ResourceUID.INVALID_ID else "<invalid>"])

	quit()
