@tool
extends Entity
class_name SwingDoor

## Minimal swinging door base.
## Handles consistent push-to-open / consistent close behavior using four animations
## (open_a/b + close_a/b). Side is determined by player facing so the door always
## swings away when opening, and closes using the original swing direction.

signal door_opened
signal door_closed

var is_open := false
var is_animating := false

## Whether the player can directly open/close this door.
## Levers and other activators can enable this at runtime.
@export var player_operated := true

## Name used by mappers in TrenchBroom to target this door from levers etc.
@export var targetname: StringName = ""

## Optional identifier used by levers and other activators to target this door.
@export var door_id: StringName = ""

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	if targetname != "" or door_id != "":
		add_to_group("lever_targets")
		_register_with_level_registry()


func _func_godot_apply_properties(properties: Dictionary) -> void:
	if properties.has("targetname"):
		targetname = StringName(properties["targetname"])
	if properties.has("player_operated"):
		player_operated = _property_to_bool(properties["player_operated"])


func _register_with_level_registry() -> void:
	if not Level.current_level:
		push_error("SwingDoor %s could not register because there is no current Level." % get_path())
		return

	if not Level.current_level.entity_registry:
		push_error("SwingDoor %s could not register because the current Level has no entity registry." % get_path())
		return

	var name_to_use: StringName = targetname if targetname != "" else door_id
	if name_to_use != "":
		Level.current_level.entity_registry.register(name_to_use, self)


func unlock() -> void:
	player_operated = true

func lock() -> void:
	player_operated = false


func activate(actor: Node) -> void:
	_toggle_door(null, actor)


func _property_to_bool(value: Variant) -> bool:
	if value is bool:
		return value
	if value is int:
		return value != 0
	if value is String:
		return value == "1" or value.to_lower() == "true" or value.to_lower() == "yes"
	return false

# Stores which side the door was opened from (+1 or -1).
# Used so that closing always uses the matching animation.
var _open_side: int = 0


## Called by the Interactable component when the player interacts.
func _on_interact(interactable: Interactable, actor: Node) -> void:
	if not player_operated:
		print("This door cannot be operated by the player: ", name)
		return

	_toggle_door(interactable, actor)


func _toggle_door(interactable: Interactable, actor: Node) -> void:
	if is_animating:
		return

	is_animating = true

	var was_open := is_open
	is_open = !is_open

	var side: int
	if not was_open:
		# Opening now → record which side we opened from
		side = _get_side(actor)
		_open_side = side
	else:
		# Closing → always use the side we originally opened from
		side = _open_side

	var anim_name: String = _get_animation_name(is_open, side)

	$AnimationPlayer.play(anim_name)
	if interactable:
		interactable.prompt = "Close Door" if is_open else "Open Door"

	$AnimationPlayer.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)



## Returns +1 or -1 depending on which side of the door the actor is approaching from.
## Uses the player's facing direction so the door always swings away from them.
func _get_side(actor: Node) -> int:
	var player_forward: Vector3 = -actor.global_transform.basis.z.normalized()
	var door_forward: Vector3 = -global_transform.basis.z.normalized()   # tuned for this door setup

	var dot: float = player_forward.dot(door_forward)
	return 1 if dot > 0 else -1


func _get_animation_name(opening: bool, side: int) -> String:
	var letter := "a" if side > 0 else "b"
	return ("open_" if opening else "close_") + letter


func _on_animation_finished(_anim_name: StringName) -> void:
	is_animating = false
	if not is_open:
		_open_side = 0
