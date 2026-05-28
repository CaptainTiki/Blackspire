extends Entity
class_name BreakableUrn

@export var debris_scene: PackedScene
@export var debris_count: int = 5
@export var debris_impulse_strength: float = 2.5
@export var debris_lifetime: float = 60.0

var _is_broken: bool = false


func _get_junk_container() -> Node3D:
	var room := self.owner as Room
	if not room:
		push_error("BreakableUrn %s could not resolve owning Room via .owner. This should never happen in a properly set up scene." % get_path())
		return null
	return room.get_junk_container()

## Called by the thin Interactable component when the player interacts.
func _on_interact(_interactable: Interactable, _actor: Node) -> void:
	if _is_broken:
		return
	_is_broken = true
	_spawn_debris()
	queue_free()

func _spawn_debris() -> void:
	var container := _get_junk_container()
	if not container:
		push_error("BreakableUrn %s could not find junk container. Debris will not spawn." % get_path())
		# Still break the urn so the player gets visual feedback
		queue_free()
		return

	for i in range(debris_count):
		var debris := debris_scene.instantiate() as UrnDebris
		debris.time_to_live = debris_lifetime
		container.add_child(debris)

		debris.global_position = global_position + Vector3(
			randf_range(-0.3, 0.3),
			randf_range(0.2, 0.6),
			randf_range(-0.3, 0.3)
		)

		var impulse := Vector3(
			randf_range(-1.0, 1.0),
			randf_range(0.8, 1.8),
			randf_range(-1.0, 1.0)
		).normalized() * debris_impulse_strength

		debris.apply_impulse(impulse)
