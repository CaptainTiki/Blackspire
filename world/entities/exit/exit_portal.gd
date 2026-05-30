@tool
extends Entity
class_name ExitPortal

@export var prompt := "Extract"
@export var completion_message := "Run Complete"
@export var requires_all_enemies_defeated := true

@onready var interactable: Interactable = $Components/Interactable
@onready var label: Label3D = $Label3D
@onready var glow_column: MeshInstance3D = $GlowColumn


func _ready() -> void:
	_apply_display_state()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	glow_column.rotate_y(delta * 0.8)


func _func_godot_apply_properties(properties: Dictionary) -> void:
	if properties.has("prompt"):
		prompt = str(properties["prompt"])
	if properties.has("completion_message"):
		completion_message = str(properties["completion_message"])
	if properties.has("requires_all_enemies_defeated"):
		requires_all_enemies_defeated = _property_to_bool(properties["requires_all_enemies_defeated"])


func _on_interact(_interactable: Interactable, actor: Node) -> void:
	if not Level.current_level:
		push_error("ExitPortal %s could not complete the run because there is no current Level." % get_path())
		return

	if requires_all_enemies_defeated and Level.current_level.has_living_enemies():
		print("ExitPortal: enemies remain. Extraction is not available yet.")
		return

	Level.current_level.complete_run(actor, completion_message)


func _apply_display_state() -> void:
	interactable.prompt = prompt
	label.text = prompt.to_upper()


func _property_to_bool(value: Variant) -> bool:
	if value is bool:
		return value
	if value is int:
		return value != 0
	if value is String:
		var normalized := str(value).to_lower()
		return normalized == "1" or normalized == "true" or normalized == "yes"
	return false
