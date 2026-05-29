@tool
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
@export var targets: String = ""

var is_active := false
var has_been_used := false
var is_animating := false

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	if targetname != "":
		var registry: MapEntityRegistry = _get_entity_registry()
		if registry:
			registry.register(targetname, self)


func _func_godot_apply_properties(properties: Dictionary) -> void:
	if properties.has("targetname"):
		targetname = StringName(properties["targetname"])
	if properties.has("targets"):
		targets = str(properties["targets"])


func _on_interact(_interactable: Interactable, _actor: Node) -> void:
	if is_animating:
		return

	var was_active := is_active
	is_active = !is_active

	if is_active and not was_active:
		has_been_used = true
	# Note: Turning the lever off does NOT clear has_been_used

	is_animating = true
	animation_player.play("activate" if is_active else "deactivate")
	var activated_targets := _activate_targets(_actor)

	await animation_player.animation_finished
	await _wait_for_activated_targets(activated_targets)
	is_animating = false


func _activate_targets(actor: Node) -> Array[Node]:
	var activated_targets: Array[Node] = []
	var target_names := _get_target_names()
	if target_names.is_empty():
		return activated_targets

	var registry: MapEntityRegistry = _get_entity_registry()
	if not registry:
		return activated_targets

	for target_name in target_names:
		var node: Node = registry.get_entity(target_name)
		if node and node.has_method("activate"):
			node.activate(actor)
			activated_targets.append(node)
		elif node and node.has_method("unlock"):
			node.unlock()
			activated_targets.append(node)
		elif node:
			push_warning("Lever target '%s' does not have unlock() or activate()." % target_name)
		else:
			push_warning("Lever could not find target with name: %s" % target_name)

	return activated_targets


func _wait_for_activated_targets(activated_targets: Array[Node]) -> void:
	while _has_animating_target(activated_targets):
		await get_tree().process_frame


func _has_animating_target(activated_targets: Array[Node]) -> bool:
	for target in activated_targets:
		if target.get("is_animating") == true:
			return true
	return false


func _get_target_names() -> Array[StringName]:
	var result: Array[StringName] = []
	var normalized_targets := targets.replace(",", " ")
	for raw_name in normalized_targets.split(" ", false):
		result.append(StringName(raw_name))
	return result


func _get_entity_registry() -> MapEntityRegistry:
	if not Level.current_level:
		push_error("Lever %s could not resolve targets because there is no current Level." % get_path())
		return null

	if not Level.current_level.entity_registry:
		push_error("Lever %s could not resolve targets because the current Level has no entity registry." % get_path())
		return null

	return Level.current_level.entity_registry
