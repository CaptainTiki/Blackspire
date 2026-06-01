@tool
extends Entity
class_name HubDeployPortal

@export var prompt := "Deploy To Run"

@onready var interactable: Interactable = $Components/Interactable
@onready var label: Label3D = $Label3D
@onready var glow_column: MeshInstance3D = $GlowColumn


func _ready() -> void:
	_apply_display_state()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	glow_column.rotate_y(delta * 0.9)


func _on_interact(_interactable: Interactable, actor: Node) -> void:
	var player := actor as PlayerController
	if not player:
		push_error("HubDeployPortal %s can only deploy a PlayerController." % get_path())
		return

	var hub := _find_parent_hub()
	if not hub:
		push_error("HubDeployPortal %s could not find a parent Hub." % get_path())
		return

	hub.request_deploy(player)


func _apply_display_state() -> void:
	interactable.prompt = prompt
	label.text = "DEPLOY"


func _find_parent_hub() -> Node:
	var current := get_parent()
	while current:
		if current.has_method("request_deploy"):
			return current
		current = current.get_parent()
	return null
