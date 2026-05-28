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
var is_locked := false

## Name used by mappers in TrenchBroom to target this door from levers etc.
@export var targetname: StringName = ""

## Optional identifier used by levers and other activators to target this door.
@export var door_id: StringName = ""

func _ready() -> void:
	if targetname != "" or door_id != "":
		add_to_group("lever_targets")
		_register_with_level_registry()


func _register_with_level_registry() -> void:
	var registry: MapEntityRegistry = _find_map_entity_registry()
	if registry:
		var name_to_use: StringName = targetname if targetname != "" else door_id
		if name_to_use != "":
			registry.register(name_to_use, self)


func _find_map_entity_registry() -> MapEntityRegistry:
	var current := get_owner()
	while current:
		if current.has_method("get_map_entity_registry"):
			var reg: MapEntityRegistry = current.get_map_entity_registry()
			if reg:
				return reg
		current = current.get_owner()
	return null


func unlock() -> void:
	is_locked = false

func lock() -> void:
	is_locked = true

# Stores which side the door was opened from (+1 or -1).
# Used so that closing always uses the matching animation.
var _open_side: int = 0


## Called by the Interactable component when the player interacts.
func _on_interact(interactable: Interactable, actor: Node) -> void:
	if is_animating:
		return

	if is_locked:
		print("This door is locked: ", name)
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
