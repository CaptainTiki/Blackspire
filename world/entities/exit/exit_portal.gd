@tool
extends Entity
class_name ExitPortal

@export var prompt := "Extract"
@export var extraction_delay_seconds := 15.0

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
	if properties.has("extraction_delay_seconds"):
		extraction_delay_seconds = float(properties["extraction_delay_seconds"])


func _on_interact(_interactable: Interactable, actor: Node) -> void:
	if not Level.current_level:
		push_error("ExitPortal %s could not start extraction because there is no current Level." % get_path())
		return

	var player := actor as PlayerController
	if not player:
		push_error("ExitPortal %s can only exit a PlayerController." % get_path())
		return

	Level.current_level.interact_with_extraction(player, extraction_delay_seconds)


func _apply_display_state() -> void:
	interactable.prompt = prompt
	label.text = prompt.to_upper()
