extends Interactable
class_name BreakableUrn

## First interactable example: A breakable urn that spawns physics debris.

@export var debris_scene: PackedScene
@export var debris_count: int = 5
@export var debris_impulse_strength: float = 2.5
@export var debris_lifetime: float = 60.0  # seconds before fading out

@export var junk_container_path: NodePath  # Should point to a node in the level for organization

var _is_broken: bool = false

func _perform_interaction(_actor: Node) -> void:
	if _is_broken:
		return
	
	_is_broken = true
	_spawn_debris()
	
	# Hide the intact urn mesh
	var parent = get_parent()
	if parent is Node3D:
		parent.visible = false
		# Disable collision on the parent if it has any
		for child in parent.get_children():
			if child is CollisionObject3D:
				child.disabled = true

func _spawn_debris() -> void:
	if not debris_scene:
		push_error("BreakableUrn: No debris_scene assigned on %s" % get_path())
		return
	
	# Strict resolution - no fallbacks. If the level isn't set up correctly, we want to know.
	var container: Node3D = null
	if junk_container_path:
		container = get_node_or_null(junk_container_path) as Node3D
	
	if not container:
		push_error("BreakableUrn: Could not find junk container at path '%s' on %s. Debris will not spawn." % [junk_container_path, get_path()])
		return
	
	var root = get_owner() as Node3D
	if not root:
		push_error("BreakableUrn: Could not find valid root Node3D on %s. Debris will not spawn." % get_path())
		return
	
	for i in range(debris_count):
		var debris = debris_scene.instantiate() as RigidBody3D
		if not debris:
			push_error("BreakableUrn: debris_scene did not instantiate a RigidBody3D.")
			continue
		
		container.add_child(debris)
		
		# Position near the urn
		debris.global_position = root.global_position + Vector3(
			randf_range(-0.3, 0.3),
			randf_range(0.2, 0.6),
			randf_range(-0.3, 0.3)
		)
		
		var impulse = Vector3(
			randf_range(-1.0, 1.0),
			randf_range(0.8, 1.8),  # mostly upward
			randf_range(-1.0, 1.0)
		).normalized() * debris_impulse_strength
		
		debris.apply_impulse(impulse)
		
		# Add lifetime timer
		_add_lifetime_timer(debris)

func _add_lifetime_timer(debris: Node) -> void:
	var timer = Timer.new()
	timer.wait_time = debris_lifetime
	timer.one_shot = true
	timer.autostart = true
	debris.add_child(timer)
	
	timer.timeout.connect(func():
		if is_instance_valid(debris):
			# Simple fade out (can be improved later with a tween or shader)
			var tween = create_tween()
			tween.tween_property(debris, "modulate:a", 0.0, 1.5)
			tween.finished.connect(debris.queue_free)
	)
